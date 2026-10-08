#!/usr/bin/env python3
"""Audit the explicit publication surface without reading local account state."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
APPROVED_FILES = {
    '.github/ISSUE_TEMPLATE/bug.yml',
    '.github/ISSUE_TEMPLATE/compatibility.yml',
    '.gitignore',
    'AGENTS.md',
    'CHANGELOG.md',
    'CONTRIBUTING.md',
    'LICENSE',
    'README.md',
    'Resources/Info.plist',
    'Sources/App.swift',
    'Sources/Core.swift',
    'Sources/Installer.swift',
    'THIRD_PARTY_NOTICES.md',
    'dependencies.json',
    'docs/START-HERE.txt',
    'docs/architecture.md',
    'docs/compatibility.md',
    'docs/dependencies.md',
    'docs/development.md',
    'docs/distribution.md',
    'docs/install.md',
    'docs/limitations.md',
    'docs/troubleshooting.md',
    'docs/verification.json',
    'scripts/audit_release.py',
    'scripts/build.sh',
    'scripts/make-icon.swift',
    'scripts/package.py',
    'scripts/probe-build.sh',
    'scripts/test.sh',
    'tests/CoreTests.swift',
    'tests/InstallationProbe.swift',
    'tests/InstallerTests.swift',
    'tests/ReleaseTests.py',
}
APPROVED_DIRS = {str(parent) for name in APPROVED_FILES
                 for parent in Path(name).parents if str(parent) != '.'}
TOP_FILES = {name for name in APPROVED_FILES if '/' not in name}
SUFFIXES = {'.swift', '.sh', '.py', '.json', '.plist', '.md', '.txt', '.yml', '.yaml'}
DISALLOWED_PARTS = {'__pycache__', '.DS_Store', 'runtime', 'state', 'downloads', 'work', 'private'}
APP_FILES = {'Contents/Info.plist', 'Contents/MacOS/DarkOrbitCommunity',
             'Contents/Resources/AppIcon.icns', 'Contents/_CodeSignature/CodeResources'}
# These patterns identify categories, never store a user's actual private values.
PATTERNS = [
    re.compile(rb'/Users/[A-Za-z0-9_.-]+/'),
    re.compile(rb'/home/[A-Za-z0-9_.-]+/'),
    re.compile(rb'\.codex/(?:attachments|\.chatgpt-projects|visualizations)/'),
    re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    re.compile(rb'gh[pousr]_[A-Za-z0-9]{24,}'),
    re.compile(rb'github_pat_[A-Za-z0-9_]{30,}'),
    re.compile(rb'(?i)(?:password|access_token|refresh_token|dosid)\s*[:=]\s*[\"\x27][^\"\x27\s]{5,}[\"\x27]'),
]

def selected_files():
    if ROOT.is_symlink() or not ROOT.is_dir():
        raise ValueError('Publication root is absent or is a link')
    files = []

    def visit(path):
        relative = str(path.relative_to(ROOT))
        # Reject unknown entries before inspecting or traversing their contents.
        if relative not in APPROVED_FILES and relative not in APPROVED_DIRS:
            raise ValueError('Unreviewed entry in a publication directory')
        try:
            mode = path.lstat().st_mode
        except FileNotFoundError:
            raise ValueError('A required publication file or directory is absent') from None
        if stat.S_ISLNK(mode):
            raise ValueError('Publication files and their parent directories cannot be links')
        if stat.S_ISDIR(mode):
            if relative not in APPROVED_DIRS:
                raise ValueError('A publication file was replaced by a directory')
            for child in sorted(path.iterdir()):
                visit(child)
        elif stat.S_ISREG(mode) and relative in APPROVED_FILES:
            files.append(path)
        else:
            raise ValueError('Publication selection contains an unexpected file type')

    for name in sorted({path.split('/')[0] for path in APPROVED_FILES}):
        visit(ROOT / name)
    if {str(path.relative_to(ROOT)) for path in files} != APPROVED_FILES:
        raise ValueError('A required allowlisted publication file is absent')
    return sorted(files)

def check_content(data, label, text=True):
    for pattern in PATTERNS:
        if pattern.search(data):
            raise ValueError('Sensitive-data pattern in ' + label + '; matched values withheld')
    actual_home = str(Path.home()).encode()
    if actual_home and actual_home != b'/' and actual_home in data:
        raise ValueError('Local home path in ' + label + '; value withheld')
    if text:
        decoded = data.decode('utf-8')
        # First-party text is deliberately ASCII. Escaped test fixtures are fine.
        if any(ord(c) > 126 or (ord(c) < 32 and c not in '\n\r\t') for c in decoded):
            raise ValueError('Non-ASCII or hidden control character in ' + label)
        if label.endswith(('.md', '.txt', '.html')) and re.search(r'<!--|display\s*:\s*none|visibility\s*:\s*hidden|font-size\s*:\s*0', decoded, re.I):
            raise ValueError('Hidden-text marker in ' + label)


def audit_source():
    files = selected_files()
    if not files:
        raise ValueError('No publication files found')
    for path in files:
        rel = path.relative_to(ROOT)
        if path.is_symlink() or any(part in DISALLOWED_PARTS for part in rel.parts):
            raise ValueError('Excluded path or link in publication selection')
        if path.name not in TOP_FILES and path.suffix not in SUFFIXES:
            raise ValueError('Unapproved file type: ' + str(rel))
        if path.stat().st_size > 2 * 1024 * 1024:
            raise ValueError('Unexpectedly large source file: ' + str(rel))
        check_content(path.read_bytes(), str(rel))
    return files


def check_git_paths(data):
    for name in data.split(b'\0'):
        if not name:
            continue
        check_content(name, 'Git path', text=False)
        try:
            relative = name.decode('utf-8')
        except UnicodeError:
            raise ValueError('Git contains an unreadable path; value withheld') from None
        if relative not in APPROVED_FILES:
            raise ValueError('Git contains a path outside the exact release allowlist; value withheld')


def audit_git(files):
    if not (ROOT/'.git').exists():
        return
    allowed = {str(p.relative_to(ROOT)) for p in files}
    tracked_data = subprocess.check_output(['git','ls-files','-z'], cwd=ROOT)
    check_git_paths(tracked_data)
    tracked = tracked_data.decode().split('\0')
    if any(name and name not in allowed for name in tracked):
        raise ValueError('Git index includes files outside the release allowlist')
    remotes = subprocess.check_output(['git','remote'],cwd=ROOT).strip()
    if remotes:
        raise ValueError('This local preparation repository must have no remote')
    have_head = subprocess.run(['git','rev-parse','--verify','HEAD'],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode == 0
    if not have_head:
        return
    objects = subprocess.check_output(['git','rev-list','--objects','--all'],cwd=ROOT).splitlines()
    for line in objects:
        object_id, separator, object_path = line.partition(b' ')
        if separator:
            check_content(object_path, 'Git object path', text=False)
        oid = object_id.decode('ascii')
        kind = subprocess.check_output(['git','cat-file','-t',oid],cwd=ROOT).strip()
        if kind == b'commit':
            paths = subprocess.check_output(['git','ls-tree','-rz','--name-only','--full-tree',oid],cwd=ROOT)
            check_git_paths(paths)
        if kind in {b'blob',b'commit',b'tag'}:
            data = subprocess.check_output(['git','cat-file','-p',oid],cwd=ROOT)
            check_content(data, 'Git object', text=False)


def audit_app(app):
    if app.is_symlink() or not app.is_dir():
        raise ValueError('Application bundle is absent or unsafe')
    found = set()
    for path in app.rglob('*'):
        if path.is_symlink():
            raise ValueError('Unexpected application symlink')
        if path.is_file():
            rel = path.relative_to(app)
            if str(rel) not in APP_FILES:
                raise ValueError('Application contains a file outside its exact allowlist')
            if any(part in DISALLOWED_PARTS for part in rel.parts):
                raise ValueError('Third-party or state directory bundled in app')
            data = path.read_bytes()
            check_content(data, str(rel), text=False)
            if path.suffix.lower() in {'.dll','.exe','.dylib','.xz','.zip','.pdb'}:
                raise ValueError('Unexpected third-party binary in app')
            found.add(str(rel))
    if found != APP_FILES:
        raise ValueError('Application is missing a required allowlisted file')
    return len(found)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-only',action='store_true')
    parser.add_argument('--app',type=Path)
    args=parser.parse_args()
    try:
        files=audit_source();audit_git(files)
        count=audit_app(args.app) if args.app else 0
        print(json.dumps({'source_files':len(files),'app_files':count,'privacy_and_style':'PASS','remote':'none','scope':'Allowlisted files and reachable Git objects; heuristic scan, not a guarantee'}))
    except (ValueError,UnicodeError,OSError,subprocess.SubprocessError) as error:
        if isinstance(error,ValueError): print('Audit failed: '+str(error),file=sys.stderr)
        else: print('Audit failed without exposing raw system output.',file=sys.stderr)
        return 1
    return 0
if __name__=='__main__':
    raise SystemExit(main())
