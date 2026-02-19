import 'package:flutter/material.dart';
import 'sprite_tab.dart';

class MapTab extends StatefulWidget {
  final List<List<int>> mapData;
  final List<List<List<int>>> spriteBank;
  final List<Color> palette;

  const MapTab({
    super.key,
    required this.mapData,
    required this.spriteBank,
    required this.palette,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  int _selectedSprite = 1;
  int _selectedRoom = 0; // 🔥 NOVO: Qual tela (0 a 15) estamos visualizando

  final GlobalKey _mapKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculando o deslocamento (offset) do mapa gigante baseado na tela atual
    // Como temos 8 telas de largura, dividimos a matemática
    int offsetX = (_selectedRoom % 8) * 16;
    int offsetY = (_selectedRoom ~/ 8) * 16;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      radius: const Radius.circular(4),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 12.0, bottom: 20.0),
        child: Column(
          children: [
            const Text(
              "SELECIONE A TELA DO MAPA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),

            // 🔥 NOVO: SELETOR DE TELAS (0 a 15)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: List.generate(16, (index) {
                bool isActive = _selectedRoom == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRoom = index),
                  child: Container(
                    width: 32,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.purpleAccent : Colors.black,
                      border: Border.all(
                        color: isActive ? Colors.white : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "$index",
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            Text(
              "EDITANDO TELA $_selectedRoom (16x16)",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),

            // 1. O QUADRO DO MAPA (TAMANHO FIXO GRANDE)
            GestureDetector(
              onPanDown: (details) =>
                  _paintMap(details.globalPosition, offsetX, offsetY),
              onPanUpdate: (details) =>
                  _paintMap(details.globalPosition, offsetX, offsetY),
              child: Container(
                key: _mapKey,
                width: 240, // Espaço confortável
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 16,
                  ),
                  itemCount: 256,
                  itemBuilder: (context, index) {
                    // 🔥 Lendo o dado do mapa gigante usando o offset da tela
                    int col = (index % 16) + offsetX;
                    int row = (index ~/ 16) + offsetY;
                    int sprId = widget.mapData[row][col];

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withAlpha(5),
                          width: 0.1,
                        ),
                      ),
                      child: sprId >= 0
                          ? CustomPaint(
                              painter: MiniSpritePainter(
                                widget.spriteBank[sprId][0],
                                widget.palette,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. SELETOR DE SPRITE ("O Pincel")
            const Text(
              "SELECIONE O SPRITE PARA PINTAR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),

            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: GridView.builder(
                shrinkWrap:
                    true, // Estica para caber tudo (resolve o esmagamento)
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 128, // Mostrando 128 sprites como "pincéis"
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSprite = index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedSprite == index
                              ? Colors.redAccent
                              : Colors.grey[800]!,
                          width: _selectedSprite == index ? 2 : 1,
                        ),
                      ),
                      child: CustomPaint(
                        painter: MiniSpritePainter(
                          widget.spriteBank[index][0],
                          widget.palette,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _paintMap(Offset globalPosition, int offsetX, int offsetY) {
    if (_mapKey.currentContext == null) return;
    RenderBox box = _mapKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(globalPosition);

    // Calcula o tamanho da celula dinamicamente
    double cellSize = box.size.width / 16;

    // Soma o Offset da Tela Atual!
    int col = (localPosition.dx / cellSize).floor() + offsetX;
    int row = (localPosition.dy / cellSize).floor() + offsetY;

    // O limite máximo do mapa gigante (128x32)
    if (col >= 0 && col < 128 && row >= 0 && row < 32) {
      if (widget.mapData[row][col] != _selectedSprite) {
        setState(() {
          widget.mapData[row][col] = _selectedSprite;
        });
      }
    }
  }
}
