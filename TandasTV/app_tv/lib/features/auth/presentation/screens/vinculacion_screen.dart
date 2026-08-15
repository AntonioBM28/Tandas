import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/vinculacion_state.dart';

/// Se muestra cuando la TV todavía no tiene sesión. Pide un código al
/// backend y espera a que lo confirmen desde el celular.
class VinculacionScreen extends StatefulWidget {
  final VoidCallback onVinculado;

  const VinculacionScreen({super.key, required this.onVinculado});

  @override
  State<VinculacionScreen> createState() => _VinculacionScreenState();
}

class _VinculacionScreenState extends State<VinculacionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VinculacionState>().iniciar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<VinculacionState>(
          builder: (context, state, _) {
            if (state.vinculado) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onVinculado();
              });
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tv_outlined, color: AppColors.primary, size: 72),
                    const SizedBox(height: 24),
                    const Text(
                      'Vincula esta TV',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Abre Tandas en tu celular, toca el ícono de TV y escribe este código:',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (state.cargando && state.codigo == null)
                      const CircularProgressIndicator(color: AppColors.primary)
                    else if (state.error != null) ...[
                      Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.statusLate, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        autofocus: true,
                        onPressed: () => context.read<VinculacionState>().iniciar(),
                        child: const Text('Reintentar', style: TextStyle(fontSize: 20)),
                      ),
                    ] else if (state.codigo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Text(
                          state.codigo!,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'El código expira en 10 minutos.',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
