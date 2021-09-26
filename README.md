## WenetSpeech
A 10000+ Hours Multi-domain Chinese Corpus for Speech Recognition

![WenetSpeech](res/wenetspeech.jpg)


## Download

Please visit the [official website](https://wenet-e2e.github.io/WenetSpeech/),
read the license, and follow the instruction to download the data.


## Benchmark

| Toolkit | Model               | test\_net | test\_meeting |
|---------|---------------------|-----------|---------------|
| Kaldi   | Chain Model         |           |               |
| ESPnet  | Joint CTC/Conformer |           |               |
| WeNet   | Joint CTC/Conformer |           |               |


## Description

### Creation

First, we collect all the data from YouTube and Podcast; Then, OCR is used to label YouTube data, auto trancrition is used to label Podcast data; Finally, a novel end-to-end label error detection method is used to further validate and filter the data.


### Categories

In summary, WenetSpeech groups all data into 3 categories, as the following table shows:

| Set        | Hours | Confidence  | Usage                                 |
|------------|-------|-------------|---------------------------------------|
| High Label | 10005 | >=0.95      | Supervised Training                   |
| Weak Label | 2478  | [0.6, 0.95] | Semi-supervised or noise training     |
| Unlabel    | 9952  | /           | Unsupervised training or Pre-training |
| In Total   | 22435 | /           | All above                             |

### High Label Data

All of the data is from Youtube and Podcast, and we tag all the data with its source and domain.
We classify the data into 10 groups according to its domain,speaking style, or scenarios.

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

We provide 3 training subsets, namely `S`, `M` and `L`. Subsets `S`, `M` are sampled from all the high label data which has the oracle confidence 1.0

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
| TEST\_MEETING   | 15    | Real meeting | Mismatch test which is far-field, conversational, and spontaneous meeting speech        |

## Contributors

| <a href="http://lxie.npu-aslp.org" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/wenet-contributors/main/colleges/nwpu.png" width="250px"></a> | <a href="https://www.chumenwenwen.com" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/wenet-contributors/main/companies/chumenwenwen.png" width="250px"></a> | <a href="http://www.aishelltech.com" target="_blank"><img src="https://raw.githubusercontent.com/wenet-e2e/wenet-contributors/main/companies/aishelltech.png" width="250px"></a> |
| ---- | ---- | ---- |


## ACKNOWLEDGEMENTS

1. WenetSpeech referred a lot of work of [GigaSpeech](https://github.com/SpeechColab/GigaSpeech),
   including metadata design, license design, data encryption, downloading pipeline, and so on.
   The authors would like to thank Jiayu Du and Guoguo Chen for their suggestions on this work.
2. The authors would like to thank my college Lianhui Zhang, Yu Mao for collecting some of the YouTube data.

