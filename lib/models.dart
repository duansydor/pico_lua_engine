class DrawCommand {
  final String
  type; // "rect", "cls", "spr", "map", "camera", "print", "circfill", "pset"
  final double x, y, w, h;
  final double x2, y2; // 🔥 NOVO: Para ponto final de retângulos e linhas
  final int colorIndex;
  final int spriteId;
  final int frame;
  final int mapX, mapY, mapW, mapH;
  final String text; // 🔥 NOVO: Para textos

  DrawCommand({
    required this.type,
    this.x = 0,
    this.y = 0,
    this.w = 0,
    this.h = 0,
    this.x2 = 0,
    this.y2 = 0,
    this.colorIndex = 0,
    this.spriteId = 0,
    this.frame = 0,
    this.mapX = 0,
    this.mapY = 0,
    this.mapW = 16,
    this.mapH = 16,
    this.text = "",
  });
}
