import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app_tv/core/network/dio_client.dart';
import 'package:app_tv/core/storage/secure_storage_service.dart';
import 'package:app_tv/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_tv/features/auth/presentation/providers/vinculacion_state.dart';
import 'package:app_tv/features/tandas/domain/repositories/tandas_tv_repository.dart';
import 'package:app_tv/features/tandas/presentation/providers/pantalla_publica_state.dart';
import 'package:app_tv/features/tandas/presentation/providers/seleccion_tandas_state.dart';
import 'package:app_tv/main.dart';

void main() {
  testWidgets('La app arranca mostrando el loader inicial sin lanzar excepciones', (WidgetTester tester) async {
    final storageService = SecureStorageService();
    final dioClient = DioClient(storageService);
    final authRepository = AuthRepository(dioClient, storageService);
    final tandasRepository = TandasTvRepository(dioClient);

    await tester.pumpWidget(
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
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
