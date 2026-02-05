import json
import os

def fix_tamil_arb():
    en_path = 'lib/l10n/app_en.arb'
    ta_path = 'lib/l10n/app_ta.arb'

    print(f"Reading {en_path}...")
    with open(en_path, 'r', encoding='utf-8') as f:
        en_data = json.load(f)

    print(f"Reading {ta_path}...")
    with open(ta_path, 'r', encoding='utf-8') as f:
        ta_data = json.load(f)

    missing_keys = 0
    for key, value in en_data.items():
        if key not in ta_data:
            # Check if it's a metadata key (starts with @)
            if key.startswith('@'):
                # Only add metadata if the corresponding key exists or is being added
                real_key = key[1:]
                if real_key in en_data: # logic: if base key exists, we might need metadata
                     # simple approach: just copy everything missing
                     ta_data[key] = value
                     missing_keys += 1
            else:
                ta_data[key] = value # Use English value as fallback
                missing_keys += 1

    print(f"Added {missing_keys} missing keys to Tamil ARB.")

    with open(ta_path, 'w', encoding='utf-8') as f:
        json.dump(ta_data, f, indent=4, ensure_ascii=False)
    
    print("Done.")

if __name__ == "__main__":
    fix_tamil_arb()
