import 'package:flutter/material.dart';
import '../services/reservation_service.dart';
import 'client_selection_screen.dart';

class ReservationLookupScreen extends StatefulWidget {
  final ClientType? clientType;

  const ReservationLookupScreen({super.key, this.clientType});

  @override
  State<ReservationLookupScreen> createState() =>
      _ReservationLookupScreenState();
}

class _ReservationLookupScreenState extends State<ReservationLookupScreen> {
  final TextEditingController _codeController = TextEditingController();
  final ReservationService _reservationService = ReservationService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupReservation() async {
    final code = _codeController.text.trim();

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
      final reservation = await _reservationService.searchByCode(code);

      if (!mounted) return;

      // Navigation vers l'écran de détails de réservation
      Navigator.of(context).pushNamed(
        '/reservation-detail',
        arguments: {'reservation': reservation},
      );
    } on ReservationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur est survenue: ${e.toString()}';
        //log the error
        debugPrint('Error: ${e.toString()}');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String typeText;
    if (widget.clientType == null) {
      typeText = '';
    } else if (widget.clientType == ClientType.standardReservation) {
      typeText = 'standard';
    } else {
      typeText = 'avec menu prépayé';
    }

    final appBarTitle = typeText.isEmpty
        ? 'Recherche de réservation'
        : 'Réservation $typeText';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle), centerTitle: true),
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
