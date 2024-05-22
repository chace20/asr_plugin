import 'package:asr_plugin/onesentence_plugin.dart';
import 'package:asr_plugin_example/config.dart';
import 'package:asr_plugin_example/models/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:asr_plugin/flashfile_plugin.dart';
import 'package:flutter/services.dart';

class FlashFileASRView extends StatefulWidget {
  const FlashFileASRView({super.key});

  @override
  State<FlashFileASRView> createState() => _FlashFileASRViewState();
}

class _FlashFileASRViewState extends State<FlashFileASRView> {
  final _eng_type = [
    CommonModel(FlashFileASRParams.ENGINE_8K_ZH, "中文电话通用"),
    CommonModel(FlashFileASRParams.ENGINE_8K_EN, "英文电话通用"),
    CommonModel(FlashFileASRParams.ENGINE_16K_ZH, "中文通用"),
    CommonModel(FlashFileASRParams.ENGINE_16K_ZH_PY, "中英粤"),
    CommonModel(FlashFileASRParams.ENGINE_16K_ZH_MEDICAL, "中文医疗"),
    CommonModel(FlashFileASRParams.ENGINE_16K_EN, "英语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_YUE, "粤语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_JA, "日语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_KO, "韩语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_VI, "越南语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_MS, "马来语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_ID, "印度尼西亚语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_FIL, "菲律宾语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_TH, "泰语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_PT, "葡萄牙语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_TR, "土耳其语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_AR, "阿拉伯语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_ES, "西班牙语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_HI, "印地语"),
    CommonModel(FlashFileASRParams.ENGINE_16K_ZH_DIALECT, "多方言"),
  ];

  final _voice_format = [
    CommonModel(FlashFileASRParams.FORMAT_WAV, "wav"),
    CommonModel(FlashFileASRParams.FORMAT_PCM, "pcm"),
    CommonModel(FlashFileASRParams.FORMAT_OGG_OPUS, "ogg-opus"),
    CommonModel(FlashFileASRParams.FORMAT_SPEEX, "speex"),
    CommonModel(FlashFileASRParams.FORMAT_SILK, "silk"),
    CommonModel(FlashFileASRParams.FORMAT_MP3, "mp3"),
    CommonModel(FlashFileASRParams.FORMAT_M4A, "m4a"),
    CommonModel(FlashFileASRParams.FORMAT_AAC, "aac"),
    CommonModel(FlashFileASRParams.FORMAT_AMR, "amr"),
  ];

  final _reinforce_hotword = [
    CommonModel(-1, "-"),
    CommonModel(FlashFileASRParams.REINFORCE_HOTWORD_MODE_0, "关闭热词增强功能"),
    CommonModel(FlashFileASRParams.REINFORCE_HOTWORD_MODE_1, "开启热词增强功能")
  ];

  final _filter_dirty = [
    CommonModel(-1, "-"),
    CommonModel(FlashFileASRParams.FILTER_DIRTY_MODE_0, "不过滤脏词"),
    CommonModel(FlashFileASRParams.FILTER_DIRTY_MODE_1, "过滤脏词"),
    CommonModel(FlashFileASRParams.FILTER_DIRTY_MODE_2, "将脏词替换为 * ")
  ];
  final _filter_modal = [
    CommonModel(-1, "-"),
    CommonModel(FlashFileASRParams.FILTER_MODAL_MODE_0, "不过滤语气词"),
    CommonModel(FlashFileASRParams.FILTER_MODAL_MODE_1, "部分过滤"),
    CommonModel(FlashFileASRParams.FILTER_MODAL_MODE_2, "严格过滤")
  ];
  final _filter_punc = [
    CommonModel(-1, "-"),
    CommonModel(FlashFileASRParams.FILTER_PUNC_MODE_0, "不过滤标点符号"),
    CommonModel(FlashFileASRParams.FILTER_PUNC_MODE_1, "过滤句末标点"),
    CommonModel(FlashFileASRParams.FILTER_PUNC_MODE_2, "过滤所有标点")
  ];
  final _convert_num_mode = [
    CommonModel(-1, "-"),
    CommonModel(FlashFileASRParams.CONVERT_NUM_NODE_0, "不转换，直接输出中文数字"),
    CommonModel(FlashFileASRParams.CONVERT_NUM_NODE_1, "根据场景智能转换为阿拉伯数字")
  ];
  final _word_info = [
    CommonModel(-1, "-"),
    CommonModel(FlashFileASRParams.WORD_INFO_MODE_0, "不显示"),
    CommonModel(FlashFileASRParams.WORD_INFO_MODE_1, "显示，不包含标点时间戳"),
    CommonModel(FlashFileASRParams.WORD_INFO_MODE_2, "显示，包含标点时间戳"),
  ];
  final _first_channel_only = [
    CommonModel(-1, "-"),
    CommonModel(FlashFileASRParams.FIRST_CHANNEL_ONLY_MODE_0, "识别所有声道"),
    CommonModel(FlashFileASRParams.FIRST_CHANNEL_ONLY_MODE_1, "识别首个声道"),
  ];
  final _speaker_diarization = [
    CommonModel(-1, "-"),
    CommonModel(FlashFileASRParams.SPEAKER_DIARIZATION_MODE_0, "不开启"),
    CommonModel(FlashFileASRParams.SPEAKER_DIARIZATION_MODE_1, "开启"),
  ];

  String _result = "";
  void Function()? _btn_onclick;
  final FlashFileASRParams _params = FlashFileASRParams();
  final FlashFileASRController _controller = FlashFileASRController();

  @override
  void initState() {
    super.initState();
    _btn_onclick = _start_recognize;
  }

  void _start_recognize() async {
    _btn_onclick = null;
    _result = "";
    setState(() {});
    try {
      _params.appid = appID;
      _params.secretkey = secretKey;
      _params.secretid = secretID;
      _params.token = token;
      // _params.sentence_max_length = 6;
      _params.data =
          Uint8List.view((await rootBundle.load("assets/30s.wav")).buffer);
      var ret = (await _controller.recognize(_params));
      _result = ret.response_body;
    } catch (e) {
      _result = e.toString();
    }
    _btn_onclick = _start_recognize;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('录音文件识别极速版示例'),
              leading: BackButton(onPressed: () {
                Navigator.pop(context);
              }),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpansionTile(
                      title: const Text('设置'),
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(child: Text('引擎类型')),
                                DropdownButton(
                                  value: _params.engine_type,
                                  items: _eng_type
                                      .map<DropdownMenuItem>((e) =>
                                          DropdownMenuItem(
                                              value: e.val,
                                              child: Text(e.label)))
                                      .toList(),
                                  onChanged: (e) => setState(() {
                                    _params.engine_type = e;
                                  }),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('音频格式')),
                                DropdownButton(
                                  value: _params.voice_format,
                                  items: _voice_format
                                      .map<DropdownMenuItem>((e) =>
                                          DropdownMenuItem(
                                              value: e.val,
                                              child: Text(e.label)))
                                      .toList(),
                                  onChanged: (e) => setState(() {
                                    _params.voice_format = e;
                                  }),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('说话人分离')),
                                DropdownButton(
                                    value: (() {
                                      if (_params.speaker_diarization != null) {
                                        return _params.speaker_diarization;
                                      } else {
                                        return -1;
                                      }
                                    })(),
                                    items: _speaker_diarization
                                        .map((e) => DropdownMenuItem<int>(
                                            value: e.val, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) {
                                      setState(() {
                                        if (e == -1) {
                                          _params.speaker_diarization = null;
                                        } else {
                                          _params.speaker_diarization = e;
                                        }
                                      });
                                    })
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('热词增强')),
                                DropdownButton(
                                    value: (() {
                                      if (_params.reinforce_hotword != null) {
                                        return _params.reinforce_hotword;
                                      } else {
                                        return -1;
                                      }
                                    })(),
                                    items: _reinforce_hotword
                                        .map((e) => DropdownMenuItem<int>(
                                            value: e.val, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) {
                                      setState(() {
                                        if (e == -1) {
                                          _params.reinforce_hotword = null;
                                        } else {
                                          _params.reinforce_hotword = e;
                                        }
                                      });
                                    })
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('脏词过滤')),
                                DropdownButton(
                                    value: (() {
                                      if (_params.filter_dirty != null) {
                                        return _params.filter_dirty;
                                      } else {
                                        return -1;
                                      }
                                    })(),
                                    items: _filter_dirty
                                        .map((e) => DropdownMenuItem<int>(
                                            value: e.val, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) {
                                      setState(() {
                                        if (e == -1) {
                                          _params.filter_dirty = null;
                                        } else {
                                          _params.filter_dirty = e;
                                        }
                                      });
                                    })
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('语气词过滤')),
                                DropdownButton(
                                    value: (() {
                                      if (_params.filter_modal != null) {
                                        return _params.filter_modal;
                                      } else {
                                        return -1;
                                      }
                                    })(),
                                    items: _filter_modal
                                        .map((e) => DropdownMenuItem<int>(
                                            value: e.val, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) {
                                      setState(() {
                                        if (e == -1) {
                                          _params.filter_modal = null;
                                        } else {
                                          _params.filter_modal = e;
                                        }
                                      });
                                    })
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('标点符号过滤')),
                                DropdownButton(
                                    value: (() {
                                      if (_params.filter_punc != null) {
                                        return _params.filter_punc;
                                      } else {
                                        return -1;
                                      }
                                    })(),
                                    items: _filter_punc
                                        .map((e) => DropdownMenuItem<int>(
                                            value: e.val, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) {
                                      setState(() {
                                        if (e == -1) {
                                          _params.filter_punc = null;
                                        } else {
                                          _params.filter_punc = e;
                                        }
                                      });
                                    })
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('数字转换')),
                                DropdownButton(
                                    value: (() {
                                      if (_params.convert_num_mode != null) {
                                        return _params.convert_num_mode;
                                      } else {
                                        return -1;
                                      }
                                    })(),
                                    items: _convert_num_mode
                                        .map((e) => DropdownMenuItem<int>(
                                            value: e.val, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) {
                                      setState(() {
                                        if (e == -1) {
                                          _params.convert_num_mode = null;
                                        } else {
                                          _params.convert_num_mode = e;
                                        }
                                      });
                                    })
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('词级时间戳')),
                                DropdownButton(
                                    value: (() {
                                      if (_params.word_info != null) {
                                        return _params.word_info;
                                      } else {
                                        return -1;
                                      }
                                    })(),
                                    items: _word_info
                                        .map((e) => DropdownMenuItem<int>(
                                            value: e.val, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) {
                                      setState(() {
                                        if (e == -1) {
                                          _params.word_info = null;
                                        } else {
                                          _params.word_info = e;
                                        }
                                      });
                                    })
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text('识别首个声道')),
                                DropdownButton(
                                    value: (() {
                                      if (_params.first_channel_only != null) {
                                        return _params.first_channel_only;
                                      } else {
                                        return -1;
                                      }
                                    })(),
                                    items: _first_channel_only
                                        .map((e) => DropdownMenuItem<int>(
                                            value: e.val, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) {
                                      setState(() {
                                        if (e == -1) {
                                          _params.first_channel_only = null;
                                        } else {
                                          _params.first_channel_only = e;
                                        }
                                      });
                                    })
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                            onPressed: _btn_onclick,
                            child: Text(_btn_onclick == null ? "识别中" : "开始识别")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const ListTile(title: Text('识别结果')),
                    const SizedBox(height: 5),
                    Text(_result)
                  ],
                ))));
  }
}
