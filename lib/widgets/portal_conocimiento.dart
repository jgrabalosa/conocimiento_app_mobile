import 'package:flutter/material.dart';

import '../models/preferencia_categoria.dart';
import '../screens/home_conocimiento_screen.dart';
import '../screens/onboarding_categorias_screen.dart';
import '../services/api_service_conocimiento.dart';
import 'error_carga.dart';

/// Punto de entrada único tras login y tras restaurar sesión. Decide contra
/// el backend, no contra ningún flag local — "cuenta recién creada" y "ya
/// eligió categorías en esta app" son cosas distintas cuando la cuenta se
/// comparte entre apps del ecosistema: alguien puede abrir Conocimiento por
/// primera vez con una cuenta antigua de Hábitos.
///
/// La señal sale gratis del propio backend: `PreferenciaCategoriaService`
/// garantiza que en cuanto el onboarding se completa una vez queda al menos
/// una categoría en QUIERE. Así que "cero en QUIERE" es sinónimo exacto de
/// "todavía no ha hecho el onboarding de esta app".
///
/// Es `StatefulWidget` y no `StatelessWidget` porque el `Future` tiene que
/// sobrevivir a los repintados: `MaterialApp` escucha `temaEquipadoNotifier`,
/// y crearlo dentro de `build()` dispararía una llamada nueva cada vez que
/// cambia el tema equipado.
class PortalConocimiento extends StatefulWidget {
  const PortalConocimiento({super.key});

  @override
  State<PortalConocimiento> createState() => _PortalConocimientoState();
}

class _PortalConocimientoState extends State<PortalConocimiento> {
  late Future<List<PreferenciaCategoria>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ApiServiceConocimiento.getPreferencias();
  }

  void _reintentar() {
    setState(() => _futuro = ApiServiceConocimiento.getPreferencias());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PreferenciaCategoria>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          // Sin conexión al arrancar: no se puede decidir nada, pero tampoco
          // se debe dejar a alguien atascado en una rueda infinita.
          return Scaffold(
            body: ErrorCarga(error: snapshot.error!, onReintentar: _reintentar),
          );
        }
        final yaEligio = snapshot.data!.any((p) => p.estado == 'QUIERE');
        return yaEligio
            ? const HomeConocimientoScreen()
            : const OnboardingCategoriasScreen();
      },
    );
  }
}
