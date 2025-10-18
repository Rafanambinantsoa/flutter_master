import 'package:flutter/material.dart';
import '../models/table.dart';

class SuggestedTableCard extends StatefulWidget {
  final DiningTable table;
  final VoidCallback onSelect;

  const SuggestedTableCard({
    super.key,
    required this.table,
    required this.onSelect,
  });

  @override
  State<SuggestedTableCard> createState() => _SuggestedTableCardState();
}

class _SuggestedTableCardState extends State<SuggestedTableCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 360;
        final bool useDark =
            widget.table.isOccupied; // dark when occupied, light when free

        return AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _hovering ? 1.03 : 1.0,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: InkWell(
              onTap: widget.onSelect,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                constraints: const BoxConstraints(minHeight: 120),
                decoration: BoxDecoration(
                  color: useDark ? const Color(0xFF111111) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: (useDark ? Colors.white : Colors.black).withOpacity(
                      0.08,
                    ),
                  ),
                  boxShadow: [
                    if (!useDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // subtle circle pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CirclesPainter(isDark: useDark),
                      ),
                    ),
                    // content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _CardContent(
                        table: widget.table,
                        isCompact: isCompact,
                        onSelect: widget.onSelect,
                        maxWidth: constraints.maxWidth,
                        foreground: useDark ? Colors.white : Colors.black,
                        dark: useDark,
                      ),
                    ),
                    // arrow top-right
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(
                        Icons.north_east,
                        size: 18,
                        color: (useDark ? Colors.white : Colors.black)
                            .withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardContent extends StatelessWidget {
  final DiningTable table;
  final bool isCompact;
  final VoidCallback onSelect;
  final double maxWidth;
  final Color foreground;
  final bool dark;

  const _CardContent({
    required this.table,
    required this.isCompact,
    required this.onSelect,
    required this.maxWidth,
    required this.foreground,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = table.isOccupied
        ? Colors.redAccent
        : Color.fromARGB(255, 97, 94, 94);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Badge table
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withOpacity(dark ? 0.18 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.55), width: 2),
              ),
              child: Center(
                child: Text(
                  "T${table.number}",
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Détails
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Table ${table.number}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        label: "Capacité ${table.capacity}",
                        foreground: foreground,
                        dark: dark,
                      ),
                      _InfoChip(
                        label: "Occupée",
                        color: accent,
                        foreground: foreground,
                        dark: dark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bouton
        Align(
          alignment: isCompact ? Alignment.centerLeft : Alignment.centerRight,
          child: SizedBox(
            width: isCompact ? double.infinity : null,
            child: OutlinedButton.icon(
              onPressed: onSelect,
              icon: Icon(Icons.chevron_right, size: 18, color: foreground),
              label: const Text("Sélectionner"),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground.withOpacity(0.9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                backgroundColor: dark ? const Color(0xFF111111) : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? foreground;
  final bool dark;

  const _InfoChip({
    required this.label,
    this.color,
    this.foreground,
    this.dark = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColorBase =
        foreground ?? (dark ? Colors.white : Colors.black);
    final Color fg = color ?? textColorBase;
    final Color bg = color != null
        ? color!.withOpacity(dark ? 0.18 : 0.12)
        : (dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: fg.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CirclesPainter extends CustomPainter {
  final bool isDark;
  const _CirclesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06);

    void drawCircle(Offset c, double r) {
      canvas.drawCircle(c, r, p);
    }

    drawCircle(Offset(size.width * 0.2, size.height * 0.15), size.width * 0.45);
    drawCircle(Offset(size.width * 0.85, size.height * 0.3), size.width * 0.55);
    drawCircle(Offset(size.width * 0.4, size.height * 0.9), size.width * 0.5);
  }

  @override
  bool shouldRepaint(covariant _CirclesPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
