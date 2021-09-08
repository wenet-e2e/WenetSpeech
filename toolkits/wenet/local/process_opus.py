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

# process_opus.py: segmentation and downsampling of opus audio

# usage: python3 process_opus.py wav.scp segments output_wav.scp

from pydub import AudioSegment
import sys
import os

def read_file(wav_scp, segments):
    h_wav = open(wav_scp, 'r')
    wav_scp_dict = {}
    for line_str in h_wav:
        wav_id, path = line_str.strip().split()
        wav_scp_dict[wav_id] = path
    h_wav.close()

    h_seg = open(segments, 'r')
    wav_path_dict = {}
    start_time_dict = {}
    end_time_dict = {}
    for line_str in h_seg:
        if line_str.find("\t") == -1:
            utt_id, wav_id, start_time, end_time = line_str.strip().split()
        else:
            utt_id, wav_id, start_time, end_time = line_str.strip().split()
        wav_path_dict[utt_id] = wav_scp_dict[wav_id]
        start_time_dict[utt_id] = float(start_time)
        end_time_dict[utt_id] = float(end_time)
    h_seg.close()
    return wav_path_dict, start_time_dict, end_time_dict

def output(output_wav_scp, wav_path_dict, start_time_dict, end_time_dict):
    utt_list = wav_path_dict.keys()
    utt_len = len(utt_list)

    a = 0
    percent = 0.01
    step = int(utt_len * percent)
    h_wav_scp = open(output_wav_scp, 'w')
    previous_wav_path = ""
    for utt_id in utt_list:
        current_wav_path = wav_path_dict[utt_id]
        output_dir = (os.path.dirname(current_wav_path)).replace("audio", 'audio_seg')
        seg_wav_path = os.path.join(output_dir, utt_id + '.wav')

        # if not os.path.exists(output_dir):
        #     os.makedirs(output_dir)

        if current_wav_path != previous_wav_path:
            source_wav = AudioSegment.from_file(current_wav_path)
        previous_wav_path = current_wav_path

        start = int(start_time_dict[utt_id] * 1000)
        end = int(end_time_dict[utt_id] * 1000)
        target_audio = source_wav[start:end].set_frame_rate(16000)
        target_audio.export(seg_wav_path, format="wav")

        h_wav_scp.write("{} {}\n".format(utt_id, seg_wav_path))
        if (a != 0) and (a % step == 0):
            print("seg wav finished: {}%".format(int(a / step)))
        a += 1
    h_wav_scp.close()


def main():
    wav_scp = sys.argv[1]
    segments = sys.argv[2]
    output_wav_scp = sys.argv[3]

    wav_path_dict, start_time_dict, end_time_dict = read_file(wav_scp, segments)
    output(output_wav_scp, wav_path_dict, start_time_dict, end_time_dict)

if __name__ == '__main__':
    main()
