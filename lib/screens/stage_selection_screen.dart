// lib/screens/stage_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:garbage_app/services/gacha_service.dart';
import 'package:garbage_app/models/stage.dart';
import 'package:garbage_app/screens/monster_selection_screen.dart'; // MonsterSelectionScreenをインポート

class StageSelectionScreen extends StatefulWidget {
  const StageSelectionScreen({super.key});

  @override
  State<StageSelectionScreen> createState() => _StageSelectionScreenState();
}

class _StageSelectionScreenState extends State<StageSelectionScreen> {
  final GachaService _gachaService = GachaService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllGachaData();
  }

  Future<void> _loadAllGachaData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _gachaService.loadGachaPool();
      await _gachaService.loadMonsters();
      await _gachaService.loadStages();
      print('StageSelectionScreen: All GachaService data loaded.');
    } catch (e) {
      print('StageSelectionScreen: Error loading GachaService data: $e');
      setState(() {
        _errorMessage = 'ステージデータのロード中にエラーが発生しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('ステージデータをロード中...', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadAllGachaData,
                child: const Text('リトライ'),
              ),
            ],
          ),
        ),
      );
    }

    final List<Stage> stages = _gachaService.getAllStages();

    if (stages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ステージデータが見つかりませんでした。\nファイルを確認してください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAllGachaData,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ステージ選択'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final stage = stages[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4.0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Text(
                stage.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  stage.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // ★修正: MonsterSelectionScreen に stageId を渡して遷移 ★
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonsterSelectionScreen(
                      selectedStageId: stage.id, // ★引数名を正確に selectedStageId に合わせる ★
                    ),
                  ),
                );
                print('Selected stage: ${stage.name} (ID: ${stage.id})');
              },
            ),
          );
        },
      ),
    );
  }
}