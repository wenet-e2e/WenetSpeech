# Copyright 2021  NPU, ASLP Group (Author: Qijie Shao)

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# usage: python3 fix_text.py text

import sys
import re

def read_text(text_file):
    text_dic = {}
    with open(text_file, 'r', encoding='UTF-8') as fin:
        for line_str in fin:
            utt, text_str = line_str.strip().split(maxsplit=1)
            text_dic[utt] = text_str
    return text_dic

def fix_text(text_dic, text_file):
    with open(text_file, 'w', encoding='UTF-8') as fout:
        for utt, text in text_dic.items():
            # Lowercase to uppercase
            text = text.upper()

            # Replace the spaces between English with ▁
            text = re.sub(r"([A-Z]){1}\s([A-Z]){1}", r"\1▁\2", text)
            text = re.sub(r"([A-Z]){1}\s([A-Z]){1}", r"\1▁\2", text)

            # Delete other special characters
            text = re.sub(r"[^\u4e00-\u9fffA-Z0-9▁]", "", text)

            fout.write("{} {}\n".format(utt, text))

def main():
    text_file = sys.argv[1]
    text_dic = read_text(text_file)
    fix_text(text_dic, text_file)

if __name__ == '__main__':
    main()
