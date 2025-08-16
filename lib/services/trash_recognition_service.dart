// lib/services/trash_recognition_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TrashRecognitionService {
  static const String _baseGomisukuUrl = 'https://www.gomisaku.jp';
  static Interpreter? _interpreter;
  static List<String> _labels = [];

  static const Map<String, String> _cityIdMap = {
    '東京都新宿区': '0263',
    '東京都渋谷区': '0207',
    '大阪府大阪市': '0184',
    '愛知県名古屋市': '0185',
    '神奈川県横浜市': '0183',
    '福岡県福岡市': '0187',
    '北海道札幌市': '0186',
  };

  // TFLiteモデルの初期化
  static Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/garbage_model.tflite');
      final labelsData = await DefaultAssetBundle.of(GlobalKey<NavigatorState>().currentContext!).loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      debugPrint('モデルとラベルを読み込みました: ${_labels.length} ラベル');
    } catch (e) {
      debugPrint('モデル読み込みエラー: $e');
    }
  }

  // 画像を前処理
  static List<List<List<List<double>>>> preprocessImage(File imageFile) {
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final resizedImage = img.copyResize(image, width: 224, height: 224); // モデルの入力サイズに合わせる
    final imageBytes = resizedImage.getBytes();

    // モデルの入力形式に変換（224x224x3）
    final input = List.generate(1, (_) => List.generate(224, (_) => List.generate(224, (_) => List<double>.filled(3, 0.0))));
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixelIndex = (y * 224 + x) * 3; // RGBの各ピクセルは3バイト
        if (pixelIndex + 2 < imageBytes.length) {
          input[0][y][x][0] = imageBytes[pixelIndex] / 255.0;     // R
          input[0][y][x][1] = imageBytes[pixelIndex + 1] / 255.0; // G
          input[0][y][x][2] = imageBytes[pixelIndex + 2] / 255.0; // B
        }
      }
    }
    return input;
  }

  // ゴミの認識
  static Future<TrashRecognitionResult?> recognizeTrash(File imageFile) async {
    try {
      if (_interpreter == null) {
        await loadModel();
      }

      if (_interpreter == null || _labels.isEmpty) {
        throw Exception('モデルまたはラベルが読み込まれていません');
      }

      final input = preprocessImage(imageFile);

      final output = List.generate(1, (_) => List<double>.filled(_labels.length, 0.0));

      _interpreter!.run(input, output);

      final maxScore = output[0].reduce((a, b) => a > b ? a : b);
      final maxScoreIndex = output[0].indexOf(maxScore);
      final label = _labels[maxScoreIndex];

      final categoryMap = {
        'ペットボトル': '資源ごみ',
        '缶': '資源ごみ',
        '生ごみ': '燃えるごみ',
        '紙パック': '資源ごみ',
        '乾電池': '有害ごみ',
      };
      final descriptionMap = {
        'ペットボトル': 'プラスチック製飲料容器',
        '缶': 'アルミ缶・スチール缶',
        '生ごみ': '食品残渣',
        '紙パック': '牛乳パック等',
        '乾電池': '単三・単四電池等',
      };

      return TrashRecognitionResult(
        label: label,
        confidence: maxScore,
        category: categoryMap[label] ?? '不明',
        description: descriptionMap[label] ?? '不明なゴミ',
      );
    } catch (e) {
      debugPrint('画像認識エラー: $e');
      return null;
    }
  }

  static Future<String> generateGomisukuUrl(String itemLabel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefecture = prefs.getString('prefecture') ?? '';
      final city = prefs.getString('city') ?? '';
      final fullAddress = '$prefecture$city';
      final cityId = _cityIdMap[fullAddress];
      if (cityId != null) {
        return '$_baseGomisukuUrl/$cityId/?search_word=${Uri.encodeComponent(itemLabel)}&lang=ja';
      } else {
        return '$_baseGomisukuUrl/?search_region=${Uri.encodeComponent(fullAddress)}&search_word=${Uri.encodeComponent(itemLabel)}';
      }
    } catch (e) {
      debugPrint('URL生成エラー: $e');
      return _baseGomisukuUrl;
    }
  }

  static Future<void> openGomisukuPage(String itemLabel) async {
    try {
      final url = await generateGomisukuUrl(itemLabel);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('URLを開けませんでした: $url');
      }
    } catch (e) {
      debugPrint('ページオープンエラー: $e');
      rethrow;
    }
  }

  static Future<File?> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('画像選択エラー: $e');
      return null;
    }
  }

  static Future<List<String>> getSupportedCities(String prefecture) async {
    final supportedCities = <String>[];
    for (final key in _cityIdMap.keys) {
      if (key.startsWith(prefecture)) {
        supportedCities.add(key.replaceFirst(prefecture, ''));
      }
    }
    return supportedCities;
  }

  static Future<bool> isCitySupported() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefecture = prefs.getString('prefecture') ?? '';
      final city = prefs.getString('city') ?? '';
      final fullAddress = '$prefecture$city';
      return _cityIdMap.containsKey(fullAddress);
    } catch (e) {
      return false;
    }
  }
}

class TrashRecognitionResult {
  final String label;
  final double confidence;
  final String category;
  final String description;
  final DateTime timestamp;

  TrashRecognitionResult({
    required this.label,
    required this.confidence,
    required this.category,
    required this.description,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  Color get confidenceColor {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'category': category,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TrashRecognitionResult.fromJson(Map<String, dynamic> json) {
    return TrashRecognitionResult(
      label: json['label'],
      confidence: json['confidence'],
      category: json['category'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}