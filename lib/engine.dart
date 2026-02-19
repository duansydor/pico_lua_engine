import 'package:flutter/material.dart';
import 'models.dart';

class EnginePainter extends CustomPainter {
  final List<DrawCommand> commands;
  final List<Color> palette;
  final List<List<List<int>>> spriteBank;
  final List<List<int>> mapData;

  EnginePainter(this.commands, this.spriteBank, this.palette, this.mapData);

  @override
  void paint(Canvas canvas, Size size) {
    double scale = size.width / 128;
    canvas.save();
    canvas.scale(scale, scale);

    // Fundo preto absoluto (fora da câmera)
    canvas.drawRect(
      const Offset(0, 0) & const Size(128, 128),
      Paint()..color = Colors.black,
    );

    // Salva o estado ANTES da câmera entrar em ação
    canvas.save();

    // 🔥 NOVO: Variáveis para saber pra onde a câmera está olhando
    double camX = 0;
    double camY = 0;

    for (var cmd in commands) {
      final paint = Paint()
        ..color = palette[cmd.colorIndex]
        ..isAntiAlias = false;

      // ===================================
      // CÂMERA E LIMPEZA
      // ===================================
      if (cmd.type == 'camera') {
        camX = cmd.x; // Guarda o X atual da câmera
        camY = cmd.y; // Guarda o Y atual da câmera
        canvas.restore(); // Reseta a câmera anterior
        canvas.save(); // Salva o novo estado
        canvas.translate(-camX, -camY); // Move o mundo inteiro
      } else if (cmd.type == "cls") {
        // 🔥 CORREÇÃO: Em vez de resetar a matriz, apenas pintamos um
        // retângulo de 128x128 exatamente em cima da visão atual da câmera!
        canvas.drawRect(Rect.fromLTWH(camX, camY, 128, 128), paint);
      }
      // ===================================
      // FORMAS PRIMITIVAS E TEXTO
      // ===================================
      else if (cmd.type == 'rect') {
        paint.style = PaintingStyle.stroke;
        canvas.drawRect(Rect.fromLTRB(cmd.x, cmd.y, cmd.x2, cmd.y2), paint);
      } else if (cmd.type == 'rectfill') {
        canvas.drawRect(Rect.fromLTRB(cmd.x, cmd.y, cmd.x2, cmd.y2), paint);
      } else if (cmd.type == 'circfill') {
        canvas.drawCircle(Offset(cmd.x, cmd.y), cmd.w, paint);
      } else if (cmd.type == 'pset') {
        canvas.drawRect(Rect.fromLTWH(cmd.x, cmd.y, 1, 1), paint);
      } else if (cmd.type == 'print') {
        final textSpan = TextSpan(
          text: cmd.text,
          style: TextStyle(
            color: paint.color,
            fontSize: 8,
            fontFamily: 'monospace',
            height: 1.0,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(cmd.x, cmd.y));
      }
      // ===================================
      // SPRITES E MAPA
      // ===================================
      else if (cmd.type == 'spr') {
        _drawSprite(canvas, cmd.spriteId, cmd.frame, cmd.x, cmd.y);
      } else if (cmd.type == 'map') {
        for (int my = 0; my < cmd.mapH; my++) {
          for (int mx = 0; mx < cmd.mapW; mx++) {
            int tileX = cmd.mapX + mx;
            int tileY = cmd.mapY + my;

            if (tileY >= 0 &&
                tileY < mapData.length &&
                tileX >= 0 &&
                tileX < mapData[0].length) {
              int sprId = mapData[tileY][tileX];
              if (sprId >= 0) {
                _drawSprite(
                  canvas,
                  sprId,
                  0,
                  cmd.x + (mx * 8),
                  cmd.y + (my * 8),
                );
              }
            }
          }
        }
      }
    }

    // Restaura a câmera e o tamanho
    canvas.restore();
    canvas.restore();
  }

  void _drawSprite(Canvas canvas, int id, int frame, double x, double y) {
    if (id < 0 || id >= 256) return; // Segurança
    List<int> pixels = spriteBank[id][frame];
    for (int i = 0; i < 64; i++) {
      int colorCode = pixels[i];
      if (colorCode != 0) {
        double px = x + (i % 8);
        double py = y + (i ~/ 8);
        canvas.drawRect(
          Rect.fromLTWH(px, py, 1, 1),
          Paint()..color = palette[colorCode],
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
