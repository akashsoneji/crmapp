#!/usr/bin/env python3
"""Bulk rename AppColors.* references in a Dart file."""
import sys

path = sys.argv[1]
with open(path) as f:
    s = f.read()

replacements = [
    ('AppColors.textSecondaryColor', 'AppColors.textSecondary'),
    ('AppColors.textPrimaryColor', 'AppColors.textPrimary'),
    ('AppColors.primaryColor', 'AppColors.primary'),
    ('AppColors.borderColor', 'AppColors.border'),
]
for a, b in replacements:
    n = s.count(a)
    s = s.replace(a, b)
    print(f'{a} -> {b}: {n} replacements')

with open(path, 'w') as f:
    f.write(s)
print('done')