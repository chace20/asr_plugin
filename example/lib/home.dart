import 'package:asr_plugin_example/views/flashfileasr.dart';
import 'package:asr_plugin_example/views/onesentenceasr.dart';
import 'package:asr_plugin_example/views/realasr.dart';
import 'package:asr_plugin_example/views/settings.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(title: const Text('示例')),
      floatingActionButton: MaterialButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return const SettingsView();
          }));
        },
        color: Colors.blue,
        padding: const EdgeInsets.all(10),
        shape: const CircleBorder(),
        child: const Icon(Icons.settings, size: 30, color: Colors.white),
      ),
      body: Column(
        children: [
          MaterialButton(
              color: Colors.blue,
              textColor: Colors.white,
              minWidth: double.infinity,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const RealASRView();
                }));
              },
              child: const Text("实时语音识别")),
          MaterialButton(
              color: Colors.blue,
              textColor: Colors.white,
              minWidth: double.infinity,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const OneSentenceASRView();
                }));
              },
              child: const Text("一句话识别")),
          MaterialButton(
              color: Colors.blue,
              textColor: Colors.white,
              minWidth: double.infinity,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const FlashFileASRView();
                }));
              },
              child: const Text("录音文件识别极速版"))
        ],
      ),
    ));
  }
}
