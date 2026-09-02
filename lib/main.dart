import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/portal_conocimiento.dart';
import 'widgets/splash_conocimiento.dart';

void main() {
  // El motor manda esto en la cabecera X-Norday-App: es lo que le dice al
  // backend de qué app son los catálogos que pide.
  ApiServiceCore.appId = 'conocimiento';
  // Las nueve familias van empaquetadas en google_fonts/. Sin esto el paquete
  // se las baja por HTTP en el primer arranque: la app se ve con la fuente por
  // defecto hasta que llegan, y sin red no llegan nunca.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ConocimientoApp());
}

class ConocimientoApp extends StatelessWidget {
  const ConocimientoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TokensContextuales>(
      valueListenable: temaEquipadoNotifier,
      builder: (context, tema, _) {
        return MaterialApp(
          // El del paquete, no uno propio: CelebracionService lo necesita.
          navigatorKey: nordayNavigatorKey,
          title: 'Norday Conocimiento',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.deTema(tema),
          // Español fijo: esta app no tiene selector de idioma. El delegate del
          // motor sigue haciendo falta porque sus pantallas compartidas
          // (LoginScreen y compañía) sacan de ahí sus textos.
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: const [
            NordayCoreLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// El tema equipado no se puede cargar en `main()`: antes del login no hay
  /// ni usuarioId ni token. Va aquí, cuando ya hay sesión guardada.
  Future<String?> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;
    final usuarioId = prefs.getInt('usuarioId');
    if (usuarioId != null) {
      await Equipamiento.cargarDeUsuarioSiSePuede(usuarioId);
    }
    return token;
  }

  @override
  Widget build(BuildContext context) {
    return SplashConocimiento<String?>(
      colorFondo: const Color(0xFF0A1628),
      wordmark: 'Norday Conocimiento',
      tarea: _checkSession,
      onListo: (context, token) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => token != null
                ? const PortalConocimiento()
                : const LoginScreen(destinoTrasLogin: destinoTrasLogin),
          ),
        );
      },
    );
  }
}

/// Adónde va el motor cuando la sesión ya es buena. `LoginScreen` no puede
/// conocer las pantallas de esta app, así que se las enchufamos desde aquí.
///
/// `mostrarOnboarding` se ignora a propósito: significa "la cuenta se acaba de
/// crear", no "este usuario ya configuró sus categorías en esta app", y con
/// una cuenta compartida entre apps del ecosistema no son lo mismo. Quien lo
/// decide es [PortalConocimiento], preguntándoselo al backend. El parámetro
/// se queda porque la firma la exige `LoginScreen`.
Widget destinoTrasLogin(BuildContext context, bool mostrarOnboarding) =>
    const PortalConocimiento();

