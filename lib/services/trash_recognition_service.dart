// lib/services/trash_recognition_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'package:garbage_app/services/address_service.dart';

class TrashRecognitionService {
  static const String _baseGomisukuUrl = 'https://www.gomisaku.jp';
  static Interpreter? _interpreter;
  static List<String> _labels = [];

  /// TFLiteモデルとラベルを非同期でロードする
  static Future<void> loadModel() async {
    if (_interpreter != null) return; // すでにロード済みなら何もしない
    try {
      _interpreter = await Interpreter.fromAsset('assets/garbage_model_4.tflite');
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      debugPrint('モデルとラベルを読み込みました: ${_labels.length} ラベル');
    } catch (e) {
      debugPrint('モデル読み込みエラー: $e');
    }
  }

  /// 画像をモデルの入力形式に前処理する
  static List<List<List<List<double>>>> preprocessImage(File imageFile) {
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final resizedImage = img.copyResize(image, width: 128, height: 128); // モデルの入力サイズに合わせる
    final imageBytes = resizedImage.getBytes();

    final input = List.generate(1, (_) => List.generate(128, (_) => List.generate(128, (_) => List<double>.filled(3, 0.0))));
    for (int y = 0; y < 128; y++) {
      for (int x = 0; x < 128; x++) {
        final pixelIndex = (y * 128 + x) * 3;
        if (pixelIndex + 2 < imageBytes.length) {
          input[0][y][x][0] = imageBytes[pixelIndex] / 255.0;
          input[0][y][x][1] = imageBytes[pixelIndex + 1] / 255.0;
          input[0][y][x][2] = imageBytes[pixelIndex + 2] / 255.0;
        }
      }
    }
    return input;
  }

  /// ゴミの画像を認識し、結果を返す
  static Future<TrashRecognitionResult?> recognizeTrash(File imageFile) async {
    try {
      if (_interpreter == null) {
        // モデルがロードされていなければここでロードを試みる
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

  /// 認識結果とユーザーの住所に基づいてゴミサクのURLを生成する
  static Future<String> generateGomisukuUrl(String itemLabel) async {
    try {
      final cleanedItemLabel = itemLabel.replaceAll(RegExp(r'<[^>]*>|[\n\r]'), '').trim();
      final prefs = await SharedPreferences.getInstance();
      final prefecture = prefs.getString('prefecture') ?? '';
      final city = prefs.getString('city') ?? '';
      final gomisakuId = AddressService.getGomisakuIdForCity(prefecture, city);

      if (gomisakuId != null) {
        return '$_baseGomisukuUrl/$gomisakuId/?lang=ja#gomisaku_keyword:${Uri.encodeComponent(cleanedItemLabel)}';
      } else {
        return '$_baseGomisukuUrl/?search_region=${Uri.encodeComponent('$prefecture$city')}&search_word=${Uri.encodeComponent(cleanedItemLabel)}';
      }
    } catch (e) {
      debugPrint('URL生成エラー: $e');
      return _baseGomisukuUrl;
    }
  }

  /// 生成されたURLをごみサクのページを開く
  static Future<void> openGomisukuPage(String itemLabel) async {
    try {
      final url = await generateGomisukuUrl(itemLabel);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('URLを開けませんでした: $url');
      }
    } catch (e) {
      debugPrint('ページオープンエラー: $e');
      rethrow;
    }
  }

  /// カメラまたはギャラリーから画像を選択する
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