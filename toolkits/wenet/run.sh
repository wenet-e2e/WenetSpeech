#!/bin/bash

# Copyright 2021  Mobvoi Inc(Author: Di Wu, Binbin Zhang)
#                 NPU, ASLP Group (Author: Qijie Shao)

. ./path.sh || exit 1;

# Use this to control how many gpu you use, It's 1-gpu training if you specify
# just 1gpu, otherwise it's is multiple gpu training based on DDP in pytorch
export CUDA_VISIBLE_DEVICES="0,1,2,3,4,5,6,7"
stage=3 # start from 0 if you need to start from data preparation
stop_stage=3

# The num of nodes or machines used for multi-machine training
# Default 1 for single machine/node
# NFS will be needed if you want run multi-machine training
num_nodes=1
# The rank of each node or machine, range from 0 to num_nodes -1
# The first node/machine sets node_rank 0, the second one sets node_rank 1
# the third one set node_rank 2, and so on. Default 0
node_rank=0

# data
# use your own data path. You need to download the WenetSpeech dataset by yourself.
wenetspeech_data_dir=/home/work_nfs4_ssd/qjshao/qjshao_workspace/DATASET/wenetspeech

# WenetSpeech training set
set=L
train_set=train_`echo $set |tr 'A-Z' 'a-z'`
train_dev=dev
test_set_1=test_net
test_set_2=test_meeting

# wav data dir
wave_data=data
nj=40
# Optional train_config
# 1. conf/train_transformer.yaml: Standard Conformer
# 2. conf/train_transformer_bidecoder.yaml: Bidecoder Conformer
train_config=conf/train_conformer_bidecoder.yaml
checkpoint=
cmvn=false
dir=exp/conformer_bidecoder

# use average_checkpoint will get better result
average_checkpoint=true
# maybe you can try to adjust it if you can not get close results as README.md
average_num=5
decode_modes="attention_rescoring ctc_greedy_search"

. tools/parse_options.sh || exit 1;

set -u
set -o pipefail

# Data preparation
if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    echo "Data preparation"
    local/wenetspeech_data_prep.sh \
       --train-subset $set \
       --stage 1 \
       $wenetspeech_data_dir \
       ${wave_data} \
       || exit 1;

    for x in ${train_set} ${train_dev} ${test_set_1} ${test_set_2};do
        tmpdir=temp_${RANDOM}
        mkdir $tmpdir

        # note: This scipt will create a "audio_seg" directory under
        # the original wenetspeech folder to store the processed audio,
        # please ensure that your disk have sufficient space
        # (the "audio_seg" directory is about 2.1TB)
        awk '{print $2}' ${wave_data}/${x}/wav.scp | \
            sed 's:audio:audio_seg:g' | \
            while read line; do dirname $line;done | uniq | \
            while read line; do mkdir -p $line;done

        for i in `seq 1 ${nj}`;do
        {
            tools/data/split_scp.pl -j ${nj} ${i} --one-based \
                ${wave_data}/${x}/segments \
                $tmpdir/segments.${i}

            python3 local/process_opus.py \
                ${wave_data}/${x}/wav.scp \
                $tmpdir/segments.${i} \
                $tmpdir/wav.scp.${i}
        }&
        done
        wait
        mv ${wave_data}/${x}/wav.scp ${wave_data}/${x}/wav.scp.ori
        for i in `seq 1 ${nj}`;do
            cat $tmpdir/wav.scp.${i} >> ${wave_data}/${x}/wav.scp
        done

        rm -rf $tmpdir
    done

    for x in ${train_set} ${train_dev} ${test_set_1} ${test_set_2};do
       cp ${wave_data}/${x}/text ${wave_data}/${x}/text.org

       paste -d " " <(cut -f 1 ${wave_data}/${x}/text.org) \
           <(cut -f 2- ${wave_data}/${x}/text.org | \
           tr 'a-z' 'A-Z' | \
           sed 's/\([A-Z]\) \([A-Z]\)/\1▁\2/g' | \
           sed 's/\([A-Z]\) \([A-Z]\)/\1▁\2/g' | \
           tr -d " ")\
       > ${wave_data}/${x}/text

       sed -i 's/\xEF\xBB\xBF//' ${wave_data}/${x}/text
    done
fi

# compute cmvn
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "compute cmvn"
    # optional
    # compute cmvn, perhaps you can sample some segmented examples fron wav.scp for cmvn computation
    if $cmvn ;then
        python3 tools/compute_cmvn_stats.py \
        --num_workers ${nj} \
        --train_config $train_config \
        --in_scp $wave_data/$train_set/wav.scp \
        --out_cmvn $wave_data/$train_set/global_cmvn \
        || exit 1;
    fi
fi

dict=${wave_data}/dict/lang_char.txt
echo "dictionary: ${dict}"
# Make train dict
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "Make a dictionary"
    mkdir -p $(dirname $dict)
    echo "<blank> 0" > ${dict} # 0 will be used for "blank" in CTC
    echo "<unk> 1" >> ${dict} # <unk> must be 1
    tools/text2token.py -s 1 -n 1 --space "▁" data/${train_set}/text \
        | cut -f 2- -d" " | tr " " "\n" \
        | sort | uniq | grep -a -v -e '^\s*$' \
        | awk '{print $0 " " NR+1}' >> ${dict} \
        || exit 1;
    num_token=$(cat $dict | wc -l)
    echo "<sos/eos> $num_token" >> $dict # <eos>
fi

# Prepare wenet requried data
if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "Prepare data, prepare requried format"
    for x in ${train_set} ${train_dev} ${test_set_1} ${test_set_2}; do
        tools/format_data.sh \
            --nj ${nj} \
            --feat-type wav \
            --feat ${wave_data}/$x/wav.scp \
            ${wave_data}/$x \
            ${dict} \
            > ${wave_data}/$x/format.data \
            || exit 1;
    done
fi

# Training
if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    mkdir -p $dir
    INIT_FILE=$dir/ddp_init
    rm -f $INIT_FILE # delete old one before starting
    init_method=file://$(readlink -f $INIT_FILE)
    echo "$0: init method is $init_method"
    num_gpus=$(echo $CUDA_VISIBLE_DEVICES | awk -F "," '{print NF}')
    # Use "nccl" if it works, otherwise use "gloo"
    dist_backend="gloo"
    # The total number of processes/gpus, so that the master knows
    # how many workers to wait for.
    # More details about ddp can be found in
    # https://pytorch.org/tutorials/intermediate/dist_tuto.html
    world_size=`expr $num_gpus \* $num_nodes`
    echo "total gpus is: $world_size"
    cmvn_opts=
    $cmvn && cp ${wave_data}/${train_set}/global_cmvn $dir
    $cmvn && cmvn_opts="--cmvn ${dir}/global_cmvn"
    # train.py will write $train_config to $dir/train.yaml with model input
    # and output dimension, train.yaml will be used for inference or model
    # export later
    for ((i = 0; i < $num_gpus; ++i)); do
    {
        gpu_id=$(echo $CUDA_VISIBLE_DEVICES | cut -d',' -f$[$i+1])
        # Rank of each gpu/process used for knowing whether it is
        # the master of a worker.
        rank=`expr $node_rank \* $num_gpus + $i`
        python wenet/bin/train.py --gpu $gpu_id \
            --config $train_config \
            --train_data $wave_data/$train_set/format.data \
            --cv_data $wave_data/$train_dev/format.data \
            ${checkpoint:+--checkpoint $checkpoint} \
            --model_dir $dir \
            --ddp.init_method $init_method \
            --ddp.world_size $world_size \
            --ddp.rank $rank \
            --ddp.dist_backend $dist_backend \
            --num_workers 4 \
            $cmvn_opts \
            --pin_memory
    } &
    done
    wait
fi

# test
if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    # Test model, please specify the model you want to test by --checkpoint
    decode_checkpoint=$dir/avg_${average_num}.pt
    # TODO, Add model average here
    if [ ${average_checkpoint} == true ]; then
        echo "do model average and final checkpoint is $decode_checkpoint"
        python wenet/bin/average_model.py \
            --dst_model $decode_checkpoint \
            --src_path $dir  \
            --num ${average_num} \
            --val_best
    fi
    # Specify decoding_chunk_size if it's a unified dynamic chunk trained model
    # -1 for full chunk
    decoding_chunk_size=
    ctc_weight=0.5
    # Polling GPU id begin with index 0
    num_gpus=$(echo $CUDA_VISIBLE_DEVICES | awk -F "," '{print NF}')
    idx=0
    for test in ${test_set_1} ${test_set_2}; do
        for mode in ${decode_modes}; do
        {
            {
                test_dir=$dir/${test}_${mode}
                mkdir -p $test_dir
                gpu_id=$(echo $CUDA_VISIBLE_DEVICES | cut -d',' -f$[$idx+1])
                python wenet/bin/recognize.py --gpu $gpu_id \
                    --mode $mode \
                    --config $dir/train.yaml \
                    --test_data $wave_data/$test/format.data \
                    --checkpoint $decode_checkpoint \
                    --beam_size 20 \
                    --batch_size 1 \
                    --penalty 0.0 \
                    --dict $dict \
                    --result_file $test_dir/text \
                    --ctc_weight $ctc_weight \
                    ${decoding_chunk_size:+--decoding_chunk_size $decoding_chunk_size}

                # a raw version wer without refining processs
                python tools/compute-wer.py --char=1 --v=1 \
                    $wave_data/$test/text $test_dir/text > $test_dir/wer

            } &
            ((idx+=1))
            if [ $idx -eq $num_gpus ]; then
              idx=0
            fi
        }
        done
    done
    wait
fi

# Export the best model you want
if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
    echo "Export the best model you want"
    python wenet/bin/export_jit.py \
        --config $dir/train.yaml \
        --checkpoint $dir/avg_${average_num}.pt \
        --output_file $dir/final.zip
fi

