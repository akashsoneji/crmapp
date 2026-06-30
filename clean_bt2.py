#!/usr/bin/env python3
"""Clean stray backticks and markdown code fences from a Dart file."""
import sys
import re

path = sys.argv[1]
with open(path, 'r') as fh:
    text = fh.read()

# Remove any run of three or more backticks
bt = chr(96)
pattern = re.compile(r'(' + bt + r'){3,}')
matches = pattern.findall(text)
print(f'Found {len(matches)} backtick runs of len>=3 in {path}')

text = pattern.sub('', text)

# Remove lines that are ONLY backticks (any amount)
lines = text.splitlines(keepends=True)
cleaned = []
removed = 0
for line in lines:
    s = line.strip()
    if s and all(c == bt for c in s):
        removed += 1
        continue
    cleaned.append(line)

print(f'Removed {removed} lines of only-backticks')
with open(path, 'w') as fh:
    fh.writelines(cleaned)
print('Done.')
