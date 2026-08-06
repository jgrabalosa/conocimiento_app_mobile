import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/preferencia_categoria.dart';
import '../services/api_service_conocimiento.dart';
import '../widgets/error_carga.dart';
import '../widgets/tarjeta_categoria.dart';

/// El perfil del lector: arriba lo de dominio —qué categorías le interesan—,
/// abajo los accesos a lo demás.
///
/// La cuenta en sí (nombre, email, contraseña, idioma, zona, borrar cuenta)
/// no se reconstruye: `PerfilScreen` del motor ya es enteramente genérica, sin
/// una línea de dominio, así que se reutiliza tal cual como una pantalla más
/// a la que se llega desde aquí.
class PerfilUsuarioLectorScreen extends StatefulWidget {
  /// Costuras de test, mismo criterio que en el resto de pantallas:
  /// `ApiServiceCore.cliente` es `final` y no hay dónde meter un cliente
  /// falso sin tocar el paquete. En producción nadie pasa esto.
  final Future<List<PreferenciaCategoria>> Function()? cargarPreferencias;
  final Future<List<PreferenciaCategoria>> Function(List<PreferenciaCategoria>)?
      guardarPreferencias;

  const PerfilUsuarioLectorScreen({
    super.key,
    this.cargarPreferencias,
    this.guardarPreferencias,
  });

  @override
  State<PerfilUsuarioLectorScreen> createState() =>
      _PerfilUsuarioLectorScreenState();
}

class _PerfilUsuarioLectorScreenState extends State<PerfilUsuarioLectorScreen> {
  /// A diferencia del Onboarding, aquí se parte de lo que el usuario ya
  /// eligió, no de un estado en blanco. `getPreferencias()` ya trae nombre,
  /// icono y color de cada categoría, así que no hace falta el catálogo
  /// aparte.
  List<PreferenciaCategoria>? _preferencias;
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final p =
          await (widget.cargarPreferencias ?? ApiServiceConocimiento.getPreferencias)();
      if (!mounted) return;
      setState(() {
        _preferencias = p;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Aquí no hay botón de Continuar: cada cambio se guarda al momento.
  ///
  /// La regla de "al menos una en QUIERE" se comprueba **antes** de tocar
  /// nada, sobre la lista que quedaría. Bloquear el cambio es distinto de
  /// dejar que el backend lo rechace con un 400: así el selector nunca llega
  /// a enseñar un estado que no existe.
  Future<void> _cambiar(PreferenciaCategoria categoria, String nuevoEstado) async {
    final anteriores = _preferencias!;
    final resultante = [
      for (final p in anteriores)
        p.categoriaId == categoria.categoriaId ? p.conEstado(nuevoEstado) : p,
    ];

    if (!resultante.any((p) => p.estado == estadoQuiere)) {
      _avisar('Debes mantener al menos una categoría en «Sí»');
      return;
    }

    setState(() => _preferencias = resultante);
    try {
      await (widget.guardarPreferencias ??
          ApiServiceConocimiento.actualizarPreferencias)(resultante);
    } catch (e) {
      if (!mounted) return;
      // Se revierte: nadie debe quedarse viendo un cambio que no se guardó.
      setState(() => _preferencias = anteriores);
      _avisar(MensajesError.de(context, e,
          generico: 'No se pudo guardar el cambio.'));
    }
  }

  /// El `usuarioId` sale de donde ya lo lee el splash: no hay una segunda
  /// fuente que pueda desincronizarse.
  Future<void> _abrirCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId');
    if (!mounted) return;
    if (usuarioId == null) {
      _avisar('No se pudo abrir tu cuenta. Vuelve a iniciar sesión.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilScreen(
          usuarioId: usuarioId,
          destinoTrasLogin: destinoTrasLogin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _cuerpo(t),
    );
  }

  Widget _cuerpo(TokensContextuales t) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ErrorCarga(error: _error!, onReintentar: _cargar);
    }

    final preferencias = _preferencias!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tus intereses',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: t.text)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cada cambio se guarda solo. Tiene que quedar al menos una en «Sí».',
                style: TextStyle(fontSize: 12, color: t.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
        for (final p in preferencias)
          TarjetaCategoria(
            key: ValueKey(p.categoriaId),
            nombre: p.nombre,
            icono: p.icono,
            color: p.color,
            estado: p.estado,
            onCambio: (nuevo) => _cambiar(p, nuevo),
          ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Icon(LucideIcons.userRound, color: t.text),
                title: Text('Cuenta', style: TextStyle(color: t.text)),
                subtitle: Text('Datos, idioma, zona horaria y contraseña',
                    style: TextStyle(fontSize: 12, color: t.textMuted)),
                trailing:
                    Icon(LucideIcons.chevronRight, size: 18, color: t.textMuted),
                onTap: _abrirCuenta,
              ),
              // El hueco de lo que viene. Sin flecha ni nada que insinúe que
              // se puede entrar: `enabled: false` ya los deja atenuados y sin
              // onTap.
              const _FilaProximamente(
                  icono: LucideIcons.store, titulo: 'Tienda'),
              const _FilaProximamente(
                  icono: LucideIcons.pawPrint, titulo: 'Mascota'),
              const _FilaProximamente(
                  icono: LucideIcons.medal, titulo: 'Logros'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaProximamente extends StatelessWidget {
  final IconData icono;
  final String titulo;

  const _FilaProximamente({required this.icono, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return ListTile(
      enabled: false,
      leading: Icon(icono, color: t.textMuted),
      title: Text(titulo, style: TextStyle(color: t.textMuted)),
      trailing: Chip(
        label: const Text('Próximamente'),
        labelStyle: TextStyle(fontSize: 11, color: t.textMuted),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
