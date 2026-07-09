import re
f = '/Users/akash/Desktop/Soneji Infotech/xelthio/app/crmapp/lib/controllers/copy_trading/copy_trading_master_dashboard_controller.dart'
with open(f, 'r') as fh:
    text = fh.read()
pattern = re.compile(r'`{3,}')
matches = pattern.findall(text)
print(f'Found {len(matches)} backtick runs of len>=3')
text2 = pattern.sub('', text)
lines = text2.splitlines(keepends=True)
cleaned = []
for line in lines:
    if line.strip() and all(c == '`' for c in line.strip()):
        print(f'Removing line: {repr(line)}')
        continue
    cleaned.append(line)
with open(f, 'w') as fh:
    fh.writelines(cleaned)
print('done')
