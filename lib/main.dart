import 'package:flutter/material.dart';
import 'dart:math' show Random;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birdle Interactif',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODÈLE DU JEU — Classe Game
// ═══════════════════════════════════════════════════════════════════════════

enum LetterType { correctPosition, wrongPosition, notInWord, unguessed }

class Letter {
  final String char;
  final LetterType type;

  Letter(this.char, this.type);
}

class Game {
  static const int maxGuesses = 5;
  static const int wordLength = 5;

  final String _targetWord;
  final List<List<Letter>> _guesses = [];

  Game({String? targetWord})
    : _targetWord = (targetWord ?? _getRandomWord()).toUpperCase();

  static String _getRandomWord() {
    const wordList = [
      'HOUSE',
      'PLANT',
      'WATER',
      'MUSIC',
      'BRAIN',
      'LIGHT',
      'STONE',
      'BREAD',
      'DREAM',
      'CHAIR',
    ];
    // Sélectionner un mot aléatoire sans utiliser shuffle()
    final random = Random();
    return wordList[random.nextInt(wordList.length)];
  }

  List<List<Letter>> get guesses => _guesses;
  String get targetWord => _targetWord;
  bool get isGameOver => _guesses.length >= maxGuesses || isWon;
  bool get isWon =>
      _guesses.isNotEmpty &&
      _guesses.last.every((l) => l.type == LetterType.correctPosition);

  void reset() {
    _guesses.clear();
  }

  void guess(String word) {
    if (isGameOver) return;

    word = word.toUpperCase();
    if (word.length != wordLength) return;

    List<Letter> result = [];
    List<bool> targetUsed = List.filled(_targetWord.length, false);

    // Première passe : marquer les bonnes positions
    for (int i = 0; i < word.length; i++) {
      if (word[i] == _targetWord[i]) {
        result.add(Letter(word[i], LetterType.correctPosition));
        targetUsed[i] = true;
      } else {
        result.add(Letter(word[i], LetterType.unguessed));
      }
    }

    // Deuxième passe : marquer les lettres mal placées
    for (int i = 0; i < word.length; i++) {
      if (result[i].type == LetterType.unguessed) {
        bool found = false;
        for (int j = 0; j < _targetWord.length; j++) {
          if (!targetUsed[j] && word[i] == _targetWord[j]) {
            result[i] = Letter(word[i], LetterType.wrongPosition);
            targetUsed[j] = true;
            found = true;
            break;
          }
        }
        if (!found) {
          result[i] = Letter(word[i], LetterType.notInWord);
        }
      }
    }

    _guesses.add(result);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS UI
// ═══════════════════════════════════════════════════════════════════════════

class Tile extends StatelessWidget {
  final String char;
  final LetterType type;

  const Tile(this.char, this.type, {super.key});

  Color _getColor() {
    switch (type) {
      case LetterType.correctPosition:
        return Colors.green.shade600;
      case LetterType.wrongPosition:
        return Colors.amber.shade600;
      case LetterType.notInWord:
        return Colors.grey.shade600;
      case LetterType.unguessed:
        return Colors.white;
    }
  }

  Color _getTextColor() {
    if (type == LetterType.unguessed) {
      return Colors.black;
    }
    return Colors.white;
  }

  bool get _isRevealed => type != LetterType.unguessed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      /// ═══════════════════════════════════════════════════════════════════
      /// ÉTAPE 1 & 2 : Container → AnimatedContainer avec duration obligatoire
      /// ═══════════════════════════════════════════════════════════════════
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut, // ÉTAPE 3 : courbe personnalisée
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getColor(),
        border: Border.all(
          color: _isRevealed ? Colors.transparent : Colors.black,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _getTextColor(),
          ),
        ),
      ),
    );
  }
}

class GuessInput extends StatefulWidget {
  final Function(String) onSubmitGuess;
  final bool enabled;

  const GuessInput({
    required this.onSubmitGuess,
    this.enabled = true,
    super.key,
  });

  @override
  State<GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<GuessInput> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final guess = _controller.text.trim();
    if (guess.length == 5 && widget.enabled) {
      widget.onSubmitGuess(guess);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              decoration: InputDecoration(
                hintText: 'Entrez un mot (5 lettres)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) => _submit(),
              maxLength: 5,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: widget.enabled ? _submit : null,
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GAMEPAGE — Convertie en StatefulWidget avec setState()
// ═══════════════════════════════════════════════════════════════════════════

/// ╔═════════════════════════════════════════════════════════════════════════╗
/// ║ ÉTAPE 1 & 2 : GamePage est maintenant un StatefulWidget avec            ║
/// ║               createState() et la classe _GamePageState.                ║
/// ╚═════════════════════════════════════════════════════════════════════════╝
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

/// La classe _GamePageState contient l'état mutable du jeu.
class _GamePageState extends State<GamePage> {
  /// Propriété mutable : l'instance du jeu.
  /// Bien que 'final' dans les deux analyses précédentes, elle est ici 'late'
  /// pour pouvoir être réassignée quand l'utilisateur clique sur "Nouvelle partie".
  late Game _game = Game();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Birdle Interactif'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 12.0,
            children: [
              // Grille des devinettes
              for (var guess in _game.guesses)
                Row(
                  spacing: 6.0,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var letter in guess) Tile(letter.char, letter.type),
                  ],
                ),

              // Input
              GuessInput(
                onSubmitGuess: (String guess) {
                  setState(() {
                    _game.guess(guess);
                  });
                },
                enabled: !_game.isGameOver,
              ),

              // Message de fin
              if (_game.isGameOver)
                Column(
                  children: [
                    Text(
                      _game.isWon
                          ? '🎉 Bravo !  Vous avez trouvé : ${_game.targetWord}'
                          : '😢 Perdu ! Le mot était : ${_game.targetWord}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _game.isWon ? Colors.green : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _game = Game();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Nouvelle partie'),
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
