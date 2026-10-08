#!/usr/bin/env python3
"""Create local candidate archives from an audited allowlist, without publishing."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import shutil
import tempfile
import zipfile
import audit_release

ROOT = audit_release.ROOT
VERSION = '0.1.0'

def write_archive(path, members):
    with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for source, relative in members:
            if source.is_symlink() or not source.is_file():
                raise ValueError('Only regular allowlisted files may be packaged')
            info = zipfile.ZipInfo(relative, date_time=(2026, 10, 8, 0, 0, 0))
            info.create_system = 3
            mode = 0o755 if source.stat().st_mode & 0o111 else 0o644
            info.external_attr = (0o100000 | mode) << 16
            archive.writestr(info, source.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError('Archive integrity check failed')
        for member in archive.infolist():
            if member.filename.startswith('/') or '..' in Path(member.filename).parts:
                raise ValueError('Unsafe release archive path')
            audit_release.check_content(archive.read(member), member.filename, text=False)


def main():
    files = audit_release.audit_source()
    audit_release.audit_git(files)
    dirty = subprocess.check_output(['git','status','--porcelain','--untracked-files=all'],cwd=ROOT)
    if dirty:
        raise ValueError('Commit the completed source portions before packaging')
    commit = subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip()
    out=ROOT/'dist';out.mkdir(exist_ok=True)
    source=out/f'DarkOrbit-macOS-{VERSION}-source.zip'
    binary=out/f'DarkOrbit-for-Mac-{VERSION}-local-candidate.zip'
    write_archive(source, [(p,'darkorbit-macos/'+str(p.relative_to(ROOT))) for p in files])
    documentation=[ROOT/'LICENSE',ROOT/'THIRD_PARTY_NOTICES.md',ROOT/'dependencies.json']
    documentation += sorted(p for p in (ROOT/'docs').glob('*') if p.is_file())
    # Build only committed, allowlisted source in a separate location. A running
    # development app and its installation are never replaced during packaging.
    with tempfile.TemporaryDirectory(prefix='darkorbit-release-') as staging:
        clean=Path(staging)/'source'
        for path in files:
            destination=clean/path.relative_to(ROOT)
            destination.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(path,destination)
            destination.chmod(0o755 if path.stat().st_mode & 0o111 else 0o644)
        subprocess.run(['/bin/sh',str(clean/'scripts/build.sh')],cwd=clean,check=True)
        app=clean/'build/DarkOrbit for Mac.app'
        audit_release.audit_app(app)
        subprocess.run(['/usr/bin/codesign','--verify','--strict',str(app)],check=True)
        executable_sha=hashlib.sha256((app/'Contents/MacOS/DarkOrbitCommunity').read_bytes()).hexdigest()
        tested_sha=json.loads((ROOT/'docs/verification.json').read_text())['candidate_executable_sha256']
        app_members=[(p,str(p.relative_to(app.parent))) for p in sorted(app.rglob('*')) if p.is_file()]
        app_members += [(p,'START-HERE.txt' if p.name == 'START-HERE.txt' else str(p.relative_to(ROOT))) for p in documentation]
        write_archive(binary,app_members)
        app_file_count=len(app_members)
    sums={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (source,binary)}
    (out/'SHA256SUMS.txt').write_text(''.join(f'{sha}  {name}\n' for name,sha in sums.items()))
    manifest={'version':VERSION,'source_commit':commit,'source_files':len(files),
              'application_files':app_file_count,'archives':sums,
              'application_executable_sha256':executable_sha,
              'matches_tested_executable':executable_sha == tested_sha,
              'status':'LOCAL CANDIDATE ONLY - public release has unresolved blockers',
              'signature':'ad-hoc, not Developer ID or notarized','published':False,
              'excluded':['game binaries','runtime binaries','installers','prefixes','account state','private reports','Git metadata']}
    (out/'release-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(manifest))

if __name__=='__main__':
    try: main()
    except (ValueError,OSError,subprocess.SubprocessError) as error:
        if isinstance(error,ValueError): print(str(error),file=sys.stderr)
        else: print('Packaging failed. Raw system output withheld.',file=sys.stderr)
        raise SystemExit(1)
