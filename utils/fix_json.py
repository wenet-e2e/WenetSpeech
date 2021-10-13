# Copyright 2021  Mobvoi Inc(Binbin Zhang)

import json
import re
import sys

with open(sys.argv[1], 'r', encoding='utf8') as fin:
    json_data = json.load(fin)

for long_audio in json_data['audios']:
    if 'batch_id' in long_audio:
        del long_audio['batch_id']
    assert 'segments' in long_audio
    for segment in long_audio['segments']:
        text = segment['text']
        # remove full white space
        text = re.sub(r'　', '', text)
        # remove whitespace
        text = re.sub(r' ', '', text)
        # remove no-break space--chr(160)
        text = re.sub(r'\u00A0', '', text)
        # remove omega
        text = re.sub(r'Ω', '', text)
        # remove space in Chinese char, apply it twice
        text = re.sub(r'([^a-zA-Z ]+) ([^a-zA-Z ]+)', '\\1\\2', text)
        text = re.sub(r'([^a-zA-Z ]+) ([^a-zA-Z ]+)', '\\1\\2', text)

        segment['text'] = text

with open(sys.argv[2], 'w', encoding='utf8') as fout:
    json.dump(json_data, fout, indent=4, ensure_ascii=False)
