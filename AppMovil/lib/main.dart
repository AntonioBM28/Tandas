import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/tandas/domain/repositories/tandas_repository.dart';
import 'features/tandas/presentation/providers/tandas_provider.dart';
import 'features/tandas/domain/repositories/tanda_detalle_repository.dart';
import 'features/tandas/presentation/providers/tanda_detalle_provider.dart';

void main() {
  final storageService = SecureStorageService();
  final dioClient = DioClient(storageService);
  final authRepository = AuthRepository(dioClient, storageService);
  final tandasRepository = TandasRepository(dioClient);
  final tandaDetalleRepository = TandaDetalleRepository(dioClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => TandasProvider(tandasRepository)),
        ChangeNotifierProvider(create: (_) => TandaDetalleProvider(tandaDetalleRepository)),
      ],
      child: const AppMovil(),
    ),
  );
}

class AppMovil extends StatelessWidget {
  const AppMovil({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tandas App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
