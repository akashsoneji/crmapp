#!/usr/bin/env python3
"""
Surgical fix for layout assertion error in _OpenPositionItemTile:
- Wrap opening Container with ClipRRect, remove boxShadow + borderRadius
- Fix the END with PRECISE replacement that preserves build/class closing braces
"""

path = '/Users/akash/Desktop/Soneji Infotech/xelthio/app/crmapp/lib/screens/home/more/copytrading/master_dashboard_screen.dart'

with open(path, 'r') as f:
    content = f.read()

# STEP 1: Wrap opening Container with ClipRRect
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

assert content.count(opening_old) == 1, 'opening pattern not found or multiple matches'
content = content.replace(opening_old, opening_new)
print('STEP 1 done - opening wrapped')

# STEP 2: Fix the END. Use a precise multi-line replacement.
# Look for the build method end right before "class _OpenPositionsSummaryCard"
# Original pattern (after step 1):
#   ...                <- end of crossFadeState
#         ],           <- Column children list close
#       ),             <- Column close
#     );               <- Container close WITH semicolon (originally, this was the outermost)
#   }                  <- BUILD METHOD CLOSE
# }                    <- CLASS CLOSE
# (blank)
# class _OpenPositionsSummaryCard

# After step 2, it should be:
#   ...
#         ],
#       ),
#     ),               <- Container close WITH comma (was ; now ,)
#   );                 <- ClipRRect close WITH semicolon
#   }
# }

# The unique closing pattern (12 lines including the blank and next class)
old_closing = '''    );
  }
}

class _OpenPositionsSummaryCard extends StatelessWidget {'''

new_closing = '''    ),
  );
}

class _OpenPositionsSummaryCard extends StatelessWidget {'''

count = content.count(old_closing)
print(f'Closing pattern found {count} times')
assert count == 1, 'closing pattern not unique - aborting'
content = content.replace(old_closing, new_closing)
print('STEP 2 done - closing fixed')

with open(path, 'w') as f:
    f.write(content)
print('File saved successfully')