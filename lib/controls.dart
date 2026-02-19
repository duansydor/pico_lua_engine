import 'package:flutter/material.dart';

// Widget auxiliar no final do arquivo. Ele é um botão que detecta quando você segura e quando solta
// (o onPressed normal não serve para jogos, pois só dispara no final).
class GameButton extends StatelessWidget {
  final IconData icon;
  final Function(bool) onChanged;

  const GameButton({super.key, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),

      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
