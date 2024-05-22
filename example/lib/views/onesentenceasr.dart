import 'dart:async';
import 'dart:io';

import 'package:asr_plugin/onesentence_plugin.dart';
import 'package:asr_plugin_example/config.dart';
import 'package:asr_plugin_example/models/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class OneSentenceASRView extends StatefulWidget {
  const OneSentenceASRView({super.key});

  @override
  State<OneSentenceASRView> createState() => _OneSentenceASRViewState();
}

class _OneSentenceASRViewState extends State<OneSentenceASRView> {
  final _eng_service_type = [
    CommonModel(OneSentenceASRParams.ENGINE_8K_ZH, "中文电话通用"),
    CommonModel(OneSentenceASRParams.ENGINE_8K_EN, "英文电话通用"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_ZH, "中文通用"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_ZH_PY, "中英粤"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_ZH_MEDICAL, "中文医疗"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_EN, "英语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_YUE, "粤语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_JA, "日语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_KO, "韩语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_VI, "越南语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_MS, "马来语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_ID, "印度尼西亚语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_FIL, "菲律宾语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_TH, "泰语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_PT, "葡萄牙语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_TR, "土耳其语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_AR, "阿拉伯语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_ES, "西班牙语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_HI, "印地语"),
    CommonModel(OneSentenceASRParams.ENGINE_16K_ZH_DIALECT, "多方言"),
  ];

  final _voice_format = [
    CommonModel(OneSentenceASRParams.FORMAT_WAV, "wav"),
    CommonModel(OneSentenceASRParams.FORMAT_PCM, "pcm"),
    CommonModel(OneSentenceASRParams.FORMAT_OGG_OPUS, "ogg-opus"),
    CommonModel(OneSentenceASRParams.FORMAT_SPEEX, "speex"),
    CommonModel(OneSentenceASRParams.FORMAT_SILK, "silk"),
    CommonModel(OneSentenceASRParams.FORMAT_MP3, "mp3"),
    CommonModel(OneSentenceASRParams.FORMAT_M4A, "m4a"),
    CommonModel(OneSentenceASRParams.FORMAT_AAC, "aac"),
    CommonModel(OneSentenceASRParams.FORMAT_AMR, "amr"),
  ];

  final _word_info = [
    CommonModel(-1, "-"),
    CommonModel(OneSentenceASRParams.WORD_INFO_MODE_0, "不显示"),
    CommonModel(OneSentenceASRParams.WORD_INFO_MODE_1, "显示，不包含标点时间戳"),
    CommonModel(OneSentenceASRParams.WORD_INFO_MODE_2, "显示，包含标点时间戳"),
  ];

  final _filter_dirty = [
    CommonModel(-1, "-"),
    CommonModel(OneSentenceASRParams.FILTER_DIRTY_MODE_0, "不过滤脏词"),
    CommonModel(OneSentenceASRParams.FILTER_DIRTY_MODE_1, "过滤脏词"),
    CommonModel(OneSentenceASRParams.FILTER_DIRTY_MODE_2, "将脏词替换为 * ")
  ];
  final _filter_modal = [
    CommonModel(-1, "-"),
    CommonModel(OneSentenceASRParams.FILTER_MODAL_MODE_0, "不过滤语气词"),
    CommonModel(OneSentenceASRParams.FILTER_MODAL_MODE_1, "部分过滤"),
    CommonModel(OneSentenceASRParams.FILTER_MODAL_MODE_2, "严格过滤")
  ];
  final _filter_punc = [
    CommonModel(-1, "-"),
    CommonModel(OneSentenceASRParams.FILTER_PUNC_MODE_0, "不过滤标点符号"),
    CommonModel(OneSentenceASRParams.FILTER_PUNC_MODE_1, "过滤句末标点"),
    CommonModel(OneSentenceASRParams.FILTER_PUNC_MODE_2, "过滤所有标点")
  ];
  final _convert_num_mode = [
    CommonModel(-1, "-"),
    CommonModel(OneSentenceASRParams.CONVERT_NUM_NODE_0, "不转换，直接输出中文数字"),
    CommonModel(OneSentenceASRParams.CONVERT_NUM_NODE_1, "根据场景智能转换为阿拉伯数字")
  ];
  final _reinforce_hotword = [
    CommonModel(-1, "-"),
    CommonModel(OneSentenceASRParams.REINFORCE_HOTWORD_MODE_0, "关闭热词增强功能"),
    CommonModel(OneSentenceASRParams.REINFORCE_HOTWORD_MODE_1, "开启热词增强功能")
  ];

  var _result = "";
  var _btn_text = "开始识别";
  void Function()? _btn_onclick;
  final _params = OneSentenceASRParams();
  final _controller = OneSentenceASRController();
  int _datasource = 0;
  var _recorder = FlutterSoundRecorder();
  var _stream_ctl = StreamController<Food>();

  @override
  void initState() {
    super.initState();
    _btn_onclick = _onclick;
  }

  @override
  dispose() async {
    super.dispose();
    await _stop_record();
  }

  Future<void> _onclick() async {
    if (_datasource == 2) {
      _start_record();
    } else {
      if (_datasource == 0) {
        _params.binary_data =
            Uint8List.view((await rootBundle.load("assets/30s.wav")).buffer);
      }
      if (_datasource == 1) {
        _params.url =
            "https://sdk-1300466766.cos.ap-shanghai.myqcloud.com/audios/test1.mp3";
      }
      setState(() {
        _btn_onclick = null;
        _btn_text = "识别中";
        _result = "";
      });
      () async {
        await _start_recognize();
        setState(() {
          _btn_onclick = _onclick;
          _btn_text = "开始识别";
        });
      }();
    }
  }

  Future<void> _start_recognize() async {
    try {
      _params.secretKey = secretKey;
      _params.secretID = secretID;
      _params.token = token;
      _result = (await _controller.recognize(_params)).response_body;
    } catch (e) {
      _result = e.toString();
    }
    setState(() {});
  }

  Future<void> _stop_record() async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    _stream_ctl.close();
  }

  Future<void> _start_record() async {
    setState(() {
      _btn_onclick = null;
      _btn_text = "停止录音";
    });
    try {
      _stream_ctl = StreamController<Food>();
      var status = await Permission.microphone.status;
      if (await Permission.microphone.isDenied) {
        status = await Permission.microphone.request();
      }
      if (status.isDenied || status.isPermanentlyDenied) {
        await openAppSettings();
        setState(() {
          _result = "未获取录音权限,请前往设置开启";
          _btn_text = "开始录音";
          _btn_onclick = _onclick;
        });
        return;
      }
      await _recorder.openRecorder();
      await _recorder.startRecorder(
          codec: Codec.pcm16,
          sampleRate: 16000,
          numChannels: 1,
          toStream: _stream_ctl.sink);
      _read_data();
    } catch (e) {
      setState(() {
        _result = e.toString();
        _btn_text = "开始录音";
        _btn_onclick = _onclick;
      });
    }
  }

  Future<void> _read_data() async {
    setState(() {
      _btn_onclick = _stop_record;
      _btn_text = "停止录音";
      _result = "";
    });
    var builder = BytesBuilder();
    await for (var food in _stream_ctl.stream) {
      if (food is FoodData && food.data != null) {
        builder.add(food.data!);
      }
    }
    _params.binary_data = builder.toBytes();
    _params.voice_format = OneSentenceASRParams.FORMAT_PCM;
    await _start_recognize();
    setState(() {
      _btn_onclick = _onclick;
      _btn_text = "开始识别";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('一句话识别示例'),
        leading: BackButton(onPressed: () {
          Navigator.pop(context);
        }),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExpansionTile(
            title: const Text("设置"),
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('数据源')),
                      DropdownButton<int>(
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text("本地文件"),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text("URL"),
                            ),
                            DropdownMenuItem(value: 2, child: Text("录音")),
                          ],
                          value: _datasource,
                          onChanged: (e) {
                            setState(() {
                              if (e == 0) {
                                _params.voice_format =
                                    OneSentenceASRParams.FORMAT_WAV;
                              } else if (e == 1) {
                                _params.voice_format =
                                    OneSentenceASRParams.FORMAT_MP3;
                              }
                              _datasource = e!;
                            });
                          })
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('引擎类型')),
                      DropdownButton(
                        value: _params.eng_serice_type,
                        items: _eng_service_type
                            .map<DropdownMenuItem>((e) => DropdownMenuItem(
                                value: e.val, child: Text(e.label)))
                            .toList(),
                        onChanged: (e) => setState(() {
                          _params.eng_serice_type = e;
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
                            .map<DropdownMenuItem>((e) => DropdownMenuItem(
                                value: e.val, child: Text(e.label)))
                            .toList(),
                        onChanged: (e) => setState(() {
                          _params.voice_format = e;
                        }),
                      )
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
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              ElevatedButton(onPressed: _btn_onclick, child: Text(_btn_text)),
            ],
          ),
          const SizedBox(height: 10),
          const ListTile(title: Text('识别结果')),
          const SizedBox(height: 5),
          Text(_result)
        ]),
      ),
    ));
  }
}
