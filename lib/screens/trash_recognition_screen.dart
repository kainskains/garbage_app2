// lib/screens/trash_recognition_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:garbage_app/services/trash_recognition_service.dart';

class TrashRecognitionScreen extends StatefulWidget {
  const TrashRecognitionScreen({super.key});

  @override
  State<TrashRecognitionScreen> createState() => _TrashRecognitionScreenState();
}

class _TrashRecognitionScreenState extends State<TrashRecognitionScreen> {
  File? _imageFile;
  String _predictionResult = '画像をタップして分類を開始';
  String _predictedLabel = '不明';

  @override
  void initState() {
    super.initState();
    // アプリ起動時にモデルをロードする
    TrashRecognitionService.loadModel();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await TrashRecognitionService.pickImage(source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _predictionResult = '分類中...';
        });
        await _runInference(_imageFile!);
      }
    } catch (e) {
      debugPrint('画像選択エラー: $e');
      setState(() {
        _predictionResult = 'エラー: 画像の選択に失敗しました。';
      });
    }
  }

  Future<void> _runInference(File imageFile) async {
    final result = await TrashRecognitionService.recognizeTrash(imageFile);
    if (result != null) {
      setState(() {
        _predictedLabel = result.label;
        _predictionResult = '分類結果: ${result.label} (信頼度: ${result.confidencePercentage})';
      });
    } else {
      setState(() {
        _predictedLabel = '不明';
        _predictionResult = '分類結果を特定できませんでした。';
      });
    }
  }

  Future<void> _showImageSourceDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('画像の選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリー'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラ'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openGomisukuPage() async {
    if (_predictedLabel == '不明') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分類結果が取得できていません。画像を分類してください。')),
      );
      return;
    }
    try {
      await TrashRecognitionService.openGomisukuPage(_predictedLabel);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ゴミサクページを開けませんでした。エラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GestureDetector(
                onTap: () => _showImageSourceDialog(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  height: 300,
                  alignment: Alignment.center,
                  child: _imageFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_roll_outlined,
                        size: 80,
                        color: Colors.green.withOpacity(0.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '画像をタップして選択または撮影',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '(ギャラリー/カメラ)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  _predictionResult,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('ギャラリーから選択'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('カメラで撮影'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _openGomisukuPage,
                  icon: const Icon(Icons.search),
                  label: const Text('ゴミサクで検索'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}