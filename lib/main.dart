import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ごみ分別AI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            side: const BorderSide(color: Colors.green),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Interpreter? _interpreter;
  List<String>? _labels;
  String _predictionResult = '画像をタップして分類を開始';

  // モデルの入力サイズとチャンネル数。モデルに合わせて調整してください。
  // あなたのモデルのログによると、Shape: [1, 128, 128, 3] なので、以下のように設定します。
  final int _inputSize = 128;
  final int _inputChannels = 3;

  // モデルから取得したTensorTypeを保持する変数
  TensorType _expectedInputType = TensorType.float32; // 初期値として一般的なfloat32を設定

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
      _interpreter = await Interpreter.fromAsset('assets/garbage_model.tflite');
      print('Model loaded successfully.');

      // ラベルファイルをロード
      String labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      print('Labels loaded: $_labels');

      // モデルの入力と出力の情報を表示（デバッグ用）
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      print('Input Tensors:');
      for (var tensor in inputTensors) {
        print('  Name: ${tensor.name}, Shape: ${tensor.shape}, Type: ${tensor.type}');
        // モデルの実際の入力型を取得して_expectedInputTypeを設定
        if (tensor.type == TensorType.float32 || tensor.type == TensorType.uint8) {
          _expectedInputType = tensor.type;
        }
      }
      print('Output Tensors:');
      for (var tensor in outputTensors) {
        print('  Name: ${tensor.name}, Shape: ${tensor.shape}, Type: ${tensor.type}');
      }

      setState(() {
        _predictionResult = 'モデル準備完了！画像をタップしてください。';
      });

    } catch (e) {
      print('Failed to load model or labels: $e');
      setState(() {
        _predictionResult = 'エラー: モデルのロードに失敗しました。';
      });
    }
  }

  // 画像をモデルの入力形式に前処理する関数
  // Uint8List (RGB 0-255) の一次元配列を返す
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

    // 画像データをRGBの一次元Uint8Listに変換
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

  // モデルの推論を実行する関数
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
      // 1. 画像の前処理
      final Uint8List inputImageBytes = _preProcessImage(imageFile);

      // モデルの入力テンソルに渡すためのデータ形式を準備
      // ここでTypedDataのインスタンスを直接準備し、List<Object>にラップします。
      // tflite_flutterは、このTypedDataとモデルの入力テンソルのShapeを使って、
      // 内部で正しくテンソルを構築します。
      TypedData processedInputData; // Float32List または Uint8List

      if (_expectedInputType == TensorType.float32) {
        // Uint8ListをFloat32Listに変換し、0-1に正規化
        final float32List = Float32List(inputImageBytes.length);
        for (int i = 0; i < inputImageBytes.length; i++) {
          float32List[i] = inputImageBytes[i] / 255.0;
        }
        processedInputData = float32List;
      } else if (_expectedInputType == TensorType.uint8) {
        // Uint8Listをそのまま使用
        processedInputData = inputImageBytes;
      } else {
        throw Exception('Unsupported input type for inference: $_expectedInputType');
      }

      // `_interpreter.run` には、`List<Object>` を渡します。
      // ここで渡すObjectは、Float32List または Uint8List の一次元配列です。
      // tflite_flutter がこの一次元配列をモデルの期待する [1, 128, 128, 3] に自動的にマッピングします。
      final List<Object> inputTensor = [processedInputData];


      // 2. 出力バッファの準備
      final outputTensorShape = _interpreter!.getOutputTensors().first.shape;
      // 出力は通常 [1, num_classes] の形をしています。
      var output = List.filled(
          outputTensorShape[0], List<double>.filled(outputTensorShape[1], 0.0));

      // 3. 推論の実行
      _interpreter!.run(inputTensor, output); // ここで `inputTensor` を渡す

      // 4. 結果の解析
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
      if (predictedIndex != -1 && _labels != null && predictedIndex < _labels!.length) {
        resultText = '分類結果: ${_labels![predictedIndex]} (信頼度: ${(maxProbability * 100).toStringAsFixed(2)}%)';
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

  // ソフトマックス関数
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ごみ分別AI'),
        centerTitle: true,
      ),
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
            ],
          ),
        ),
      ),
    );
  }
}