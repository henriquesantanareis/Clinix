import 'package:flutter/material.dart';

class PainelMarcaClinix extends StatelessWidget {
  const PainelMarcaClinix({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF183D37),
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarcaClinix(light: true),
          const Spacer(),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF28564D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Color(0xFFB9E2D0),
              size: 31,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Seu cuidado,\nmais perto.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w600,
              height: 1.14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Acesse seus dados e mantenha sua jornada de saúde em dia.',
            style: TextStyle(
              color: Color(0xFFC5D5CF),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const Spacer(),
          const Text(
            'CLINIX  ·  SAÚDE COM CONFIANÇA',
            style: TextStyle(
              color: Color(0xFFB9CFC6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MarcaClinix extends StatelessWidget {
  const MarcaClinix({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : const Color(0xFF183D37);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.add_box_rounded, color: Color(0xFFDF8968), size: 28),
        const SizedBox(width: 9),
        Text(
          'clinix',
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class RotuloCampo extends StatelessWidget {
  const RotuloCampo(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF28433B),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
