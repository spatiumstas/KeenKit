import os
import random
import string
import sys
import re

def generate_random_string(length, chars):
    return ''.join(random.choice(chars) for _ in range(length))

def replace_values(filename):
    current_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(current_dir)
    file_path = os.path.join(parent_dir, filename)

    try:
        with open(file_path, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f'Файл {file_path} не найден. Пожалуйста, проверьте путь к файлу.')
        return

    patterns = {
        'servicetag': (b'\x73\x65\x72\x76\x69\x63\x65\x74\x61\x67\x3D', string.digits),
        'sernumb': (b'\x73\x65\x72\x6E\x75\x6D\x62\x3D', string.digits),
        'servicepass': (b'\x73\x65\x72\x76\x69\x63\x65\x70\x61\x73\x73\x3D', string.ascii_letters + string.digits)
    }

    replacements = {}

    for name, (pattern, chars) in patterns.items():
        pattern_regex = re.escape(pattern) + b'(.*?)\x00'
        matches = list(re.finditer(pattern_regex, data))
        if matches:
            for match in matches:
                start, end = match.span(1)
                original_value = match.group(1)
                if name not in replacements:
                    if name == 'sernumb':
                        new_value = (original_value[:-4] + generate_random_string(4, chars).encode())
                    else:
                        new_value = generate_random_string(end - start, chars).encode()
                    
                    replacements[name] = new_value

                    if name == 'servicetag':
                        servicetag_last_two_bytes = new_value[-4:]

                else:
                    new_value = replacements[name]

                data = data[:start] + new_value + data[start + len(new_value):]
                print(f'Значение {name} было успешно заменено на {new_value.decode("utf-8", errors="ignore")}.')
        else:
            print(f'Переменная {name} не найдена.')

    if 'servicetag' in replacements:
        servicetag_last_two_bytes = replacements['servicetag'][-4:]
        servicetag_suffix = servicetag_last_two_bytes.decode('utf-8', errors='ignore')
    else:
        print("Не удалось получить последние 2 байта из servicetag. Использую 'XXXX' по умолчанию.")
        servicetag_suffix = "XXXX"

    base, ext = os.path.splitext(filename)
    new_filename = f"{base}_{servicetag_suffix}{ext}"
    new_file_path = os.path.join(parent_dir, new_filename)

    with open(new_file_path, 'wb') as f:
        f.write(data)
        # print(f'Новые данные были успешно записаны в файле {new_file_path}')  
        # print('')

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1) 
    input_filename = sys.argv[1]
    replace_values(input_filename)
