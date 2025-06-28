import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// AIモデル関連のインポート（前回の回答を参照）
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
// import 'package:flutter/services.dart' show rootBundle;
// import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ごみ分別AI', // アプリのタイトルをより分かりやすく
      theme: ThemeData(
        primarySwatch: Colors.green, // ゴミ分別に合う色合いに変更
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green, // App Bar の背景色
          foregroundColor: Colors.white, // App Bar のテキスト色
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // ボタンの背景色
            foregroundColor: Colors.white, // ボタンのテキスト色
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // 角丸ボタン
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

  // AIモデル関連の変数と初期化（前回の回答からコピー）
  // Interpreter? _interpreter;
  // List<String>? _labels;
  String _predictionResult = '画像を選択して分類を開始'; // 初期メッセージを変更
  // final int _inputSize = 224;
  // final int _inputChannels = 3;
  // final TfLiteType _inputType = TfLiteType.float32;

  @override
  void initState() {
    super.initState();
    // _loadModel(); // モデルロードの呼び出し（前回の回答を参照）
  }

  @override
  void dispose() {
    // _interpreter?.close(); // インタープリターのクローズ（前回の回答を参照）
    super.dispose();
  }

  // モデルロード関数（前回の回答からコピー）
  // Future<void> _loadModel() async { ... }

  // 推論実行関数（前回の回答からコピー）
  // Future<void> _runInference(File imageFile) async { ... }


  // 画像選択ソース（ギャラリーまたはカメラ）を選択するダイアログ
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

  // 実際の画像選択ロジック
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _predictionResult = '分類中...'; // 画像選択時にメッセージを更新
        });
        // await _runInference(_imageFile!); // 推論を実行（AIモデル統合後）
        // TODO: AIモデル統合後、上記のコメントを解除し推論を呼び出す
        // ダミーの分類結果をシミュレート
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _predictionResult = '分類結果: ペットボトル (信頼度: 98.50%)';
          });
        });

      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _predictionResult = 'エラー: 画像の選択に失敗しました。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ごみ分別AI'),
        centerTitle: true, // タイトルを中央に配置
      ),
      body: SingleChildScrollView( // コンテンツがはみ出す場合にスクロール可能にする
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // 子要素を横幅いっぱいに広げる
            children: <Widget>[
              // 画像表示エリア
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                height: 300, // 画像表示エリアの高さ
                child: _imageFile == null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text(
                        '画像が選択されていません',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
                    : ClipRRect( // 角丸にするためにClipRRectを使用
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover, // 画像をコンテナに合わせてカバー
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 予測結果表示
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green[50], // 薄い緑の背景
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  _predictionResult,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800], // 濃い緑の文字色
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              // ボタン
              ElevatedButton.icon(
                onPressed: () => _showImageSourceDialog(context), // ダイアログを表示
                icon: const Icon(Icons.add_a_photo),
                label: const Text('画像を選択 / 撮影'),
              ),

              // 必要に応じて、追加のボタンなどを配置できます
              // const SizedBox(height: 15),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     // 分類履歴など
              //   },
              //   icon: const Icon(Icons.history),
              //   label: const Text('分類履歴を見る'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blueGrey, // 別の色
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tensor の `reshape` メソッドをリストに拡張（AIモデル統合後も必要）
// extension ReshapeExtension on List { ... }