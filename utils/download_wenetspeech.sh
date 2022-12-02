#!/usr/bin/env bash
# Copyright 2021  Jiayu Du
#                 Seasalt AI, Inc (Author: Guoguo Chen)
#                 Tsinghua University (Author: Shuzhou Chai)
#                 Mobvoi Inc (Author: Binbin Zhang)

set -e
set -o pipefail

stage=0
modelscope=false
WENETSPEECH_RELEASE_URL=http://wenet.meeting.tencent.com/WenetSpeech

if [ $# -ne 2 ]; then
  echo "Usage: $0 <download-dir> <untar-dir>"
  echo " e.g.: $0 /disk1/audio_data/wenetspeech_download /disk1/audio_data/wenetspeech_untar"
  echo ""
  echo "We suggest having at least 500G of free space for the download and untar"
  echo "directory, respectively. If dataset resources are updated, "
  echo "you can re-run this script for incremental download."
  exit 1
fi

download_dir=$(realpath $1)
untar_dir=$(realpath $2)
mkdir -p $download_dir || exit 1;
mkdir -p $untar_dir || exit 1;

# Check operating system
if [ `uname -s` != 'Linux' ] && [ `uname -s` != 'Darwin' ]; then
  echo "$0: We only support Linux and Mac OS downloading."
  exit 1
fi

# Check credential
if [ ! -f SAFEBOX/password ]; then
  echo "$0: Please apply for the download credentials (see the \"Download\""
  echo "$0: section in README) and it to SAFEBOX/password."
  exit 1
fi
PASSWORD=`cat SAFEBOX/password 2>/dev/null`
if [ -z "$PASSWORD" ]; then
  echo "$0: Error, SAFEBOX/password is empty."
  exit 1
fi

# Check downloading tools
if ! which wget >/dev/null; then
  echo "$0: Error, please make sure you have wget installed."
  exit 1
fi
if ! which openssl >/dev/null; then
  echo "$0: Error, please make sure you have openssl installed."
  exit 1
fi

openssl_distro=`openssl version | awk '{print $1}'`
required_distro="OpenSSL"
if [[ "$openssl_distro" != "$required_distro" ]]; then
  echo "$0: Unsupported $openssl_distro detected, please use $required_distro"
  echo "$0: On mac, you should try: brew install openssl"
  exit 1
fi

openssl_version=`openssl version|sed -E 's/^.*([0-9]+\.[0-9]+\.[0-9]+).*$/\1/g'`
required_version="1.1.1"
older_version=$(printf "$required_version\n$openssl_version\n"|sort -V|head -n1)
if [[ "$older_version" != "$required_version" ]]; then
  echo "$0: The script requires openssl version $required_version or newer."
  echo "$0: Please download the openssl source code, and install openssl"
  echo "$0: version $required_version"
  exit 1
fi

download_object_from_release() {
  local remote_md5=$1
  local obj=$2
  echo "$0: Downloading $obj remote_md5=$remote_md5"

  local remote_obj=${WENETSPEECH_RELEASE_URL}/$obj
  local local_obj=${download_dir}/$obj

  local location=$(dirname $local_obj)
  mkdir -p $location || exit 1;

  if [ -f $local_obj ]; then
    if [[ `uname -s` == "Linux" ]]; then
      local local_md5=$(md5sum $local_obj | awk '{print $1}')
    elif [[ `uname -s` == "Darwin" ]]; then
      local local_md5=$(md5 -r $local_obj | awk '{print $1}')
    else
      echo "$0: only supports Linux and Mac OS"
      exit 1
    fi

    if [ "$local_md5" == "$remote_md5" ]; then
      echo "$0: Skipping $local_obj, successfully retrieved already."
    else
      echo "$0: $local_obj corrupted or out-of-date, start to re-download."
      rm $local_obj || exit 1;
      wget -t 20 -T 90 -P $location $remote_obj || exit 1;
    fi
  else
    wget -t 20 -T 90 -P $location $remote_obj || exit 1;
  fi

  echo "$0: $obj successfully synchronized to $local_obj"
}

process_downloaded_object() {
  local obj=$1
  echo "$0: Processing $obj"
  openssl aes-256-cbc -d -salt -pass pass:$PASSWORD -pbkdf2 -in $obj | \
    tar xzf - -C $untar_dir || exit 1;
}


# User agreement
if [ $stage -le 0 ]; then
  echo "$0: Start to download WenetSpeech user agreement"
  wget -c -P $download_dir \
    ${WENETSPEECH_RELEASE_URL}/TERMS_OF_ACCESS || exit 1;
  GREEN='\033[0;32m'
  NC='\033[0m'       # No Color
  echo -e "${GREEN}"
  echo -e "BY PROCEEDING YOU AGREE TO THE FOLLOWING WENETSPEECH TERMS OF ACCESS:"
  echo -e ""
  echo -e "=============== WENETSPEECH DATASET TERMS OF ACCESS ==============="
  cat $download_dir/TERMS_OF_ACCESS
  echo -e "=================================================================="
  echo -e "$0: WenetSpeech downloading will start in 5 seconds"
  echo -e ""

  for t in $(seq 5 -1 1); do
    echo -e "$t"
    sleep 1
  done
  echo -e "${NC}"
fi

# Download from list
if [ $stage -le 2 ]; then
  echo "$0: Start to download WenetSpeech files(*.aes.tgz)"
  if [ $modelscope == true ]; then
    CACHE_HOME=$download_dir python utils/download_from_modelscope.py
  else
    grep -v '^#' metadata/v1.list | (while read line; do
      download_object_from_release $line || exit 1;
    done) || exit 1;
  fi
fi

# Process data
if [ $stage -le 3 ]; then
  echo "$0: Start to process the downloaded files(*.aes.tgz)"
  cp $download_dir/TERMS_OF_ACCESS $untar_dir
  if [ $modelscope == true ]; then
    ms_download_dir=$download_dir/modelscope/hub/datasets/downloads/wenet/WenetSpeech/master
    for tgz in `ls $ms_download_dir | grep -v '\.'`; do
      process_downloaded_object ${ms_download_dir}/$tgz || exit 1;
    done || exit 1;
  else
    grep -v '^#' metadata/v1.list | (while read md5 tgz; do
      process_downloaded_object ${download_dir}/$tgz || exit 1;
    done) || exit 1;
  fi
fi

echo "$0: Done"
