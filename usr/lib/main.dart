import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prédicteur de Mines',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A2025),
        primaryColor: const Color(0xFF00A2FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00A2FF),
          secondary: Color(0xFFFFD700),
          surface: Color(0xFF2C3A47),
          onSurface: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A2FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C3A47),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Arial',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const MinesPredictorPage(),
    );
  }
}

enum CellState { hidden, revealedSafe, revealedMine }

class MinesPredictorPage extends StatefulWidget {
  const MinesPredictorPage({super.key});

  @override
  State<MinesPredictorPage> createState() => _MinesPredictorPageState();
}

class _MinesPredictorPageState extends State<MinesPredictorPage> {
  int _rows = 5;
  int _cols = 5;
  int _mineCount = 3;

  late List<List<CellState>> _grid;
  late Set<int> _minePositions;
  Set<int> _revealedPositions = {};
  bool _isGameOver = false;
  String _gameMessage = "Bonne chance !";
  double _safeProbability = 0.0;
  int? _suggestedIndex;

  final TextEditingController _rowsController = TextEditingController(text: '5');
  final TextEditingController _colsController = TextEditingController(text: '5');
  final TextEditingController _mineController = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      _rows = int.tryParse(_rowsController.text) ?? 5;
      _cols = int.tryParse(_colsController.text) ?? 5;
      _mineCount = int.tryParse(_mineController.text) ?? 3;
      
      if (_mineCount >= _rows * _cols) {
        _mineCount = _rows * _cols - 1;
        _mineController.text = _mineCount.toString();
      }
      if (_mineCount < 1) {
        _mineCount = 1;
        _mineController.text = '1';
      }

      _grid = List.generate(_rows, (_) => List.filled(_cols, CellState.hidden));
      _minePositions = _generateMines(_rows, _cols, _mineCount);
      _revealedPositions = {};
      _isGameOver = false;
      _gameMessage = "Sélectionnez une case pour commencer.";
      _suggestedIndex = null;
      _calculateProbability();
    });
  }

  Set<int> _generateMines(int rows, int cols, int mineCount) {
    final totalCells = rows * cols;
    final random = Random();
    final mines = <int>{};
    while (mines.length < mineCount) {
      mines.add(random.nextInt(totalCells));
    }
    return mines;
  }

  void _calculateProbability() {
    final totalCells = _rows * _cols;
    final unopenedCount = totalCells - _revealedPositions.length;
    final minesRevealed = _revealedPositions.where((pos) => _minePositions.contains(pos)).length;
    final minesRemaining = _mineCount - minesRevealed;

    if (unopenedCount > 0) {
      _safeProbability = (1.0 - (minesRemaining / unopenedCount)) * 100;
    } else {
      _safeProbability = 100.0;
    }
  }

  void _onCellTapped(int index) {
    if (_isGameOver || _revealedPositions.contains(index)) {
      return;
    }

    setState(() {
      _revealedPositions.add(index);
      _suggestedIndex = null; // Clear suggestion after a move

      if (_minePositions.contains(index)) {
        // Game Over
        _isGameOver = true;
        _gameMessage = "BOOM! Partie terminée.";
        // Reveal all mines
        for (final minePos in _minePositions) {
          final r = minePos ~/ _cols;
          final c = minePos % _cols;
          _grid[r][c] = CellState.revealedMine;
        }
      } else {
        // Safe
        final r = index ~/ _cols;
        final c = index % _cols;
        _grid[r][c] = CellState.revealedSafe;
        
        final totalSafeCells = (_rows * _cols) - _mineCount;
        final safeRevealedCount = _revealedPositions.length - _revealedPositions.where((pos) => _minePositions.contains(pos)).length;

        if (safeRevealedCount == totalSafeCells) {
          _isGameOver = true;
          _gameMessage = "Félicitations! Vous avez gagné!";
        } else {
          _gameMessage = "Continuez, vous êtes en sécurité.";
        }
      }
      _calculateProbability();
    });
  }
  
  void _suggestMove() {
      if (_isGameOver) return;
      
      final unopenedPositions = [];
      for (int i = 0; i < _rows * _cols; i++) {
        if (!_revealedPositions.contains(i)) {
          unopenedPositions.add(i);
        }
      }

      if (unopenedPositions.isNotEmpty) {
        setState(() {
          _suggestedIndex = unopenedPositions[Random().nextInt(unopenedPositions.length)];
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prédicteur de Mines Pro'),
        backgroundColor: const Color(0xFF1A2025),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingsPanel(),
            const SizedBox(height: 20),
            _buildInfoPanel(),
            const SizedBox(height: 20),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3A47),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Configuration", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(_rowsController, "Lignes")),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(_colsController, "Colonnes")),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(_mineController, "Mines")),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Nouvelle Partie"),
              onPressed: _startGame,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3A47),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Chance de survie:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                "${_safeProbability.toStringAsFixed(2)}%",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _safeProbability > 75 ? Colors.greenAccent : _safeProbability > 50 ? Colors.yellowAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_gameMessage, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70)),
           const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text("Prochain coup sûr"),
              onPressed: _suggestMove,
               style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
               ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return AspectRatio(
      aspectRatio: _cols / _rows,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _cols,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _rows * _cols,
        itemBuilder: (context, index) {
          final r = index ~/ _cols;
          final c = index % _cols;
          final cellState = _grid[r][c];

          return GestureDetector(
            onTap: () => _onCellTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: _getCellColor(cellState),
                borderRadius: BorderRadius.circular(8),
                border: _suggestedIndex == index ? Border.all(color: const Color(0xFFFFD700), width: 3) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  _getCellIcon(cellState),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCellColor(CellState state) {
    switch (state) {
      case CellState.hidden:
        return const Color(0xFF4A6572);
      case CellState.revealedSafe:
        return Colors.green.shade700;
      case CellState.revealedMine:
        return Colors.red.shade700;
    }
  }

  String _getCellIcon(CellState state) {
    switch (state) {
      case CellState.hidden:
        return '';
      case CellState.revealedSafe:
        return '💎';
      case CellState.revealedMine:
        return '💣';
    }
  }
}
