import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'consts.dart';
import 'data/database.dart';
import 'data/baking_pan_repository.dart';
import 'data/preferences_repository.dart';
import 'data/preset_repository.dart';
import 'data/photo_storage.dart';
import 'home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[Impasta] main() start');
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const Impasta());
}

class Impasta extends StatefulWidget {
  const Impasta({super.key});

  @override
  State<Impasta> createState() => _ImpastaState();
}

class _ImpastaState extends State<Impasta> {
  late Future<
      ({
        PresetRepository presetRepo,
        BakingPanRepository panRepo,
        PreferencesRepository prefsRepo,
        Locale? savedLocale,
      })> _initFuture;

  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<
      ({
        PresetRepository presetRepo,
        BakingPanRepository panRepo,
        PreferencesRepository prefsRepo,
        Locale? savedLocale,
      })> _init() async {
    try {
      debugPrint('[Impasta] _init start');
      final results = await Future.wait([
        openAppDatabase(),
        initPhotoStorage(),
      ]);
      final db = results[0] as Database;
      debugPrint('[Impasta] DB opened');
      final presetRepo = PresetRepository(db);
      final panRepo = BakingPanRepository(db);
      final prefsRepo = PreferencesRepository(db);
      final savedLocaleStr = await prefsRepo.getLocale();
      final savedLocale = savedLocaleStr != null ? Locale(savedLocaleStr) : null;
      debugPrint('[Impasta] Repositories ready, locale=$savedLocaleStr');
      return (
        presetRepo: presetRepo,
        panRepo: panRepo,
        prefsRepo: prefsRepo,
        savedLocale: savedLocale,
      );
    } catch (e, st) {
      debugPrint('[Impasta] init error: $e');
      debugPrint('[Impasta] $st');
      rethrow;
    }
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        final locale = _locale ?? snapshot.data?.savedLocale;
        return MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: secondaryColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: secondaryColor,
            textTheme: TextTheme(
              displayLarge: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
              titleLarge: GoogleFonts.oswald(
                fontSize: 30,
              ),
              bodyMedium: GoogleFonts.robotoSerif(),
              displaySmall: GoogleFonts.robotoSerif(),
            ),
          ),
          home: snapshot.hasData
              ? Home(
                  presetRepository: snapshot.data!.presetRepo,
                  bakingPanRepository: snapshot.data!.panRepo,
                  preferencesRepository: snapshot.data!.prefsRepo,
                  onLocaleChanged: _setLocale,
                )
              : snapshot.hasError
                  ? Scaffold(
                      body: Center(
                        child: Builder(
                          builder: (ctx) {
                            final l10n = AppLocalizations.of(ctx);
                            return Text(
                              l10n?.dbError(snapshot.error.toString()) ??
                                  'DB error: ${snapshot.error}',
                              style: const TextStyle(
                                  color: primaryColor, fontSize: 16),
                            );
                          },
                        ),
                      ),
                    )
                  : const Scaffold(
                      body: Center(
                        child:
                            CircularProgressIndicator(color: primaryColor),
                      ),
                    ),
        );
      },
    );
  }
}
