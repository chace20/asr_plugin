import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class _Inner {
  int _id = 1;
  Map<int, dynamic> _instance_mgr = {};
  MethodChannel methodChannel = const MethodChannel('asr_plugin');
  static _Inner _instance = _Inner();
  static _Inner get instance {
    return _instance;
  }

  _Inner() {
    methodChannel.setMethodCallHandler((call) async {
      int id = call.arguments["id"];
      var obj = _instance_mgr[id];
      if (obj == null) {
        return null;
      }
      if (call.method == "onStartRecord") {
        obj.onStartRecord();
      } else if (call.method == "onStopRecord") {
        obj.onStopRecord();
      } else if (call.method == "onSliceSuccess") {
        int sen_id = call.arguments["sentence_id"];
        String sen_text = call.arguments["sentence_text"];
        obj.onSliceSuccess(sen_id, sen_text);
      } else if (call.method == "onSegmentSuccess") {
        int sen_id = call.arguments["sentence_id"];
        String sen_text = call.arguments["sentence_text"];
        obj.onSegmentSuccess(sen_id, sen_text);
      } else if (call.method == "onSuccess") {
        String text = call.arguments["text"];
        obj.onSuccess(text);
      } else if (call.method == "onFailed") {
        int code = call.arguments["code"];
        String msg = call.arguments["message"];
        String resp = call.arguments["response"];
        obj.onFailed(code, msg, resp);
      } else if (call.method == "read") {
        int size = call.arguments["size"];
        return obj.read(size);
      } else if (call.method == "onAudioFile") {
        int code = call.arguments["code"];
        String msg = call.arguments["message"];
        obj.onAudioFile(code, msg);
      }
    });
  }

  int addInstance(dynamic obj) {
    while (_instance_mgr.containsKey(_id)) {
      _id = (_id + 1).toUnsigned(32);
    }
    _instance_mgr.addEntries({_id: obj}.entries);
    return _id;
  }

  void removeInstance(int id) {
    _instance_mgr.remove(id);
  }
}

class _ASRControllerObserver {
  StreamController<ASRData> _stream_ctl;

  _ASRControllerObserver(this._stream_ctl);

  onFailed(int code, String msg, String resp) {
    _stream_ctl.addError(ASRError(code, msg, resp));
  }

  onSegmentSuccess(int id, String res) {
    var data = ASRData(ASRDataType.SEGMENT);
    data.res = res;
    data.id = id;
    _stream_ctl.add(data);
  }

  onSliceSuccess(int id, String res) {
    var data = ASRData(ASRDataType.SLICE);
    data.res = res;
    data.id = id;
    _stream_ctl.add(data);
  }

  onStartRecord() {}

  onStopRecord() {
    _stream_ctl.close();
  }

  onSuccess(String result) {
    var data = ASRData(ASRDataType.SUCCESS);
    data.result = result;
    _stream_ctl.add(data);
  }

  onAudioFile(int code, String msg) {
    var data = ASRData(ASRDataType.NOTIFY);
    data.info = jsonEncode({
      "type": "onAudioFile",
      "code": code,
      "message": msg,
    });
    _stream_ctl.add(data);
  }
}

class _ASRDataSource {
  Stream<Uint8List> _source;
  Completer<Uint8List>? _completer;

  _ASRDataSource(this._source) {
    _source.listen((event) {
      if (_completer != null) {
        if (!_completer!.isCompleted) {
          _completer!.complete(event);
        }
      }
    });
  }

  Future<Uint8List> read(int size) async {
    _completer = Completer();
    return _completer!.future;
  }
}

enum ASRDataType {
  SLICE,
  SEGMENT,
  SUCCESS,
  NOTIFY,
}

class ASRData {
  ASRDataType type; //数据类型
  int? id; //句子的id
  String? res; //数据类型为SLICE和SEGMENT时返回部分识别结果
  String? result; // 数据类型SUCCESS时返回所有识别结果
  String? info; //数据类型为NOTIFY时携带的信息
  ASRData(this.type);
}

class ASRError implements Exception {
  int code; //错误码 iOS参考QCloudRealTimeClientErrCode Android参考ClientException
  String message; //错误消息
  String? resp; //服务端返回的原始数据
  ASRError(this.code, this.message, this.resp);
}

class ASRControllerConfig {
  int appID = 0; // 腾讯云 appID
  int projectID = 0; //腾讯云 projectID
  String secretID = ""; //腾讯云 secretID
  String secretKey = ""; // 腾讯云 secretKey
  String? token = null; // 腾讯云 token

  String engine_model_type = "16k_zh"; //设置引擎，不设置默认16k_zh
  int filter_dirty = 0; //是否过滤脏词，具体的取值见API文档的filter_dirty参数
  int filter_modal = 0; //过滤语气词具体的取值见API文档的filter_modal参数
  int filter_punc = 0; //过滤句末的句号具体的取值见API文档的filter_punc参数
  int convert_num_mode = 1; //是否进行阿拉伯数字智能转换。具体的取值见API文档的convert_num_mode参数
  String hotword_id = ""; //热词id。具体的取值见API文档的hotword_id参数
  String customization_id = ""; //自学习模型id,详情见API文档
  int? vad_silence_time = 1000; //语音断句检测阈值,详情见API文档
  int needvad = 1; //人声切分,详情见API文档
  int word_info = 0; //是否显示词级别时间戳,详情见API文档
  int reinforce_hotword = 0; //热词增强功能,详情见API文档
  double noise_threshold = 0; //噪音参数阈值,详情见API文档

  bool is_compress = true; //是否开启音频压缩,开启后使用opus压缩传输数据
  bool silence_detect = false; //静音检测功能,开启后检测到静音会停止识别
  int silence_detect_duration = 5000; //静音检测时长,开启静音检测功能后生效
  bool is_save_audio_file =
      false; //是否保存音频,仅对内置录音生效,格式为s16le,16000Hz,mono的pcm,开启后会通过NOTIFY类型的ASRData返回到上层,其中ASRData中info为以下的JSON格式{"type":"onAudioFile, "code": 0, "message": "audio file path"}
  String audio_file_path = ""; //is_save_audio_file为true时,会将音频保存在指定位置

  ASRControllerConfig clone() {
    var obj = ASRControllerConfig();
    return obj;
  }

  Future<ASRController> build() async {
    final id =
        await _Inner.instance.methodChannel.invokeMethod("ASRController.new", {
      "appID": appID,
      "projectID": projectID,
      "secretID": secretID,
      "secretKey": secretKey,
      "token": token,
      "engine_model_type": engine_model_type,
      "filter_dirty": filter_dirty,
      "filter_modal": filter_modal,
      "filter_punc": filter_punc,
      "convert_num_mode": convert_num_mode,
      "hotword_id": hotword_id,
      "customization_id": customization_id,
      "vad_silence_time": vad_silence_time,
      "needvad": needvad,
      "word_info": word_info,
      "reinforce_hotword": reinforce_hotword,
      "is_compress": is_compress,
      "silence_detect": silence_detect,
      "silence_detect_duration": silence_detect_duration,
      "noise_threshold": noise_threshold,
      "is_save_audio_file": is_save_audio_file,
      "audio_file_path": audio_file_path,
    });
    if (id == null) {
      throw Exception("");
    }
    return ASRController(id);
  }
}

class ASRController {
  int _id;

  ASRController(this._id);

  Stream<ASRData> recognize() async* {
    yield* recognizeWithDataSource(null);
  }

  Stream<ASRData> recognizeWithDataSource(Stream<Uint8List>? source) async* {
    var stream_ctl = StreamController<ASRData>();
    var observer_id =
        _Inner.instance.addInstance(_ASRControllerObserver(stream_ctl));
    await _Inner.instance.methodChannel
        .invokeMethod("ASRController.setObserver", {
      "id": _id,
      "observer_id": observer_id,
    });
    var datasource_id = 0;
    if (source != null) {
      datasource_id = _Inner.instance.addInstance(_ASRDataSource(source));
      await _Inner.instance.methodChannel
          .invokeMethod("ASRController.setDataSource", {
        "id": _id,
        "datasource_id": datasource_id,
      });
    }
    await _Inner.instance.methodChannel
        .invokeMethod("ASRController.start", {"id": _id});
    await for (final val in stream_ctl.stream) {
      yield val;
    }
    if (source != null) {
      _Inner.instance.removeInstance(datasource_id);
    }
    _Inner.instance.removeInstance(observer_id);
  }

  stop() async {
    await _Inner.instance.methodChannel
        .invokeMethod("ASRController.stop", {"id": _id});
  }

  release() async {
    await _Inner.instance.methodChannel
        .invokeMethod("ASRController.release", {"id": _id});
  }
}
