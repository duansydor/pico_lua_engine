import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lua_dardo/lua.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'consts.dart';
import 'models.dart';
import 'engine.dart';
import 'controls.dart';
import 'sprite_tab.dart';
import 'map_tab.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Engine',
      theme: ThemeData(colorScheme: ColorScheme.dark()),
      home: const MyHomePage(title: 'Mini Engine'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 🔥 NOVO: Começa na aba 0 (JOGAR)
  int _selectedTab = 0;

  final TextEditingController _codeController = TextEditingController();
  final List<bool> _inputState = List.filled(6, false);

  final List<List<List<int>>> _spriteBank = List.generate(
    256,
    (_) => List.generate(4, (_) => List.filled(64, 0)),
  );
  final List<int> _spriteFlags = List.filled(256, 0);
  final List<List<int>> _mapMemory = List.generate(
    32,
    (_) => List.filled(128, -1),
  );
  List<List<int>> _runtimeMap = [];
  final List<DrawCommand> _drawCommandList = [];
  late LuaState state;
  Timer? _gameLoop;

  @override
  void initState() {
    super.initState();
    _bootConsole();
  }

  Future<void> _bootConsole() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('save_full_project');

    if (savedData != null) {
      // 1. Tenta carregar o que o usuário salvou por último
      _injectCartridgeData(savedData);
    } else {
      try {
        // 2. Se não houver save, tenta carregar o arquivo empacotado
        String assetData = await rootBundle.loadString('assets/cartucho.json');
        _injectCartridgeData(assetData);
      } catch (e) {
        // 3. SE O ARQUIVO NÃO EXISTIR: Carrega o cartucho "hardcoded" de segurança!
        debugPrint(
          "Aviso: cartucho.json não encontrado nos assets. Usando fallback.",
        );
        _injectCartridgeData(fallbackCartridge);
      }
    }
    _startEngine();
  }

  void _injectCartridgeData(String jsonString) {
    Map<String, dynamic> data = jsonDecode(jsonString);
    setState(() {
      _codeController.text = data['code'] ?? "";
      if (data['sprites'] != null) {
        var sprs = data['sprites'] as List;
        for (int i = 0; i < sprs.length; i++) {
          for (int f = 0; f < sprs[i].length; f++) {
            _spriteBank[i][f] = List<int>.from(sprs[i][f]);
          }
        }
      }
      if (data['flags'] != null) {
        _spriteFlags.setAll(0, List<int>.from(data['flags']));
      }
      if (data['map'] != null) {
        var mps = data['map'] as List;
        for (int r = 0; r < mps.length; r++) {
          _mapMemory[r].setAll(0, List<int>.from(mps[r]));
        }
      }
    });
  }

  void _saveInternal() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> project = {
      'code': _codeController.text,
      'sprites': _spriteBank,
      'flags': _spriteFlags,
      'map': _mapMemory,
    };
    await prefs.setString('save_full_project', jsonEncode(project));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Salvo no Memory Card! 💾')));
    }
  }

  void _exportCartridge() async {
    Map<String, dynamic> project = {
      'code': _codeController.text,
      'sprites': _spriteBank,
      'flags': _spriteFlags,
      'map': _mapMemory,
    };
    final bytes = utf8.encode(jsonEncode(project));
    // ignore: deprecated_member_use
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: 'meu_jogo.json',
        mimeType: 'application/json',
      ),
    ]);
  }

  void _importCartridge() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      String content = await File(result.files.single.path!).readAsString();
      _injectCartridgeData(content);
      _startEngine();
    }
  }

  void _startEngine() {
    _runtimeMap = _mapMemory.map((row) => List<int>.from(row)).toList();
    state = LuaState.newState()..openLibs();

    state.register("btn", (ls) {
      ls.pushBoolean(_inputState[ls.toInteger(1)]);
      return 1;
    });
    state.register("cls", (ls) {
      _drawCommandList.add(
        DrawCommand(
          type: 'cls',
          colorIndex:
              int.tryParse(ls.toStr(1) ?? "0") ?? colorNames[ls.toStr(1)] ?? 0,
        ),
      );
      return 0;
    });
    state.register("spr", (ls) {
      _drawCommandList.add(
        DrawCommand(
          type: 'spr',
          spriteId: ls.toInteger(1),
          x: ls.toNumber(2),
          y: ls.toNumber(3),
          frame: ls.toInteger(4),
        ),
      );
      return 0;
    });
    state.register("map", (ls) {
      _drawCommandList.add(
        DrawCommand(
          type: 'map',
          mapX: ls.toInteger(1),
          mapY: ls.toInteger(2),
          x: ls.toNumber(3),
          y: ls.toNumber(4),
          mapW: ls.toInteger(5),
          mapH: ls.toInteger(6),
        ),
      );
      return 0;
    });
    state.register("mget", (ls) {
      int x = ls.toInteger(1), y = ls.toInteger(2);
      ls.pushInteger(
        (x >= 0 && x < 128 && y >= 0 && y < 32) ? _runtimeMap[y][x] : -1,
      );
      return 1;
    });
    state.register("mset", (ls) {
      int x = ls.toInteger(1), y = ls.toInteger(2), v = ls.toInteger(3);
      if (x >= 0 && x < 128 && y >= 0 && y < 32) _runtimeMap[y][x] = v;
      return 0;
    });
    state.register("fget", (ls) {
      int id = ls.toInteger(1), f = ls.toInteger(2);
      ls.pushBoolean(
        (id >= 0 && id < 256) ? (_spriteFlags[id] & (1 << f)) != 0 : false,
      );
      return 1;
    });
    state.register("print", (ls) {
      _drawCommandList.add(
        DrawCommand(
          type: 'print',
          text: ls.toStr(1) ?? "",
          x: ls.toNumber(2),
          y: ls.toNumber(3),
          colorIndex:
              colorNames[ls.toStr(4)] ?? int.tryParse(ls.toStr(4) ?? "7") ?? 7,
        ),
      );
      return 0;
    });
    state.register("camera", (ls) {
      _drawCommandList.add(
        DrawCommand(
          type: 'camera',
          x: ls.toNumber(1) ?? 0,
          y: ls.toNumber(2) ?? 0,
        ),
      );
      return 0;
    });

    String poly =
        "flr=math.floor sin=math.sin cos=math.cos rnd=function(x) return math.random()*(x or 1) end";
    try {
      state.doString(poly);
      state.doString(_codeController.text);
    } catch (e) {
      _codeController.text = "-- Erro: $e\n${_codeController.text}";
    }

    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _drawCommandList.clear();
      for (var n in ["_update", "_draw"]) {
        state.getGlobal(n);
        if (state.isFunction(-1))
          state.pCall(0, 0, 0);
        else
          state.pop(1);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Mini Engine",
          style: TextStyle(color: Colors.teal, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open, color: Colors.purpleAccent),
            onPressed: _importCartridge,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.blueAccent),
            onPressed: _exportCartridge,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.amber),
            onPressed: _saveInternal,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            onPressed: _startEngine,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔥 MOSTRA O CONSOLE SE NÃO ESTIVER NA ABA CÓDIGO (1)
          if (_selectedTab != 1) ...[
            Expanded(
              flex: _selectedTab == 0 ? 5 : 4, // Mais espaço no modo "JOGAR"
              child: Container(
                color: Colors.grey[900],
                alignment: Alignment.center,
                child: FittedBox(
                  child: SizedBox(
                    width: 512,
                    height: 512,
                    child: CustomPaint(
                      painter: EnginePainter(
                        _drawCommandList,
                        _spriteBank,
                        palette,
                        _runtimeMap,
                      ),
                      size: const Size(512, 512),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Positioned(
                    bottom: 10,
                    left: 20,
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: GameButton(
                              icon: Icons.keyboard_arrow_up,
                              onChanged: (v) => _inputState[2] = v,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: GameButton(
                              icon: Icons.keyboard_arrow_down,
                              onChanged: (v) => _inputState[3] = v,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GameButton(
                              icon: Icons.keyboard_arrow_left,
                              onChanged: (v) => _inputState[0] = v,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GameButton(
                              icon: Icons.keyboard_arrow_right,
                              onChanged: (v) => _inputState[1] = v,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    right: 20,
                    child: Row(
                      children: [
                        GameButton(
                          icon: Icons.close,
                          onChanged: (v) => _inputState[5] = v,
                        ),
                        const SizedBox(width: 10),
                        GameButton(
                          icon: Icons.circle,
                          onChanged: (v) => _inputState[4] = v,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.green),
          ],

          // ÁREA DE EDIÇÃO OU BARRA DE ABAS
          Expanded(
            flex: _selectedTab == 0 ? 1 : (_selectedTab == 1 ? 10 : 6),
            child: Container(
              color: const Color(0xFF1E1E1E),
              child: Column(
                children: [
                  // 🔥 BARRA DE NAVEGAÇÃO DE ABAS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _tabButton("JOGAR", 0),
                        _tabButton("CÓDIGO", 1),
                        _tabButton("SPRITES", 2),
                        _tabButton("MAPA", 3),
                      ],
                    ),
                  ),

                  // CONTEÚDO DOS EDITORES (Somente se não for JOGAR)
                  if (_selectedTab != 0)
                    Expanded(
                      child: IndexedStack(
                        index:
                            _selectedTab -
                            1, // Deslocado 1 porque "JOGAR" é o índice 0
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _codeController,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.greenAccent,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SpriteTab(
                              spriteBank: _spriteBank,
                              palette: palette,
                              spriteFlags: _spriteFlags,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: MapTab(
                              mapData: _mapMemory,
                              spriteBank: _spriteBank,
                              palette: palette,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Função para criar os botões das abas com estilo unificado
  Widget _tabButton(String label, int index) {
    bool active = _selectedTab == index;
    return TextButton(
      onPressed: () => setState(() => _selectedTab = index),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.teal : Colors.white,
          fontSize: 11,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
