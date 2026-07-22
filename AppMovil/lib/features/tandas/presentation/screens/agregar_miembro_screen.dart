import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/tanda_detalle_provider.dart';

class AgregarMiembroScreen extends StatefulWidget {
  final String id;
  const AgregarMiembroScreen({super.key, required this.id});

  @override
  State<AgregarMiembroScreen> createState() => _AgregarMiembroScreenState();
}

class _AgregarMiembroScreenState extends State<AgregarMiembroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _agregarMiembro() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      
      final provider = context.read<TandaDetalleProvider>();
      final email = _emailController.text.trim().toLowerCase();
      
      final success = await provider.invitarMiembro(widget.id, email);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Miembro agregado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Error al agregar miembro'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TandaDetalleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Miembro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ingresa el correo con el que la persona está registrada en Tandas',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Buscar y agregar',
                  onPressed: _agregarMiembro,
                  isLoading: provider.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
