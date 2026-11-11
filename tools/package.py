#!/usr/bin/env python3
"""Build a deterministic installable ZIP. No release publication or network operations."""
from hashlib import sha256
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import re

root = Path(__file__).resolve().parents[1]
dist = root / 'dist'
dist.mkdir(exist_ok=True)
files = {f'AlbinoUI/{path.name}': path for path in (root / 'AlbinoUI').iterdir() if path.is_file()}
files['AlbinoUI/README.md'] = root / 'README.md'
for name in ('COMPATIBILITY.md', 'ACCEPTANCE.md', 'LIMITATIONS.md', 'TEST_REPORT.md'):
    files['AlbinoUI/docs/' + name] = root / 'docs' / name
archive = dist / 'AlbinoUI.zip'
with ZipFile(archive, 'w', compression=ZIP_DEFLATED) as zip_file:
    for name, path in sorted(files.items()):
        info = ZipInfo(name, (2026, 1, 1, 0, 0, 0))
        info.compress_type = ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        zip_file.writestr(info, path.read_bytes())
with ZipFile(archive) as zip_file:
    assert zip_file.testzip() is None
    names = set(zip_file.namelist())
    assert 'AlbinoUI/AlbinoUI.toc' in names
    assert all(n.startswith('AlbinoUI/') and '..' not in n.split('/') for n in names)
    assert not any('/tests/' in n or '/.git/' in n for n in names)
    toc = zip_file.read('AlbinoUI/AlbinoUI.toc').decode()
    for line in toc.splitlines():
        if line.strip() and not line.startswith('#'):
            assert 'AlbinoUI/' + line.strip().replace('\\', '/') in names
    assert 'AlbinoUI/Bindings.xml' in names
checksum = sha256(archive.read_bytes()).hexdigest()
(dist / 'SHA256SUMS').write_text(f'{checksum}  AlbinoUI.zip\n')
print(f'PASS package: {len(files)} files; CRC, manifest, bindings, and root directory checked')
print(f'{archive}\nSHA256 {checksum}')
