from pathlib import Path
for i,line in enumerate(Path('lib/src/pages/dashboard/common_dialogs.dart').read_text().splitlines(),1):
    print(f"{i}: {line}")
