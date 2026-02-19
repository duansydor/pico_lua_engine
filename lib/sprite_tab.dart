import 'package:flutter/material.dart';

class SpriteTab extends StatefulWidget {
  final List<List<List<int>>> spriteBank;
  final List<int> spriteFlags;
  final List<Color> palette;

  const SpriteTab({
    super.key,
    required this.spriteBank,
    required this.palette,
    required this.spriteFlags,
  });

  @override
  State<SpriteTab> createState() => _SpriteTabState();
}

class _SpriteTabState extends State<SpriteTab> {
  int _selectedColor = 8;
  int _selectedSprite = 0;
  int _selectedFrame = 0;

  final GlobalKey _gridKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 A MÁGICA 1: O Scrollbar agora engloba a TELA INTEIRA
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      radius: const Radius.circular(4),
      // 🔥 A MÁGICA 2: A tela inteira agora rola para baixo!
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          right: 12.0,
          bottom: 20.0,
        ), // Dá um respiro pro scroll
        child: Column(
          children: [
            // ==========================================
            // 1. A PALETA DE CORES
            // ==========================================
            const Text(
              "PALETA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: List.generate(16, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.palette[index],
                      border: Border.all(
                        color: _selectedColor == index
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 2. O GRID DE PINTURA (TAMANHO FIXO GRANDE)
            // ==========================================
            Text(
              "EDITANDO SPRITE $_selectedSprite",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (fIndex) {
                bool isActive = _selectedFrame == fIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFrame = fIndex),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blueAccent : Colors.black,
                      border: Border.all(
                        color: isActive ? Colors.white : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "F$fIndex",
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

            const SizedBox(height: 8),

            // 🔥 A MÁGICA 3: O quadro agora tem 240x240 pixels (bem confortável pra desenhar)
            GestureDetector(
              onPanDown: (details) =>
                  _paintOnGlobalPosition(details.globalPosition),
              onPanUpdate: (details) =>
                  _paintOnGlobalPosition(details.globalPosition),
              child: Container(
                key: _gridKey,
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: GridView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // Desliga a rolagem de dentro do quadro
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    int pixelColor = widget
                        .spriteBank[_selectedSprite][_selectedFrame][index];
                    return Container(
                      decoration: BoxDecoration(
                        color: widget.palette[pixelColor],
                        border: Border.all(
                          color: Colors.white.withAlpha(5),
                          width: 0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 3. SISTEMA DE FLAGS E BANCO
            // ==========================================
            const Text(
              "FLAGS (0 = SÓLIDO)",
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (flagIndex) {
                bool isActive =
                    (widget.spriteFlags[_selectedSprite] & (1 << flagIndex)) !=
                    0;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.spriteFlags[_selectedSprite] ^= (1 << flagIndex);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.yellow : Colors.black,
                      border: Border.all(color: Colors.white54),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$flagIndex",
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            const Text(
              "BANCO DE SPRITES",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),

            // 🔥 A MÁGICA 4: O Banco de Sprites não tem mais Expanded. Ele cresce o quanto precisar.
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: GridView.builder(
                shrinkWrap:
                    true, // Avisa o GridView para renderizar tudo e esticar a tela para baixo
                physics:
                    const NeverScrollableScrollPhysics(), // A tela inteira rola, não apenas o Grid
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 256,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSprite = index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedSprite == index
                              ? Colors.greenAccent
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

  // --- Funções Auxiliares de Pintura ---

  void _setPixel(int index) {
    if (widget.spriteBank[_selectedSprite][_selectedFrame][index] !=
        _selectedColor) {
      setState(() {
        widget.spriteBank[_selectedSprite][_selectedFrame][index] =
            _selectedColor;
      });
    }
  }

  void _paintOnGlobalPosition(Offset globalPosition) {
    if (_gridKey.currentContext == null) return;

    RenderBox box = _gridKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(globalPosition);

    double pixelSize = box.size.width / 8;

    int col = (localPosition.dx / pixelSize).floor();
    int row = (localPosition.dy / pixelSize).floor();

    if (col >= 0 && col < 8 && row >= 0 && row < 8) {
      int index = (row * 8) + col;
      _setPixel(index);
    }
  }
}

class MiniSpritePainter extends CustomPainter {
  final List<int> pixels;
  final List<Color> palette;

  MiniSpritePainter(this.pixels, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    double pSize = size.width / 8;
    for (int i = 0; i < 64; i++) {
      int colorCode = pixels[i];
      if (colorCode != 0) {
        double x = (i % 8) * pSize;
        double y = (i ~/ 8) * pSize;
        canvas.drawRect(
          Rect.fromLTWH(x, y, pSize, pSize),
          Paint()
            ..color = palette[colorCode]
            ..isAntiAlias = false,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
