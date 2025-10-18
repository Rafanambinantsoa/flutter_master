import 'package:flutter/material.dart';
import '../models/table.dart';

class TableTileCard extends StatelessWidget {
  final DiningTable table;
  final VoidCallback onTap;

  const TableTileCard({super.key, required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 160;
        final bool useDark = table.isOccupied;
        final Color base = useDark ? const Color(0xFF111111) : Colors.white;
        final Color fg = useDark ? Colors.white : Colors.black;
        final Color accent = table.isOccupied
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
            padding: EdgeInsets.all(isCompact ? 10 : 12),
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
                SizedBox(height: isCompact ? 6 : 8),
                Text(
                  'Table ${table.number}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: isCompact ? 2 : 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniChip(label: 'Cap. ${table.capacity}', dark: useDark),
                    _MiniChip(
                      label: table.isOccupied ? 'Occupée' : 'Libre',
                      color: accent,
                      dark: useDark,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
