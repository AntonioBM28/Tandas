import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/circular_safe_area.dart';
import '../providers/vinculacion_state.dart';

/// Se muestra cuando el reloj todavía no tiene sesión. Pide un código al
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
      body: CircularSafeArea(
        child: Consumer<VinculacionState>(
          builder: (context, state, _) {
            if (state.vinculado) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onVinculado();
              });
            }

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.watch_outlined, color: AppColors.primaryText, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    'Abre Tandas en tu celular y escribe:',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  if (state.cargando && state.codigo == null)
                    const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText)
                  else if (state.error != null) ...[
                    Text(
                      state.error!,
                      style: AppTextStyles.body.copyWith(color: AppColors.statusLate),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => context.read<VinculacionState>().iniciar(),
                      child: const Text('Reintentar'),
                    ),
                  ] else if (state.codigo != null)
                    Text(
                      state.codigo!,
                      style: AppTextStyles.title.copyWith(fontSize: 26, letterSpacing: 4),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
