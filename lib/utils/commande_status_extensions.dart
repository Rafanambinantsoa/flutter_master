import 'package:flutter/material.dart';

import '../models/commande.dart';

extension CommandeStatusView on CommandeStatus {
  String get displayLabel {
    switch (this) {
      case CommandeStatus.enCours:
        return 'En cours';
      case CommandeStatus.enAttente:
        return 'En attente';
      case CommandeStatus.terminee:
        return 'Terminée';
      case CommandeStatus.annulee:
        return 'Annulée';
    }
  }

  Color get displayColor {
    switch (this) {
      case CommandeStatus.enCours:
        return Colors.orange;
      case CommandeStatus.enAttente:
        return Colors.blue;
      case CommandeStatus.terminee:
        return Colors.green;
      case CommandeStatus.annulee:
        return Colors.red;
    }
  }
}

