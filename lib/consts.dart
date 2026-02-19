import 'package:flutter/material.dart';

const List<Color> palette = [
  Color(0xFF000000), // 0: black
  Color(0xFF1D2B53), // 1: dark_blue
  Color(0xFF7E2553), // 2: dark_purple
  Color(0xFF008751), // 3: dark_green
  Color(0xFFAB5236), // 4: brown
  Color(0xFF5F574F), // 5: dark_gray
  Color(0xFFC2C3C7), // 6: light_gray
  Color(0xFFFFF1E8), // 7: white
  Color(0xFFFF004D), // 8: red
  Color(0xFFFFA300), // 9: orange
  Color(0xFFFFEC27), // 10: yellow
  Color(0xFF00E436), // 11: green
  Color(0xFF29ADFF), // 12: blue
  Color(0xFF83769C), // 13: indigo
  Color(0xFFFF77A8), // 14: pink
  Color(0xFFFFCCAA), // 15: peach
];
// A Lista ordenada (Essencial para os Sprites saberem quem é quem)
const Map<String, int> colorNames = {
  "black": 0,
  "dark_blue": 1,
  "dark_purple": 2,
  "dark_green": 3,
  "brown": 4,
  "dark_gray": 5,
  "light_gray": 6,
  "white": 7,
  "red": 8,
  "orange": 9,
  "yellow": 10,
  "green": 11,
  "blue": 12,
  "indigo": 13,
  "pink": 14,
  "peach": 15,
};
const String fallbackCartridge = '''
{
  "code": "x=64 y=64\\nfunction _update()\\n  if btn(0) then x=x-2 end\\n  if btn(1) then x=x+2 end\\n  if btn(2) then y=y-2 end\\n  if btn(3) then y=y+2 end\\nend\\nfunction _draw()\\n  cls(12)\\n  print('FALLBACK MODE', 40, 20, 7)\\n  spr(0, x, y, 0)\\nend",
  "sprites": [[[0,11,11,11,11,11,0,0,11,11,11,11,7,11,0,0,15,15,5,15,15,5,15,0,15,15,15,4,15,15,0,0,11,11,12,12,12,11,11,0,15,12,12,12,12,12,15,0,0,12,12,0,12,12,0,0,0,4,4,0,4,4,0,0]]],
  "flags": [0],
  "map": [[-1]]
}
''';
