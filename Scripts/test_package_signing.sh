#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PACKAGE_SCRIPT="$ROOT/Scripts/package_app.sh"
RELEASE_SCRIPT="$ROOT/Scripts/sign-and-notarize.sh"
FUNCTIONS_FILE=$(mktemp "${TMPDIR:-/tmp}/codexbar-package-signing-functions.XXXXXX")
trap 'rm -f "$FUNCTIONS_FILE"' EXIT

python3 - "$PACKAGE_SCRIPT" "$FUNCTIONS_FILE" <<'PY'
import sys
from pathlib import Path

script = Path(sys.argv[1]).read_text()
functions = []
for name in (
    'resolve_package_signing_mode',
    'verify_no_quarantine_attribute',
    'verify_packaged_app_integrity',
):
    start = script.index(f'{name}() {{')
    end = script.index('\n}\n', start) + 3
    functions.append(script[start:end])
Path(sys.argv[2]).write_text('\n\n'.join(functions))
PY

source "$FUNCTIONS_FILE"

unset CODEXBAR_SIGNING
SIGNING_MODE=
resolve_package_signing_mode
[[ "$SIGNING_MODE" == "adhoc" ]]

CODEXBAR_SIGNING=identity
resolve_package_signing_mode
[[ "$SIGNING_MODE" == "identity" ]]

CODEXBAR_SIGNING=invalid
if resolve_package_signing_mode 2>/dev/null; then
  echo "Invalid package signing mode unexpectedly succeeded" >&2
  exit 1
fi

grep -Fq 'CODEXBAR_SIGNING=identity ./Scripts/package_app.sh release' "$RELEASE_SCRIPT"
# Public package/artifact resolution must never fall back to an interactive
# macOS Keychain lookup during headless packaging.
grep -Fq -- '-packageAuthorizationProvider netrc' "$PACKAGE_SCRIPT"

TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/codexbar-package-signing.XXXXXX")
trap 'rm -f "$FUNCTIONS_FILE"; rm -rf "$TEMP_DIR"' EXIT
APP="$TEMP_DIR/CodexBar.app"
mkdir -p "$APP/Contents/Frameworks/Sparkle.framework"

xattr() {
  if [[ "${MOCK_QUARANTINE:-0}" == "1" ]]; then
    printf '0081;fake;Safari;https://example.invalid\n'
    return 0
  fi
  return 1
}

codesign() {
  return "${MOCK_CODESIGN_STATUS:-0}"
}

verify_packaged_app_integrity "$APP"

export MOCK_QUARANTINE=1
if verify_packaged_app_integrity "$APP" 2>/dev/null; then
  echo "Quarantined app unexpectedly passed integrity verification" >&2
  exit 1
fi
unset MOCK_QUARANTINE

export MOCK_CODESIGN_STATUS=1
if verify_packaged_app_integrity "$APP" 2>/dev/null; then
  echo "App with an invalid signature unexpectedly passed integrity verification" >&2
  exit 1
fi
unset MOCK_CODESIGN_STATUS

python3 - "$PACKAGE_SCRIPT" "$RELEASE_SCRIPT" "$ROOT/Scripts/compile_and_run.sh" <<'PY'
import itertools
import os
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path

source = Path(sys.argv[1]).read_text()
start = source.index('BUNDLE_ID="com.ian902792.codexbar"')
end = source.index('BUILD_TIMESTAMP=', start)
generation = source[start:end]
start = source.index('PROVISION_PROFILE="$ROOT/Provisioning/CodexBar_Dev.provisionprofile"')
end = source.index('\nfi', start) + len('\nfi')
embedding = source[start:end]

helper = ''
if 'resolve_package_signing_identity() {' in source:
    start = source.index('resolve_package_signing_identity() {')
    end = source.index('\n}\n', start) + 3
    helper = source[start:end]

for configuration, signing, profile_present, allow_lldb in itertools.product(
    ['release', 'debug'], ['identity', 'adhoc'], [False, True], ['0', '1'],
):
    with tempfile.TemporaryDirectory(prefix='codexbar-entitlement-test-') as directory:
        root = Path(directory)
        app = root / 'CodexBar.app'
        (app / 'Contents').mkdir(parents=True)
        profile = root / 'Provisioning/CodexBar_Dev.provisionprofile'
        if profile_present:
            profile.parent.mkdir(parents=True)
            # Marker tests selection/copying only, not certificate or profile validity.
            profile.write_text('synthetic fork profile selection marker\n')
        # An upstream profile must never satisfy the fork's provisioning requirement.
        upstream = root / 'Scripts/profiles/CodexBar-DeveloperID.provisionprofile'
        upstream.parent.mkdir(parents=True)
        upstream.write_text('incompatible upstream profile marker\n')
        app_identity = 'Developer ID Application: Fixture (RQCATSZF69)'
        env = dict(os.environ, ROOT=str(root), APP=str(app), APP_TEAM_ID='RQCATSZF69',
                   CONF=configuration, LOWER_CONF=configuration, SIGNING_MODE=signing,
                   ALLOW_LLDB=allow_lldb, APP_IDENTITY=app_identity)
        identity_stub = f'security() {{ echo \'  1) {"A" * 40} "{app_identity}"\'; }}'
        result = subprocess.run(['bash', '-eu', '-c', identity_stub + '\n' + helper + '\n' + generation + '\n' + embedding],
                                env=env, capture_output=True, text=True)
        expected_failure = (allow_lldb == '1' and configuration != 'debug') or (
            configuration == 'release' and signing == 'identity' and not profile_present)
        if expected_failure:
            assert result.returncode != 0, (configuration, signing, profile_present, allow_lldb)
            continue
        assert result.returncode == 0, result.stderr
        app_entitlements = plistlib.loads((root / '.build/entitlements/CodexBar.entitlements').read_bytes())
        widget_entitlements = plistlib.loads((root / '.build/entitlements/CodexBarWidget.entitlements').read_bytes())
        cloudkit = signing == 'identity'
        if cloudkit:
            assert app_entitlements['com.apple.developer.team-identifier'] == 'RQCATSZF69'
            assert app_entitlements['com.apple.developer.icloud-container-environment'] == 'Production'
            assert app_entitlements['com.apple.developer.icloud-container-identifiers'] == ['iCloud.com.ian902792.codexbar']
            assert app_entitlements['com.apple.security.application-groups'][0].startswith('group.com.ian902792.codexbar')
        else:
            assert 'com.apple.developer.icloud-services' not in app_entitlements
        assert widget_entitlements['com.apple.security.app-sandbox'] is True
        embedded = app / 'Contents/embedded.provisionprofile'
        assert embedded.exists() == profile_present
        if embedded.exists():
            assert embedded.read_bytes() == profile.read_bytes()
print('16 entitlement/profile configuration cases passed.')

# Execute the actual entitlement block against synthetic identity listings only.
# A direct APP_IDENTITY call must not inherit upstream team-bound resources.
upstream = 'Developer ID Application: Example Upstream (Y5PE65HELJ)'
fork = 'Developer ID Application: Example Fork (TESTTEAM01)'
first_hash = 'A' * 40
second_hash = 'B' * 40
listing = f'  1) {first_hash} "{upstream}"\n  2) {second_hash} "{fork}"\n     2 valid identities found\n'
cases = [
    ('full name', fork, None, listing, 0, 'TESTTEAM01'),
    ('hash', second_hash, None, listing, 0, 'TESTTEAM01'),
    ('lowercase hash', second_hash.lower(), None, listing, 0, 'TESTTEAM01'),
    ('unique substring', 'Example Fork', None, listing, 0, 'TESTTEAM01'),
    ('matching override', fork, 'TESTTEAM01', listing, 0, 'TESTTEAM01'),
    ('conflicting override', fork, 'Y5PE65HELJ', listing, 0, None),
    ('empty override', fork, '', listing, 0, 'TESTTEAM01'),
    ('missing identity', 'Missing', None, listing, 0, None),
    ('ambiguous identity', 'Developer ID Application:', None, listing, 0, None),
    ('missing team', 'Teamless', None, f'  1) {first_hash} "Teamless"\n', 0, None),
    ('malformed team', 'Broken', None, f'  1) {first_hash} "Broken (SHORT)"\n', 0, None),
    ('development personal ID is not a team', 'Apple Development:', None, f'  1) {first_hash} "Apple Development: Fixture (PERSONID01)"\n', 0, None),
    ('arbitrary suffix is not a team', 'Local Certificate', None, f'  1) {first_hash} "Local Certificate (TESTTEAM01)"\n', 0, None),
    ('query failure', fork, None, listing, 1, None),
    ('no identities', fork, None, '     0 valid identities found\n', 0, None),
    ('duplicate name', fork, None, listing + f'  3) {first_hash} "{fork}"\n', 0, None),
]
with tempfile.TemporaryDirectory(prefix='codexbar-identity-test-') as directory:
    root = Path(directory)
    mock_bin = root / 'bin'
    mock_bin.mkdir()
    security = mock_bin / 'security'
    security.write_text('#!/bin/bash\n[[ "$*" == "find-identity -p codesigning -v" ]] || exit 99\nprintf "%s" "$MOCK_IDENTITIES"\nexit "$MOCK_SECURITY_EXIT"\n')
    security.chmod(0o755)
    for case, (configuration, lldb) in itertools.product(cases, [('release', '0'), ('debug', '1')]):
        label, identity, override, identities, query_exit, expected_team = case
        case_root = root / (label + configuration)
        case_root.mkdir()
        env = dict(os.environ, ROOT=str(case_root), LOWER_CONF=configuration, SIGNING_MODE='identity',
                   ALLOW_LLDB=lldb, APP_IDENTITY=identity, MOCK_IDENTITIES=identities,
                   MOCK_SECURITY_EXIT=str(query_exit), PATH=str(mock_bin) + os.pathsep + os.environ['PATH'])
        env.pop('APP_TEAM_ID', None)
        if override is not None:
            env['APP_TEAM_ID'] = override
        result = subprocess.run(['bash', '-eu', '-c', helper + '\n' + generation + '\nprintf "%s" "$CODESIGN_ID"'],
                                env=env, capture_output=True, text=True)
        app_path = case_root / '.build/entitlements/CodexBar.entitlements'
        if expected_team is None:
            assert result.returncode != 0 and 'ERROR:' in result.stderr, (label, result.stderr)
            assert not app_path.exists(), label
            continue
        assert result.returncode == 0, (label, result.stderr)
        assert result.stdout == second_hash, (label, result.stdout)
        app_entitlements = plistlib.loads(app_path.read_bytes())
        widget_entitlements = plistlib.loads((app_path.parent / 'CodexBarWidget.entitlements').read_bytes())
        suffix = '.debug' if configuration == 'debug' else ''
        # App-identifier, team-identifier and the KVS store follow the team that
        # resolved CODESIGN_ID; the bundle, app group and CloudKit container are
        # fork-owned and stay fixed.
        expected_group = [f'group.com.ian902792.codexbar{suffix}']
        expected_app = {
            'com.apple.application-identifier': f'{expected_team}.com.ian902792.codexbar{suffix}',
            'com.apple.developer.team-identifier': expected_team,
            'com.apple.security.application-groups': expected_group,
            'com.apple.developer.ubiquity-kvstore-identifier': f'{expected_team}.com.codexbar.shared',
            'com.apple.developer.icloud-services': ['CloudKit'],
            'com.apple.developer.icloud-container-identifiers': ['iCloud.com.ian902792.codexbar'],
            'com.apple.developer.icloud-container-environment': 'Production',
        }
        if lldb == '1':
            expected_app['com.apple.security.get-task-allow'] = True
        assert app_entitlements == expected_app, label
        assert widget_entitlements['com.apple.security.application-groups'] == expected_group, label
print(f'{len(cases) * 2} direct identity cases passed without signing or Keychain access.')

release_source = Path(sys.argv[2]).read_text()
identity_assignment = next(line for line in release_source.splitlines() if line.startswith('APP_IDENTITY='))
package_call = next(line for line in release_source.splitlines() if './Scripts/package_app.sh release' in line)
with tempfile.TemporaryDirectory(prefix='codexbar-release-identity-test-') as directory:
    root = Path(directory)
    (root / 'Scripts').mkdir()
    package_stub = root / 'Scripts/package_app.sh'
    package_stub.write_text('#!/bin/bash\n[[ "$*" == release && "$CODEXBAR_SIGNING" == identity ]] || exit 99\nprintf "%s" "$APP_IDENTITY"\n')
    package_stub.chmod(0o755)
    for identity in [None, fork]:
        env = dict(os.environ, ARCHES_VALUE='arm64', STAGED_APP_BUNDLE=str(root / 'CodexBar.app'))
        env.pop('APP_IDENTITY', None)
        if identity is not None:
            env['APP_IDENTITY'] = identity
        result = subprocess.run(['bash', '-eu', '-c', identity_assignment + '\n' + package_call],
                                cwd=root, env=env, capture_output=True, text=True)
        expected = identity or 'Developer ID Application: CHENG YEN YU (RQCATSZF69)'
        assert result.returncode == 0 and result.stdout == expected, result
print('2 release identity forwarding cases passed without signing or notarization.')

# Source only the selection functions, never the build/kill/launch entry point.
dev_source = Path(sys.argv[3]).read_text()
start = dev_source.index('has_signing_identity() {')
end = dev_source.index('\nrun_step() {', start)
dev_selection = dev_source[start:end]
legacy_listing = f'  1) {first_hash} "CodexBar Development"\n'
for label, identities, explicit, expected_mode, expected_identity in [
    ('legacy only', legacy_listing, '', 'adhoc', ''),
    ('legacy with Apple identity', legacy_listing + listing, '', 'identity', upstream),
    ('no identities', '', '', 'adhoc', ''),
    ('development identity only', f'  1) {first_hash} "Apple Development: Fixture (PERSONID01)"\n', '', 'adhoc', ''),
    ('explicit missing identity', '', 'Missing', 'identity', 'Missing'),
    ('explicit legacy identity', legacy_listing, 'CodexBar Development', 'identity', 'CodexBar Development'),
]:
    env = dict(os.environ, SIGNING_MODE='', APP_IDENTITY=explicit, APP_TEAM_ID='', MOCK_IDENTITIES=identities)
    stubs = 'security() { [[ "$*" == "find-identity -p codesigning -v" ]] || exit 99; printf "%s" "$MOCK_IDENTITIES"; }; log() { :; }'
    result = subprocess.run(['bash', '-eu', '-c', stubs + '\n' + dev_selection +
                             '\nresolve_signing_mode\nprintf "%s|%s" "$SIGNING_MODE" "$APP_IDENTITY"'],
                            env=env, capture_output=True, text=True)
    assert result.returncode == 0 and result.stdout == f'{expected_mode}|{expected_identity}', (label, result)
print('6 development identity selection cases passed without running the app.')
PY

echo "Package signing tests passed."
