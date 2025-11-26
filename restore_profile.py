from pathlib import Path
source = Path('tmp_head_main.dart').read_text()
start = source.index('class _ProfileInfoCard extends StatefulWidget')
end_marker = "class _UserWhiskeyList extends StatelessWidget"
end = source.index(end_marker, start)
content = source[start:end]
Path('lib/src/pages/dashboard/profile_info_widgets.dart').write_text("part of 'package:the_whiskey_manuscript_app/main.dart';\n\n" + content.strip() + '\n')
