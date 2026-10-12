import 'package:flutter/material.dart';

// Avatar reutilizable que prioriza una imagen y, cuando no está disponible,
// representa a la persona mediante las iniciales de su nombre.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final ImageProvider<Object>? imageProvider;
  final double radius;

  const InitialsAvatar({
    super.key,
    required this.name,
    required this.imageProvider,
    required this.radius,
  });

  // Obtiene la primera letra del primer y último término del nombre.
  //
  // Para un único término devuelve su primera letra; para un nombre vacío se
  // usa un signo de interrogación como representación neutral.
  static String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';

    final firstInitial = parts.first.characters.first;
    if (parts.length == 1) return firstInitial.toUpperCase();

    return '$firstInitial${parts.last.characters.first}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      foregroundImage: imageProvider,
      child: Text(
        initialsFor(name),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
