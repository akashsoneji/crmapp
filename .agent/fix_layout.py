#!/usr/bin/env python3
import sys

path = '/Users/akash/Desktop/Soneji Infotech/xelthio/app/crmapp/lib/screens/home/more/copytrading/master_dashboard_screen.dart'

with open(path, 'r') as f:
    content = f.read()

# STEP 1: Wrap _OpenPositionItemTile's outer Container with ClipRRect
opening_old = '''    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowAlpha(0.02),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column('''

opening_new = '''    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.12)),
        ),
        child: Column('''

count = content.count(opening_old)
print(f'Opening pattern found {count} times')
if count == 1:
    content = content.replace(opening_old, opening_new)
    print('STEP 1 done - opening wrapped')

# STEP 2: Find unique closing pattern
marker = '\nclass _OpenPositionsSummaryCard extends StatelessWidget {'
pos = content.find(marker)
if pos > 0:
    before = content[:pos]
    expected = '    );\n  }\n}\n'
    if before.endswith(expected):
        new_before = before[:-len(expected)] + '    ),\n  );\n}\n'
        content = new_before + content[pos:]
        print('STEP 2 done - closing braces fixed')
    else:
        print(f'DBG last 200 before marker: {repr(before[-200:])}')

with open(path, 'w') as f:
    f.write(content)
print('File saved')
