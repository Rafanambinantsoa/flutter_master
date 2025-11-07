import 'package:flutter/material.dart';
import '../services/mock_api_service.dart';
import '../models/reservation.dart';
import 'client_selection_screen.dart';

class ReservationLookupScreen extends StatefulWidget {
  final MockApiService apiService;
  final ClientType clientType;

  const ReservationLookupScreen({
    super.key,
    required this.apiService,
    required this.clientType,
  });

  @override
  State<ReservationLookupScreen> createState() =>
      _ReservationLookupScreenState();
}

class _ReservationLookupScreenState extends State<ReservationLookupScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupReservation() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un code de réservation';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservation = await widget.apiService.getReservationByCode(code);

      if (!mounted) return;

      if (reservation == null) {
        setState(() {
          _errorMessage =
              'Aucune réservation trouvée avec ce code ou réservation non active';
          _isLoading = false;
        });
        return;
      }

      // Vérifier que le type de réservation correspond
      if ((widget.clientType == ClientType.standardReservation &&
              reservation.type != ReservationType.standard) ||
          (widget.clientType == ClientType.prepaidReservation &&
              reservation.type != ReservationType.prepaidMenu)) {
        setState(() {
          _errorMessage =
              'Le type de réservation ne correspond pas à la sélection';
          _isLoading = false;
        });
        return;
      }

      // Navigation vers l'écran de détails de réservation
      Navigator.of(context).pushNamed(
        '/reservation-detail',
        arguments: {'reservation': reservation},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur est survenue: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeText = widget.clientType == ClientType.standardReservation
        ? 'standard'
        : 'avec menu prépayé';

    return Scaffold(
      appBar: AppBar(title: Text('Réservation $typeText'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recherche de réservation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Entrez le code de réservation du client',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Code de réservation',
                hintText: 'Ex: RES001',
                prefixIcon: const Icon(Icons.confirmation_number),
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _lookupReservation(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _lookupReservation,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Rechercher',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
