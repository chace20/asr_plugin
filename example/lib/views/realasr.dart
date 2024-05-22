import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:asr_plugin_example/config.dart';
import 'package:asr_plugin_example/models/common.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:asr_plugin/asr_plugin.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class CustomDataSource {
  late FlutterSoundRecorder _recorder;
  final StreamController<Food> _stream_ctl = StreamController<Food>();
  Duration _slice_time = const Duration(milliseconds: 40);
  CustomDataSource() {
    _recorder = FlutterSoundRecorder();
  }
  Stream<Uint8List> start() async* {
    await _recorder.openRecorder();
    await _recorder.startRecorder(
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
        toStream: _stream_ctl.sink);
    var builder = BytesBuilder();
    await for (var food in _stream_ctl.stream) {
      if (food is FoodData && food.data != null) {
        builder.add(food.data!);
        var expect_len = _slice_time.inMilliseconds * 16 * 2;
        print("stream length ${food.data!.length}");
        if (builder.length >= expect_len) {
          var res = builder.toBytes();
          builder.clear();
          int cur = 0;
          yield Uint8List.sublistView(res, cur, cur + expect_len);
          cur += expect_len;
          while (cur + expect_len <= res.length) {
            await Future.delayed(_slice_time);
            yield Uint8List.sublistView(res, cur, cur + expect_len);
            cur += expect_len;
          }
          if (cur < res.length) {
            builder.add(Uint8List.sublistView(res, cur, res.length));
          }
        }
      }
    }
  }

  void stop() async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
  }
}

class RealASRView extends StatefulWidget {
  const RealASRView({super.key});

  @override
  State<RealASRView> createState() => _RealASRViewState();
}

class _RealASRViewState extends State<RealASRView> {
  String _result = "";
  List<String> _sentences = [];
  final _config = ASRControllerConfig();
  final _statesController = MaterialStatesController();
  int _datasource_type = 0;
  ASRController? _controller;
  void Function()? _btn_onclick;

  final _datasource = [
    CommonModel(0, "内置录音"),
    CommonModel(1, "自定义录音"),
  ];

  final _convert_num_mode = [
    CommonModel(0, "全部转换为中文"),
    CommonModel(1, "智能转换为阿拉伯数字"),
    CommonModel(3, "数学相关数字转换"),
  ];

  final _filter_dirty_mode = [
    CommonModel(0, "不过滤"),
    CommonModel(1, "过滤"),
    CommonModel(2, "替换为*"),
  ];

  final _filter_modal_mode = [
    CommonModel(0, "不过滤"),
    CommonModel(1, "部分过滤"),
    CommonModel(2, "严格过滤")
  ];

  @override
  void initState() {
    super.initState();
    _btn_onclick = startRecognize;
    _config.appID = appID;
    _config.secretID = secretID;
    _config.secretKey = secretKey;
    _config.token = token;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('实时语音识别示例'),
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
                        const Expanded(child: Text('脏词过滤')),
                        DropdownButton(
                            value: _config.filter_dirty,
                            items:
                                _filter_dirty_mode.map<DropdownMenuItem>((e) {
                              return DropdownMenuItem(
                                value: e.val,
                                child: Text(e.label),
                              );
                            }).toList(),
                            onChanged: (e) {
                              setState(() {
                                _config.filter_dirty = e;
                              });
                            })
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('语气词过滤')),
                        DropdownButton(
                            value: _config.filter_modal,
                            items:
                                _filter_modal_mode.map<DropdownMenuItem>((e) {
                              return DropdownMenuItem(
                                value: e.val,
                                child: Text(e.label),
                              );
                            }).toList(),
                            onChanged: (e) {
                              setState(() {
                                _config.filter_modal = e;
                              });
                            })
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('句号过滤')),
                        Switch(
                            value: _config.filter_punc == 1,
                            onChanged: (bool val) {
                              setState(() {
                                _config.filter_punc = val ? 1 : 0;
                              });
                            }),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('数字转换')),
                        DropdownButton(
                            value: _config.convert_num_mode,
                            items: _convert_num_mode.map<DropdownMenuItem>((e) {
                              return DropdownMenuItem(
                                value: e.val,
                                child: Text(e.label),
                              );
                            }).toList(),
                            onChanged: (e) {
                              setState(() {
                                _config.convert_num_mode = e;
                              });
                            })
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('人声检测切分(VAD)')),
                        Switch(
                            value: _config.needvad == 1,
                            onChanged: (bool val) {
                              setState(() {
                                _config.needvad = val ? 1 : 0;
                              });
                            }),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('热词增强')),
                        Switch(
                            value: _config.reinforce_hotword == 1,
                            onChanged: (bool val) {
                              setState(() {
                                _config.reinforce_hotword = val ? 1 : 0;
                              });
                            }),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('噪音参数')),
                        Slider(
                            label: _config.noise_threshold.toString(),
                            value: _config.noise_threshold,
                            min: -1,
                            max: 1,
                            divisions: 21,
                            onChanged: (double val) {
                              setState(() {
                                _config.noise_threshold =
                                    (val * 10).truncate() / 10;
                              });
                            }),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('Opus 压缩')),
                        Switch(
                            value: _config.is_compress,
                            onChanged: (bool val) {
                              setState(() {
                                _config.is_compress = val;
                              });
                            }),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('数据源')),
                        DropdownButton(
                            value: _datasource_type,
                            items: _datasource.map<DropdownMenuItem>((e) {
                              return DropdownMenuItem(
                                value: e.val,
                                child: Text(e.label),
                              );
                            }).toList(),
                            onChanged: (e) {
                              setState(() {
                                _datasource_type = e;
                              });
                            })
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('静音检测')),
                        Switch(
                            value: _config.silence_detect,
                            onChanged: (bool val) {
                              setState(() {
                                _config.silence_detect = val;
                              });
                            }),
                      ],
                    ),
                    Visibility(
                        visible: _datasource_type == 0,
                        child: Row(
                          children: [
                            const Expanded(child: Text('保存录音')),
                            Switch(
                              value: _config.is_save_audio_file,
                              onChanged: (bool val) {
                                setState(() {
                                  _config.is_save_audio_file = val;
                                });
                              },
                            )
                          ],
                        )),
                    Visibility(
                        visible: _config.silence_detect,
                        child: Row(
                          children: [
                            const Expanded(child: Text('静音检测时长（毫秒）')),
                            Slider(
                                value:
                                    _config.silence_detect_duration.toDouble(),
                                label: '${_config.silence_detect_duration}',
                                max: 10000,
                                min: 3000,
                                divisions: 10000 - 3000,
                                onChanged: (e) {
                                  setState(() {
                                    _config.silence_detect_duration = e.toInt();
                                  });
                                })
                          ],
                        ))
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                    statesController: _statesController,
                    onPressed: _btn_onclick,
                    child: Text(_btn_onclick == null
                        ? "请等待"
                        : _btn_onclick == startRecognize
                            ? "开始识别"
                            : "停止识别")),
              ],
            ),
            const SizedBox(height: 10),
            const ListTile(title: Text('识别结果')),
            const SizedBox(height: 5),
            Text(_result)
          ],
        ),
      ),
    ));
  }

  startRecognize() async {
    setState(() {
      _btn_onclick = null;
      _result = "";
      _sentences = [];
    });
    CustomDataSource? datasource;
    try {
      if (_controller != null) {
        await _controller?.release();
      }
      _config.audio_file_path =
          "${(await getTemporaryDirectory()).absolute.path}/temp.wav";
      _controller = await _config.build();
      setState(() {
        _btn_onclick = stopRecognize;
      });
      Stream<ASRData> asr_stream;
      if (_datasource_type == 0) {
        asr_stream = _controller!.recognize();
      } else {
        datasource = CustomDataSource();
        asr_stream = _controller!.recognizeWithDataSource(datasource.start());
      }
      await for (final val in asr_stream) {
        switch (val.type) {
          case ASRDataType.SLICE:
          case ASRDataType.SEGMENT:
            var id = val.id!;
            var res = val.res!;
            if (id >= _sentences.length) {
              for (var i = _sentences.length; i <= id; i++) {
                _sentences.add("");
              }
            }
            _sentences[id] = res;
            setState(() {
              _result = _sentences.map((e) => e).join("");
            });
            break;
          case ASRDataType.SUCCESS:
            setState(() {
              _btn_onclick = startRecognize;
              _result = val.result!;
              _sentences = [];
            });
            break;
          case ASRDataType.NOTIFY:
            log(val.info!);
        }
      }
      setState(() {
        _btn_onclick = startRecognize;
      });
    } on ASRError catch (e) {
      setState(() {
        _btn_onclick = startRecognize;
        _result = "错误码：${e.code} \n错误信息: ${e.message} \n详细信息: ${e.resp}";
      });
    } catch (e) {
      log(e.toString());
      setState(() {
        _btn_onclick = startRecognize;
      });
    }
    if (datasource != null) {
      datasource.stop();
    }
  }

  stopRecognize() async {
    setState(() {
      _btn_onclick = null;
    });
    await _controller?.stop();
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.stop();
  }
}
