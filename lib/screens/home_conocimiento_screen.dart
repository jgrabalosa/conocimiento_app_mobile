import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../main.dart';
import '../widgets/bucle_pildoras.dart';
import 'biblioteca_screen.dart';
import 'perfil_usuario_lector_screen.dart';

/// La pantalla principal: el bucle de píldoras y nada más.
///
/// Sin pestañas ni `NavigationBar`, y por tanto sin `PageView`. Colección y
/// Perfil no son actividades paralelas al bucle —no hay nada paralelo al
/// bucle—, así que se abren con `Navigator.push` desde el `AppBar`, igual que
/// hace `HomeShell` en Hábitos con Colección y Logros.
class HomeConocimientoScreen extends StatelessWidget {
  const HomeConocimientoScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  /// Está aquí para poder probar con varias cuentas sin desinstalar la app.
  /// Va en el menú y no como icono suelto para que no se pulse sin querer.
  Future<void> _cerrarSesion(BuildContext context) async {
    await ApiServiceCore.logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(destinoTrasLogin: destinoTrasLogin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conocimiento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Biblioteca',
            icon: Icon(LucideIcons.library, color: t.textMuted),
            onPressed: () => _abrir(context, const BibliotecaScreen()),
          ),
          IconButton(
            tooltip: 'Perfil',
            icon: Icon(LucideIcons.userRound, color: t.textMuted),
            onPressed: () => _abrir(context, const PerfilUsuarioLectorScreen()),
          ),
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.menu, color: t.textMuted),
            onSelected: (valor) {
              if (valor == 'logout') _cerrarSesion(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: const BuclePildoras(),
    );
  }
}
