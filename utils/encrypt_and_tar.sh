#!/usr/bin/bash

# Copyright 2021  Mobvoi Inc(Author: Binbin Zhang)

if [ ! -f SAFEBOX/password ]; then
  echo "$0: please add password to SAFEBOX/password."
  exit 1
fi

PASSWORD=`cat SAFEBOX/password 2>/dev/null`
if [ -z "$PASSWORD" ]; then
  echo "$0: Error, SAFEBOX/password is empty."
  exit 1
fi

src=/ssd/nfs07/binbinzhang/wenetspeech/
dst=/ssd/nfs07/binbinzhang/wenetspeech_release
aes_list=$PWD/misc/data.list

rm -f $aes_list

pushd $src
for item in WenetSpeech.json audio/*/*/*; do
  echo "Processing $item"
  sub_dst=$dst/${item}.aes.tgz
  mkdir -p $(dirname $sub_dst)
  tar zcvf - $item | \
    openssl enc -e -aes-256-cbc -salt -pass pass:$PASSWORD -pbkdf2 -out $sub_dst
  md5=$(md5sum $sub_dst | awk '{print $1}')
  echo "$md5 ${item}.aes.tgz" >> $aes_list
done
popd
