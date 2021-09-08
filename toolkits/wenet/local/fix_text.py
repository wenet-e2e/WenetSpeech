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

def read_text(text):
    h_t = open(text, 'r')
    text_dic = {}
    for line_str in h_t:
        utt, text_str = line_str.strip().split(maxsplit=1)
        text_dic[utt] = text_str
    h_t.close()
    return text_dic

def fix(text_dic):
    text_dic_fix = {}
    for utt, text in text_dic.items():
        # Lowercase to uppercase
        text = text.upper()

        # Replace the spaces between English with ▁
        text = re.sub(r"([A-Z]){1}\s([A-Z]){1}", r"\1▁\2", text)
        text = re.sub(r"([A-Z]){1}\s([A-Z]){1}", r"\1▁\2", text)

        # Delete other special characters
        text = re.sub(r"[^\u4e00-\u9fffA-Z0-9▁]", "", text)

        text_dic_fix[utt] = text
    return text_dic_fix

def output_text(text, text_dic):
    h_t = open(text, 'w')
    for utt, text in text_dic.items():
        h_t.write("{} {}\n".format(utt, text))
    h_t.close()

def main():
    text = sys.argv[1]

    text_dic = read_text(text)
    text_dic = fix(text_dic)
    output_text(text, text_dic)

if __name__ == '__main__':
    main()
