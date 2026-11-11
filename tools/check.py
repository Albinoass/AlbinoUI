#!/usr/bin/env python3
"""Validate the shipping manifest and run actual Lua 5.1 tests, without third-party Python packages."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
LUA = os.environ.get('LUA') or shutil.which('lua5.1') or shutil.which('lua')
if not LUA:
    raise SystemExit('Lua 5.1 required: install lua5.1 or set LUA=/path/to/lua')
version = subprocess.check_output([LUA, '-e', 'io.write(_VERSION)'], text=True)
assert version == 'Lua 5.1', f'Expected Lua 5.1, got {version}'
static = 0

def check(condition, name):
    global static
    assert condition, name
    static += 1
    print('PASS static:', name, flush=True)

toc = (ROOT / 'AlbinoUI/AlbinoUI.toc').read_text()
modules = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith('#')]
check(modules == ['Core.lua', 'Compatibility.lua', 'Persistence.lua', 'Layout.lua', 'ActionBars.lua',
                  'Resources.lua', 'Cooldowns.lua', 'SwingTimers.lua', 'Settings.lua'], 'module order')
check('## Interface: 16001' in toc, 'Forever interface metadata')
check('## SavedVariablesPerCharacter: AlbinoUIDB' in toc, 'character-specific SavedVariables')
check(all((ROOT / 'AlbinoUI' / file).is_file() for file in modules), 'manifest files exist')
check(len(modules) == len(set(modules)), 'no duplicate modules')
for file in sorted(list(Path('AlbinoUI').glob('*.lua')) + list(Path('tests').glob('*.lua'))):
    subprocess.run([LUA, '-e', f'assert(loadfile({json.dumps(str(file))}))'], check=True)
check(True, 'all shipping and test Lua syntax compiles under Lua 5.1')
bindings = ET.parse('AlbinoUI/Bindings.xml').getroot()
expected = {f'CLICK AlbinoUIBar{bar}Button{i}:LeftButton' for bar in (1, 2) for i in range(1, 13)}
check(bindings.tag == 'Bindings' and {b.attrib['name'] for b in bindings} == expected, '24 secure click bindings')
check(len(list(bindings)) == 24 and all(not (b.text or '').strip() for b in bindings), 'bindings contain no insecure execution')
source = '\n'.join(Path('AlbinoUI', f).read_text() for f in modules)
check(re.findall(r'SLASH_ALBINOUI\d+\s*=\s*"([^"]+)"', source) == ['/albino'], 'single slash root')
check(not re.search(r'(?m)^\s*(UseAction|CastSpellByName|RunMacroText|SetBinding)\s*\(', source), 'no insecure action execution or persistent binding rewrites')
check(not re.search(r'SetScript\("OnClick"', Path('AlbinoUI/ActionBars.lua').read_text()), 'secure OnClick stays intact')
check('SetScript("OnAttributeChanged"' not in Path('AlbinoUI/ActionBars.lua').read_text(), 'secure state attribute handler stays intact')
check('SavedVariables:' not in toc, 'placements not stored in shared addon variables')
print(f'RESULT {static} static checks passed', flush=True)
subprocess.run([LUA, 'tests/run.lua'], check=True)
for profile in ('legacy', 'unsupported', 'combat-login', 'namespaced-actions'):
    subprocess.run([LUA, 'tests/profiles.lua', profile], check=True)
