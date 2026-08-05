import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/vinculacion_state.dart';
import 'features/auth/presentation/screens/vinculacion_screen.dart';
import 'features/dashboard/presentation/screens/main_wear_screen.dart';
import 'features/pagos/domain/repositories/pagos_wear_repository.dart';
import 'features/pagos/presentation/providers/pagos_wear_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = SecureStorageService();
  final dioClient = DioClient(storageService);
  final authRepository = AuthRepository(dioClient, storageService);
  final pagosRepository = PagosWearRepository(dioClient, storageService);

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>(create: (_) => storageService),
        ChangeNotifierProvider(create: (_) => VinculacionState(authRepository)),
        ChangeNotifierProvider(create: (_) => PagosWearState(pagosRepository)),
      ],
      child: const AppWear(),
    ),
  );
}

class AppWear extends StatelessWidget {
  const AppWear({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppWear Tandas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.statusOk,
          secondary: AppColors.statusPending,
          surface: AppColors.background,
        ),
        useMaterial3: true,
      ),
      home: const RaizScreen(),
    );
  }
}

/// Decide si mostrar la pantalla de vinculación (sin sesión) o el dashboard
/// (ya con sesión guardada de una vinculación anterior).
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
    if (token != null) {
      context.read<PagosWearState>().iniciar();
    }
  }

  void _onVinculado() {
    setState(() => _tieneSesion = true);
    context.read<PagosWearState>().iniciar();
  }

  Future<void> _cerrarSesion() async {
    final storage = context.read<SecureStorageService>();
    await storage.clearTokens();
    if (!mounted) return;
    context.read<PagosWearState>().detener();
    setState(() => _tieneSesion = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_tieneSesion == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryText)),
      );
    }
    if (_tieneSesion == false) {
      return VinculacionScreen(onVinculado: _onVinculado);
    }
    return MainWearScreen(onCerrarSesion: _cerrarSesion);
  }
}
