#!/usr/bin/env node
/*
 * Adds the BigBlueButton screen-share Broadcast Upload Extension to an existing iOS app project
 * (Flutter, React Native or native hosts):
 *
 *   node tools/ios/add-broadcast-extension.mjs --project <path/to/App.xcodeproj> --app-target <Name>
 *        --team <TEAMID> [--app-group group.<bundle id>] [--target-name BroadcastExtension]
 *        [--display-name "<App> Screen Share"] [--version 1.0.0 --build 1] [--deployment-target 16.4]
 *
 * It (1) copies ios/BroadcastExtension/* of this repository into <ios dir>/<target-name>/ with the
 * placeholders filled in, (2) adds the extension target with its sources, Info.plist, entitlements
 * and build settings, the app -> extension dependency and the "Embed Foundation Extensions"
 * phase, (3) gives the app target an App Group entitlement (creating <AppTarget>.entitlements when
 * the app has none) and the Info.plist keys RTCAppGroupIdentifier / RTCScreenSharingExtension the
 * SDK's WebRTC module reads, and (4) sets automatic signing with the team on both targets.
 * Idempotent: re-running refreshes the files and settings.
 */
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const xcode = require('xcode');

const HERE = path.dirname(fileURLToPath(import.meta.url));
const TEMPLATE_DIR = path.resolve(HERE, '..', '..', 'ios', 'BroadcastExtension');
const SWIFT_SOURCES = ['SampleHandler.swift', 'SampleUploader.swift', 'SocketConnection.swift', 'DarwinNotificationCenter.swift', 'Atomic.swift'];

const args = {};
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i += 1) {
  if (!argv[i].startsWith('--')) throw new Error(`unexpected argument ${argv[i]}`);
  args[argv[i].slice(2)] = argv[i + 1];
  i += 1;
}
const required = (k) => { if (!args[k]) throw new Error(`--${k} is required`); return args[k]; };

const projectDir = path.resolve(required('project'));
const pbxprojPath = path.join(projectDir, 'project.pbxproj');
const iosDir = path.dirname(projectDir);
const appTargetName = required('app-target');
const team = required('team');
const targetName = args['target-name'] || 'BroadcastExtension';
const deploymentTarget = args['deployment-target'] || '16.4';
const shortVersion = args.version || '1.0.0';
const buildVersion = args.build || '1';

const unquote = (v) => (typeof v === 'string' ? v.replace(/^"(.*)"$/, '$1') : v);
const quote = (v) => `"${v}"`;

const project = xcode.project(pbxprojPath);
project.parseSync();
const objects = project.hash.project.objects;

// ---- the app target and its settings -----------------------------------------------------
const nativeTargets = project.pbxNativeTargetSection();
const appTargetKey = Object.keys(nativeTargets).find((k) => !k.endsWith('_comment') && unquote(nativeTargets[k].name) === appTargetName);
if (!appTargetKey) throw new Error(`app target '${appTargetName}' not found in ${pbxprojPath}`);
const appTarget = nativeTargets[appTargetKey];
const configurations = project.pbxXCBuildConfigurationSection();
const appConfigs = project.pbxXCConfigurationList()[appTarget.buildConfigurationList].buildConfigurations.map((r) => configurations[r.value]);
const appSetting = (name) => { const c = appConfigs.find((e) => e.buildSettings && e.buildSettings[name] !== undefined); return c ? unquote(c.buildSettings[name]) : undefined; };

let appBundleId = appSetting('PRODUCT_BUNDLE_IDENTIFIER');
if (!appBundleId || appBundleId.includes('$(')) {
  const plist = appSetting('INFOPLIST_FILE');
  throw new Error(`cannot read the app bundle id from the project (PRODUCT_BUNDLE_IDENTIFIER=${appBundleId}, INFOPLIST_FILE=${plist}); pass a project with a literal bundle id`);
}
const appGroup = args['app-group'] || `group.${appBundleId}`;
const extBundleId = `${appBundleId}.broadcast`;
const displayName = args['display-name'] || `${appTargetName} Screen Share`;
const appInfoPlist = path.resolve(iosDir, unquote(appSetting('INFOPLIST_FILE')).replace(/\$\(SRCROOT\)\/?/, ''));
if (!fs.existsSync(appInfoPlist)) throw new Error(`app Info.plist not found: ${appInfoPlist}`);

// ---- 1. extension files -----------------------------------------------------------------
const render = (text, values) => Object.entries(values).reduce((acc, [k, v]) => acc.split(`{{${k}}}`).join(v), text);
const extDir = path.join(iosDir, targetName);
fs.mkdirSync(extDir, { recursive: true });
SWIFT_SOURCES.forEach((f) => fs.copyFileSync(path.join(TEMPLATE_DIR, f), path.join(extDir, f)));
fs.writeFileSync(path.join(extDir, 'Info.plist'), render(fs.readFileSync(path.join(TEMPLATE_DIR, 'Info.plist'), 'utf8'), {
  APP_GROUP: appGroup, DISPLAY_NAME: displayName, SHORT_VERSION: shortVersion, BUILD_VERSION: buildVersion,
}));
const entitlementsName = `${targetName}.entitlements`;
fs.writeFileSync(path.join(extDir, entitlementsName), render(fs.readFileSync(path.join(TEMPLATE_DIR, 'BroadcastExtension.entitlements'), 'utf8'), { APP_GROUP: appGroup }));

// ---- 2. extension target ----------------------------------------------------------------
const existing = Object.keys(nativeTargets).find((k) => !k.endsWith('_comment') && unquote(nativeTargets[k].name) === targetName);
if (!existing) {
  objects.PBXTargetDependency = objects.PBXTargetDependency || {};
  objects.PBXContainerItemProxy = objects.PBXContainerItemProxy || {};
  const group = project.addPbxGroup([...SWIFT_SOURCES, 'Info.plist', entitlementsName], targetName, targetName);
  const groups = objects.PBXGroup;
  Object.keys(groups).forEach((key) => {
    const entry = groups[key];
    if (entry && typeof entry === 'object' && entry.name === undefined && entry.path === undefined) project.addToPbxGroup(group.uuid, key);
  });
  const target = project.addTarget(targetName, 'app_extension', targetName, extBundleId);
  project.addBuildPhase(SWIFT_SOURCES, 'PBXSourcesBuildPhase', 'Sources', target.uuid);
  project.addBuildPhase([], 'PBXResourcesBuildPhase', 'Resources', target.uuid);
  project.addBuildPhase([], 'PBXFrameworksBuildPhase', 'Frameworks', target.uuid);
}
// The embed phase the xcode lib appends lands after script phases such as Flutter's "Thin Binary"
// (which rewrites the app bundle) and Xcode then reports "Cycle inside <App>". Move it right
// after the app's frameworks embedding (or its Resources phase), where Xcode itself puts it.
{
  const phases = appTarget.buildPhases || [];
  const copyPhases = objects.PBXCopyFilesBuildPhase || {};
  const isAppex = (ref) => copyPhases[ref.value] && String(copyPhases[ref.value].dstSubfolderSpec) === '13';
  const idx = phases.findIndex(isAppex);
  if (idx >= 0) {
    const [embed] = phases.splice(idx, 1);
    let anchor = -1;
    phases.forEach((ref, i) => {
      if (copyPhases[ref.value] && String(copyPhases[ref.value].dstSubfolderSpec) === '10') anchor = i;
    });
    if (anchor < 0) anchor = phases.findIndex((ref) => (objects.PBXResourcesBuildPhase || {})[ref.value]);
    phases.splice(anchor + 1, 0, embed);
  }
}
Object.keys(configurations).forEach((key) => {
  const entry = configurations[key];
  if (!entry || typeof entry !== 'object' || !entry.buildSettings) return;
  if (unquote(entry.buildSettings.PRODUCT_NAME) !== targetName) return;
  Object.assign(entry.buildSettings, {
    INFOPLIST_FILE: quote(`${targetName}/Info.plist`),
    CODE_SIGN_ENTITLEMENTS: quote(`${targetName}/${entitlementsName}`),
    CODE_SIGN_STYLE: 'Automatic',
    DEVELOPMENT_TEAM: team,
    GENERATE_INFOPLIST_FILE: 'NO',
    IPHONEOS_DEPLOYMENT_TARGET: deploymentTarget,
    TARGETED_DEVICE_FAMILY: quote('1,2'),
    SWIFT_VERSION: '5.0',
    SWIFT_EMIT_LOC_STRINGS: 'YES',
    MARKETING_VERSION: shortVersion,
    CURRENT_PROJECT_VERSION: buildVersion,
    PRODUCT_BUNDLE_IDENTIFIER: quote(extBundleId),
    SKIP_INSTALL: 'YES',
  });
});

// ---- 3. app target: entitlements + Info.plist keys + signing ----------------------------
let appEntitlements = appSetting('CODE_SIGN_ENTITLEMENTS');
if (!appEntitlements) {
  appEntitlements = `${appTargetName}/${appTargetName}.entitlements`;
  const abs = path.join(iosDir, appEntitlements);
  if (!fs.existsSync(abs)) {
    fs.mkdirSync(path.dirname(abs), { recursive: true });
    fs.writeFileSync(abs, '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n<dict>\n</dict>\n</plist>\n');
  }
}
const appEntitlementsAbs = path.join(iosDir, unquote(appEntitlements));
/** plutil -replace only touches existing keys, -insert only missing ones, and dots in a key name are path separators unless escaped. */
function plistSet(file, key, typeFlag, value) {
  const keyPath = key.replace(/\./g, '\\.');
  try {
    execFileSync('plutil', ['-replace', keyPath, typeFlag, value, file], { stdio: 'pipe' });
  } catch {
    execFileSync('plutil', ['-insert', keyPath, typeFlag, value, file], { stdio: 'pipe' });
  }
}
plistSet(appEntitlementsAbs, 'com.apple.security.application-groups', '-json', JSON.stringify([appGroup]));
plistSet(appInfoPlist, 'RTCAppGroupIdentifier', '-string', appGroup);
plistSet(appInfoPlist, 'RTCScreenSharingExtension', '-string', extBundleId);
appConfigs.forEach((c) => {
  if (!c.buildSettings) return;
  c.buildSettings.CODE_SIGN_ENTITLEMENTS = quote(unquote(appEntitlements));
  c.buildSettings.CODE_SIGN_STYLE = 'Automatic';
  c.buildSettings.DEVELOPMENT_TEAM = team;
});

fs.writeFileSync(pbxprojPath, project.writeSync());
console.log(`${existing ? 'updated' : 'added'} ${targetName} (${extBundleId}) in ${path.basename(projectDir)}; app group ${appGroup}; team ${team}`);
