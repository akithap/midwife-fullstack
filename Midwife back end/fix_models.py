import re

path = 'sql_app/models.py'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace DATETIME with DateTime
new_content = re.sub(r'Column\(DATETIME', 'Column(DateTime', content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Fixed DATETIME usages.")
