import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 追加
import 'package:garbage_app/services/trash_recognition_service.dart'; // 追加

class TrashRecognitionScreen extends StatefulWidget {
  const TrashRecognitionScreen({super.key});

  @override
  State<TrashRecognitionScreen> createState() => _TrashRecognitionScreenState();
}

class _TrashRecognitionScreenState extends State<TrashRecognitionScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Interpreter? _interpreter;
  List<String>? _labels;
  String _predictionResult = '画像をタップして分類を開始';

  final int _inputSize = 128;
  final int _inputChannels = 3;

  TensorType _expectedInputType = TensorType.float32;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/garbage_model_2.tflite');
      print('Model loaded successfully.');

      String labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      print('Labels loaded: $_labels');

      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      print('Input Tensors:');
      for (var tensor in inputTensors) {
        print('  Name: ${tensor.name}, Shape: ${tensor.shape}, Type: ${tensor.type}');
        if (tensor.type == TensorType.float32 || tensor.type == TensorType.uint8) {
          _expectedInputType = tensor.type;
        }
      }
      print('Output Tensors:');
      for (var tensor in outputTensors) {
        print('  Name: ${tensor.name}, Shape: ${tensor.shape}, Type: ${tensor.type}');
      }

      setState(() {
        _predictionResult = 'ゴミの画像を選択してください。';
      });

    } catch (e) {
      print('Failed to load model or labels: $e');
      setState(() {
        _predictionResult = 'エラー: モデルのロードに失敗しました。';
      });
    }
  }

  Uint8List _preProcessImage(File imageFile) {
    final img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());

    if (originalImage == null) {
      throw Exception('Failed to decode image.');
    }

    final img.Image resizedImage = img.copyResize(
      originalImage,
      width: _inputSize,
      height: _inputSize,
    );

    final inputBytes = Uint8List(_inputSize * _inputSize * _inputChannels);
    int pixelIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputBytes[pixelIndex++] = pixel.r.toInt();
        inputBytes[pixelIndex++] = pixel.g.toInt();
        inputBytes[pixelIndex++] = pixel.b.toInt();
      }
    }
    return inputBytes;
  }

  Future<void> _runInference(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      setState(() {
        _predictionResult = 'エラー: モデルがロードされていません。';
      });
      return;
    }

    setState(() {
      _predictionResult = '分類中...';
    });

    try {
      final Uint8List inputImageBytes = _preProcessImage(imageFile);

      List<List<List<List<double>>>> inputListFloat = [];
      List<List<List<List<int>>>> inputListUint8 = [];

      if (_expectedInputType == TensorType.float32) {
        List<List<List<double>>> imagePixels = [];
        int byteIndex = 0;
        for (int y = 0; y < _inputSize; y++) {
          List<List<double>> rowPixels = [];
          for (int x = 0; x < _inputSize; x++) {
            rowPixels.add([
              inputImageBytes[byteIndex++] / 255.0,
              inputImageBytes[byteIndex++] / 255.0,
              inputImageBytes[byteIndex++] / 255.0,
            ]);
          }
          imagePixels.add(rowPixels);
        }
        inputListFloat.add(imagePixels);
      } else if (_expectedInputType == TensorType.uint8) {
        List<List<List<int>>> imagePixels = [];
        int byteIndex = 0;
        for (int y = 0; y < _inputSize; y++) {
          List<List<int>> rowPixels = [];
          for (int x = 0; x < _inputSize; x++) {
            rowPixels.add([
              inputImageBytes[byteIndex++],
              inputImageBytes[byteIndex++],
              inputImageBytes[byteIndex++],
            ]);
          }
          imagePixels.add(rowPixels);
        }
        inputListUint8.add(imagePixels);
      } else {
        throw Exception('Unsupported input type for inference: $_expectedInputType');
      }

      final outputTensorShape = _interpreter!.getOutputTensors().first.shape;
      var output = List.filled(
          outputTensorShape[0], List<double>.filled(outputTensorShape[1], 0.0));

      if (_expectedInputType == TensorType.float32) {
        _interpreter!.run(inputListFloat, output);
      } else if (_expectedInputType == TensorType.uint8) {
        _interpreter!.run(inputListUint8, output);
      }

      final List<double> rawOutput = List<double>.from(output[0]);
      final List<double> probabilities = _softmax(rawOutput);

      double maxProbability = 0.0;
      int predictedIndex = -1;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          predictedIndex = i;
        }
      }

      String resultText;
      String predictedLabel = '不明';
      if (predictedIndex != -1 && _labels != null && predictedIndex < _labels!.length) {
        predictedLabel = _labels![predictedIndex];
        resultText = '分類結果: $predictedLabel ';
      } else {
        resultText = '分類結果を特定できませんでした。';
      }

      setState(() {
        _predictionResult = resultText;
      });

    } catch (e) {
      print('Error during inference: $e');
      setState(() {
        _predictionResult = 'エラー: 分類中に問題が発生しました。$e';
      });
    }
  }

  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    List<double> expValues = logits.map((e) => math.exp(e - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((e) => e / sumExp).toList();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _predictionResult = '分類中...';
        });
        await _runInference(_imageFile!);
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _predictionResult = 'エラー: 画像の選択に失敗しました。$e';
      });
    }
  }

  // 住所に基づいたゴミサク検索
  Future<void> _openGomisukuPage() async {
    final prefs = await SharedPreferences.getInstance();
    final prefecture = prefs.getString('prefecture') ?? '';
    final city = prefs.getString('city') ?? '';

    if (_labels == null || _predictionResult.contains('不明') || !_predictionResult.contains('分類結果:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分類結果が取得できていません。画像を分類してください。')),
      );
      return;
    }

    if (prefecture.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('住所が設定されていません。住所設定画面で入力してください。')),
      );
      return;
    }

    final String predictedLabel = _predictionResult.split('分類結果: ')[1].split(' (信頼度:')[0];
    try {
      final url = await TrashRecognitionService.generateGomisukuUrl(predictedLabel);
      print('Generated URL: $url'); // デバッグ用
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ゴミサクページを開けませんでした。住所を確認してください。')),
        );
      }
    } catch (e) {
      print('Error opening Gomisuku page: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
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