## WenetSpeech

[**Official website**](https://wenet-e2e.github.io/WenetSpeech/)
| [**Paper**](https://arxiv.org/pdf/2110.03370.pdf)

A 10000+ Hours Multi-domain Chinese Corpus for Speech Recognition

![WenetSpeech](res/wenetspeech.jpg)


## Download

Please visit the [official website](https://wenet-e2e.github.io/WenetSpeech/),
read the license, and follow the instruction to apply for the `PASSWORD` to download the data.

``` bash
echo 'PASSWORD' > SAFEBOX/password
```

### From Tecent Meeting (default)

Download WenetSpeech:

``` bash
bash utils/download_wenetspeech.sh DOWNLOAD_DIR UNTAR_DIR
```

### From ModelScope

Install `modelscope` (depends on `torch`) before downloading:

``` bash
conda create -n modelscope python=3.7
conda activate modelscope
pip install torch
pip install modelscope -f https://modelscope.oss-cn-beijing.aliyuncs.com/releases/repo.html
```

Download [WenetSpeech](https://modelscope.cn/datasets/wenet/WenetSpeech) from modelscope:

``` bash
sed -i 's/modelscope=false/modelscope=true/g' utils/download_wenetspeech.sh
bash utils/download_wenetspeech.sh DOWNLOAD_DIR UNTAR_DIR
```

## Discussion & Communication

Please scan the QR code on the left to follow our offical account of WeNet.
We created a WeChat group for better discussion and quicker response.
Please scan the personal QR code on the right, and the guy is responsible for inviting you to the chat group.

| <img src="https://github.com/robin1001/qr/blob/master/wenet.jpeg" width="250px"> | <img src="https://github.com/wenet-e2e/wenet-contributors/blob/main/wenetspeech/lvhang.jpg" width="250px"> |
| ---- | ---- |


## Benchmark

| Toolkit | Dev  | Test\_Net | Test\_Meeting | AIShell-1 |
|---------|------|:---------:|:-------------:|:---------:|
| Kaldi   | 9.07 |   12.83   |     24.72     |    5.41   |
| ESPNet  | 9.70 |    8.90   |     15.90     |    3.90   |
| WeNet   | 8.88 |    9.70   |     15.59     |    4.61   |

## Description

### Creation

All the data are collected from YouTube and Podcast. Optical character recognition (OCR) and automatic speech recognition (ASR) techniques are adopted to label each YouTube and Podcast recording, respectively. To improve the quality of the corpus, we use a novel end-to-end label error detection method to further validate and filter the data.


### Categories

In summary, WenetSpeech groups all data into 3 categories, as the following table shows:

| Set        | Hours | Confidence  | Usage                                 |
|------------|-------|-------------|---------------------------------------|
| High Label | 10005 | >=0.95      | Supervised Training                   |
| Weak Label | 2478  | [0.6, 0.95] | Semi-supervised or noise training     |
| Unlabel    | 9952  | /           | Unsupervised training or Pre-training |
| In Total   | 22435 | /           | All above                             |

### High Label Data

We classify the high label into 10 groups according to its domain, speaking style, and scenarios.

| Domain      | Youtube | Podcast | Total  |
|-------------|---------|---------|--------|
| audiobook   | 0       | 250.9   | 250.9  |
| commentary  | 112.6   | 135.7   | 248.3  |
| documentary | 386.7   | 90.5    | 477.2  |
| drama       | 4338.2  | 0       | 4338.2 |
| interview   | 324.2   | 614     | 938.2  |
| news        | 0       | 868     | 868    |
| reading     | 0       | 1110.2  | 1110.2 |
| talk        | 204     | 90.7    | 294.7  |
| variety     | 603.3   | 224.5   | 827.8  |
| others      | 144     | 507.5   | 651.5  |
| Total       | 6113    | 3892    | 10005  |

As shown in the following table, we provide 3 training subsets, namely `S`, `M` and `L` for building ASR systems on different data scales.

| Training Subsets | Confidence  | Hours |
|------------------|-------------|-------|
| L                | [0.95, 1.0] | 10005 |
| M                | 1.0         | 1000  |
| S                | 1.0         | 100   |

### Evaluation Sets

| Evaluation Sets | Hours | Source       | Description                                                                             |
|-----------------|-------|--------------|-----------------------------------------------------------------------------------------|
| DEV             | 20    | Internet     | Specially designed for some speech tools which require cross-validation set in training |
| TEST\_NET       | 23    | Internet     | Match test                                                                              |
| TEST\_MEETING   | 15    | Real meeting | Mismatch test which is a far-field, conversational, spontaneous, and meeting dataset   |

## Contributors


| <a href="http://lxie.npu-aslp.org" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/wenet-contributors/main/colleges/nwpu.png" width="250px"></a> | <a href="https://www.chumenwenwen.com" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/wenet-contributors/main/companies/chumenwenwen.png" width="250px"></a> | <a href="http://www.aishelltech.com" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/wenet-contributors/main/companies/aishelltech.png" width="250px"></a> |
| ---- | ---- | ---- |

|<a href="" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/WenetSpeech/gh-pages/assets/img/tencent.png" width="250px"></a> | <a href="" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/WenetSpeech/gh-pages/assets/img/MindSpore.png" width="250px"></a> | <a href="" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/WenetSpeech/gh-pages/assets/img/xian.png" width="250px"></a> |
| ---- | ---- | ---- |



## ACKNOWLEDGEMENTS

* WenetSpeech refers a lot of work of [GigaSpeech](https://github.com/SpeechColab/GigaSpeech), and we thank Jiayu Du and Guoguo Chen for their suggestions on this work.
* We thank Tencent Ethereal Audio Lab and Xi'an Future AI Innovation Center for providing hosting service for WenetSpeech. We also thank [MindSpore](https://www.mindspore.cn/) for the support of this work, which is a new deep learning computing framework.
* Our gratitude goes to Lianhui Zhang and Yu Mao for collecting some of the YouTube data.

