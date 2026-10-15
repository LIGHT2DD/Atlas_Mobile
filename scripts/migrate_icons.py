import os
import re

ICON_MAP = {
    'access_time': 'clock',
    'access_time_filled': 'clock',
    'add': 'plus',
    'add_circle_outline': 'circle_plus',
    'arrow_drop_down': 'chevron_down',
    'arrow_forward_ios': 'chevron_right',
    'article_outlined': 'article',
    'assignment_outlined': 'clipboard_list',
    'assignment_turned_in_outlined': 'clipboard_check',
    'attach_file': 'paperclip',
    'bar_chart_outlined': 'chart_bar',
    'calendar_month_outlined': 'calendar',
    'calendar_today': 'calendar_event',
    'calendar_today_outlined': 'calendar_event',
    'cancel_outlined': 'circle_x',
    'check_circle_outline': 'circle_check',
    'chevron_right': 'chevron_right',
    'clear': 'x',
    'close': 'x',
    'code': 'code',
    'copy': 'copy',
    'dashboard_outlined': 'layout_dashboard',
    'delete_outline': 'trash',
    'description_outlined': 'file_description',
    'done_all': 'checks',
    'edit_document': 'file_pencil',
    'edit_outlined': 'pencil',
    'email_outlined': 'mail',
    'error_outline': 'alert_circle',
    'event_available': 'calendar_event',
    'event_outlined': 'calendar_event',
    'event_seat_outlined': 'armchair',
    'exit_to_app': 'logout',
    'fact_check_outlined': 'checklist',
    'feedback_outlined': 'message_circle',
    'flag_outlined': 'flag',
    'folder_zip_outlined': 'file_zip',
    'gavel_outlined': 'gavel',
    'grade_outlined': 'award',
    'grading': 'certificate',
    'group_add_outlined': 'user_plus',
    'group_off_outlined': 'user_off',
    'group_outlined': 'users',
    'group_work_outlined': 'circles_relation',
    'groups_3': 'users',
    'groups_3_outlined': 'users',
    'groups_outlined': 'users',
    'history': 'history',
    'history_outlined': 'history',
    'inbox_outlined': 'inbox',
    'insert_drive_file': 'file',
    'link': 'link',
    'lock_clock_outlined': 'clock',
    'lock_outline': 'lock',
    'lock_reset': 'lock_access',
    'lock_reset_rounded': 'lock_access',
    'login': 'login',
    'logout': 'logout',
    'mark_email_unread_outlined': 'mail_opened',
    'meeting_room_outlined': 'door_enter',
    'menu_book_outlined': 'book',
    'notes_outlined': 'notes',
    'notifications_none_outlined': 'bell',
    'notifications_outlined': 'bell',
    'numbers': 'numbers',
    'people_alt_outlined': 'users',
    'people_outline': 'users',
    'percent': 'percentage',
    'person': 'user',
    'person_add': 'user_plus',
    'person_add_alt': 'user_plus',
    'person_outline': 'user',
    'pie_chart_outline': 'chart_pie',
    'publish': 'upload',
    'rate_review_outlined': 'message_report',
    'refresh': 'rotate_clockwise',
    'rule_outlined': 'ruler',
    'schedule_outlined': 'clock',
    'school': 'school',
    'school_outlined': 'school',
    'school_rounded': 'school',
    'search': 'search',
    'shield_outlined': 'shield_check',
    'speed': 'gauge',
    'star': 'star',
    'star_border': 'star',
    'stars': 'sparkles',
    'title': 'heading',
    'title_outlined': 'heading',
    'upload_file': 'upload',
    'visibility': 'eye',
    'visibility_off': 'eye_off',
    'vpn_key_outlined': 'key',
    'warning_amber_rounded': 'alert_triangle',
    'workspace_premium': 'award',
    'workspace_premium_outlined': 'award'
}

TABLER_IMPORT = "import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';"
OLD_TABLER_IMPORT = "import 'package:tabler_icons/tabler_icons.dart';"

def process_file(fp):
    with open(fp, 'r', encoding='utf-8') as f:
        content = f.read()

    modified = content
    replacement_count = 0

    if OLD_TABLER_IMPORT in modified:
        modified = modified.replace(OLD_TABLER_IMPORT, TABLER_IMPORT)
        replacement_count += 1

    def replace_match(m):
        nonlocal replacement_count
        icon_name = m.group(1)
        if icon_name in ICON_MAP:
            replacement_count += 1
            return f'TablerIcons.{ICON_MAP[icon_name]}'
        else:
            print(f'WARNING: Unmapped icon {icon_name} in {fp}')
            return m.group(0)

    modified = re.sub(r'\bIcons\.([a-zA-Z0-9_]+)\b', replace_match, modified)

    if replacement_count > 0:
        if TABLER_IMPORT not in modified:
            # Place after the last import line
            import_matches = list(re.finditer(r"^import\s+['\"][^'\"]+['\"];", modified, re.MULTILINE))
            if import_matches:
                last_import = import_matches[-1]
                idx = last_import.end()
                modified = modified[:idx] + f'\n{TABLER_IMPORT}' + modified[idx:]
            else:
                modified = f'{TABLER_IMPORT}\n' + modified

        with open(fp, 'w', encoding='utf-8', newline='\n') as f:
            f.write(modified)

    return replacement_count

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'mobile'))
    total_files = 0
    total_replacements = 0

    for base in ['lib', 'test']:
        target_path = os.path.join(root_dir, base)
        for root, _, files in os.walk(target_path):
            for file in files:
                if file.endswith('.dart'):
                    fp = os.path.join(root, file)
                    c = process_file(fp)
                    if c > 0:
                        total_files += 1
                        total_replacements += c
                        print(f'Updated {c} icons in: {os.path.relpath(fp, root_dir)}')

    print(f'\nTotal: {total_replacements} icons replaced across {total_files} files.')

if __name__ == '__main__':
    main()
