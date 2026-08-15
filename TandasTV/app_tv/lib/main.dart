import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/vinculacion_state.dart';
import 'features/auth/presentation/screens/vinculacion_screen.dart';
import 'features/tandas/domain/repositories/tandas_tv_repository.dart';
import 'features/tandas/presentation/providers/pantalla_publica_state.dart';
import 'features/tandas/presentation/providers/seleccion_tandas_state.dart';
import 'features/tandas/presentation/screens/seleccionar_tanda_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = SecureStorageService();
  final dioClient = DioClient(storageService);
  final authRepository = AuthRepository(dioClient, storageService);
  final tandasRepository = TandasTvRepository(dioClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>(create: (_) => storageService),
        ChangeNotifierProvider(create: (_) => VinculacionState(authRepository)),
        ChangeNotifierProvider(create: (_) => SeleccionTandasState(tandasRepository)),
        ChangeNotifierProvider(create: (_) => PantallaPublicaState(tandasRepository)),
      ],
      child: const AppTv(),
    ),
  );
}

class AppTv extends StatelessWidget {
  const AppTv({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tandas TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surface: AppColors.surface,
        ),
        useMaterial3: true,
      ),
      home: const RaizScreen(),
    );
  }
}

/// Decide si mostrar la pantalla de vinculación (sin sesión) o la selección
/// de tandas (ya con sesión guardada de una vinculación anterior).
class RaizScreen extends StatefulWidget {
  const RaizScreen({super.key});

  @override
  State<RaizScreen> createState() => _RaizScreenState();
}

class _RaizScreenState extends State<RaizScreen> {
  bool? _tieneSesion; // null mientras se revisa el storage

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final storage = context.read<SecureStorageService>();
    final token = await storage.getToken();
    if (!mounted) return;
    setState(() => _tieneSesion = token != null);
  }

  void _onVinculado() {
    setState(() => _tieneSesion = true);
  }

  Future<void> _cerrarSesion() async {
    final storage = context.read<SecureStorageService>();
    await storage.clearTokens();
    if (!mounted) return;
    context.read<PantallaPublicaState>().detener();
    setState(() => _tieneSesion = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_tieneSesion == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_tieneSesion == false) {
      return VinculacionScreen(onVinculado: _onVinculado);
    }
    return SeleccionarTandaScreen(onCerrarSesion: _cerrarSesion);
  }
}
