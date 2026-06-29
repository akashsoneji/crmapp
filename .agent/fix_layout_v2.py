#!/usr/bin/env python3
"""
Strategy:
1. Wrap Container with ClipRRect (step 1 only - opening change)
2. Replace the closing '    );\\n  }\\n}\\n' (Container close + build close + class close)
   with '    ),\\n  );\\n}\\n' (Container close + ClipRRect close)
   BUT only when that pattern is preceded by _OpenPositionItemTile build content.

We will identify the END of _OpenPositionItemTile's build method uniquely
by checking that immediately AFTER the closing pattern (before class declaration)
appears specific markers like 'crossFadeState' which only exists in _OpenPositionItemTile.
"""

path = '/Users/akash/Desktop/Soneji Infotech/xelthio/app/crmapp/lib/screens/home/more/copytrading/master_dashboard_screen.dart'

with open(path, 'r') as f:
    content = f.read()

# STEP 1 (verified): Wrap opening Container with ClipRRect
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

# STEP 2 (safer): Find the EXACT end of _OpenPositionItemTile's build method
# The build method end is right before "class _OpenPositionsSummaryCard"
# Between the start of _OpenPositionItemTile and its end, there MUST be:
#   - AnimatedCrossFade(
#   - crossFadeState:
# These are unique to _OpenPositionItemTile's build method

# After step 1, the structure at the END of _OpenPositionItemTile.build should be:
#   ...CrossFadeState.showFirst,
#   duration: ...,
# ),                         <- AnimatedCrossFade close (no semicolon)
# ],                         <- Column children list close
# ),                         <- Column close
# );                         <- Container close WITH semicolon (originally)
# }                          <- build method close
# }                          <- class close
# (blank line)
# class _OpenPositionsSummaryCard extends StatelessWidget {

# We want:
#   ...
# );                         <- AnimatedCrossFade close (no semicolon)
# ],                         <- Column children list close
# ),                         <- Column close
# ),                         <- Container close (NEW: now has comma not semicolon)
# );                         <- ClipRRect close with semicolon (NEW)
# }                          <- build method close
# }                          <- class close

# Find the marker
marker = '\nclass _OpenPositionsSummaryCard extends StatelessWidget {'
pos = content.find(marker)
if pos > 0:
    # Look at the last 200 chars before marker
    before = content[:pos]
    print(f'Last 250 chars: {repr(before[-250:])}')

    # Old pattern (END of _OpenPositionItemTile.build) should be:
    #       ),\n    );\n  }\n}\n
    expected_old_end = '      ),\n    );\n  }\n}\n'
    new_end = '      ),\n    ),\n  );\n}\n'
    if before.endswith(expected_old_end):
        new_before = before[:-len(expected_old_end)] + new_end
        content = new_before + content[pos:]
        print('STEP 2 done')
    else:
        # Try alternative: indented with 8 spaces
        expected_old_end2 = '    ),\n  );\n}\n'
        new_end2 = '    ),\n  ),\n}\n'
        if before.endswith(expected_old_end2):
            # No wait, this is the same as original. Skip
            pass
        else:
            # Find the LAST occurrence of the pattern before marker
            # We need to find '    );\n  }\n}\n' preceded by '      ),\n' to be unique
            # Look for the row "          )," (AnimatedCrossFade close with trailing comma)
            # Right after the 'crossFadeState' line
            # Use a more robust approach

            # Look for 'crossFadeState:' to find the AnimatedCrossFade section
            crossfade_idx = before.rfind('crossFadeState:')
            if crossfade_idx > 0:
                # From crossfade_idx, find the build method end (next '    );\n  }\n}\n')
                # Because the AnimatedCrossFade has children close, Column close, Container close
                search_start = crossfade_idx
                close_pattern = '\n    );\n  }\n}\n'
                close_idx = before.find(close_pattern, search_start)
                if close_idx > 0:
                    # The position close_idx is where '    );' starts
                    # Replace '    );\n  }\n}\n' with '    ),\n  );\n}\n' AT THIS POSITION ONLY
                    actual_end = close_idx + 1  # +1 to skip the leading newline
                    end_str = before[actual_end:actual_end + len(close_pattern) - 1]
                    # end_str should be '    );\n  }\n}\n'
                    new_replacement = '    ),\n  );\n}\n'
                    new_before = before[:actual_end] + new_replacement + content[pos+1:]  # +1 because pos has leading \n
                    # But we already excluded that with content[pos:] which keeps the \n
                    # Let's be careful
                    content = before[:actual_end] + new_replacement + before[actual_end + len('    );\n  }\n}\n'):] + content[pos:]
                    # Actually the cleanest is:
                    content = before[:actual_end] + new_replacement + content[actual_end + len('    );\n  }\n}\n'):]
                    print('STEP 2 done (using crossFadeState anchor)')
                else:
                    print('close pattern not found after crossFadeState')
            else:
                print('crossFadeState not found')

with open(path, 'w') as f:
    f.write(content)
print('File saved')
