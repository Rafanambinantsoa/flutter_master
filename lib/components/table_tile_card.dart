import 'package:flutter/material.dart';
import '../models/table.dart';

class TableTileCard extends StatelessWidget {
  final DiningTable table;
  final VoidCallback onTap;
  final bool isAvailable; // Disponibilité dynamique

  const TableTileCard({
    super.key,
    required this.table,
    required this.onTap,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 160;
        final bool useDark = !isAvailable;
        final Color base = useDark ? const Color(0xFF111111) : Colors.white;
        final Color fg = useDark ? Colors.white : Colors.black;
        final Color accent = !isAvailable
            ? Colors.redAccent
            : Color.fromARGB(255, 97, 94, 94);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (useDark ? Colors.white : Colors.black).withOpacity(
                  0.08,
                ),
              ),
              boxShadow: [
                if (!useDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            // Micro-optimisation: réduit légèrement la hauteur pour
            // éviter le débordement sub-pixel sur petits écrans.
            padding: EdgeInsets.all(isCompact ? 7 : 11),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(useDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withOpacity(0.55),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'T${table.number}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: isCompact ? 11 : 12,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.north_east,
                      size: 16,
                      color: fg.withOpacity(0.8),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 4 : 7),
                Text(
                  'Table ${table.number}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: isCompact ? 1 : 3),
                Row(
                  // Sur petits écrans, on force les chips sur une seule ligne
                  // pour éviter les débordements verticaux.
                  children: [
                    Flexible(
                      child: _MiniChip(
                        label: 'Cap. ${table.capacity}',
                        dark: useDark,
                      ),
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    Flexible(
                      child: _MiniChip(
                        label: isAvailable ? 'Disponible' : 'Indisponible',
                        color: accent,
                        dark: useDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool dark;

  const _MiniChip({required this.label, this.color, required this.dark});

  @override
  Widget build(BuildContext context) {
    final Color textColorBase = dark ? Colors.white : Colors.black;
    final Color fg = color ?? textColorBase;
    final Color bg = color != null
        ? color!.withOpacity(dark ? 0.18 : 0.12)
        : (dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
