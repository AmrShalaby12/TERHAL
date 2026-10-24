part of '../app.dart';

Future<bool> openExternalLink(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) {
    return false;
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8F6F2),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F6F2), Color(0xFFFCFBF8)],
          ),
        ),
        child: child,
      ),
    );
  }
}

class HeaderBlock extends StatelessWidget {
  const HeaderBlock({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF72798D),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[trailing!],
      ],
    );
  }
}

/// Stable app navigation surface with a clear content boundary.
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7E1DC))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F17181B),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// Production content surface. The historic class name is kept so feature
/// pages do not need to know about the visual-system migration.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 18.0,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: br,
        border: Border.all(color: const Color(0xFFE7E1DC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17181B),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF72798D)),
        ),
      ],
    );
  }
}

class BadgeAvatar extends StatelessWidget {
  const BadgeAvatar({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFA61C1C),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'رقم الطالب',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact initials avatar used in operational headers.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.accent});

  final String name;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? const Color(0xFF72131B);
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        _initialsOf(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

/// Extract up to two display initials from an Arabic or Latin full name.
/// Falls back to a single neutral mark when the name is empty.
String _initialsOf(String name) {
  final cleaned = name.trim();
  if (cleaned.isEmpty) return '•';
  final parts = cleaned
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '•';
  if (parts.length == 1) {
    final s = parts.first;
    return s.characters.take(1).toString().toUpperCase();
  }
  final first = parts.first.characters.take(1).toString();
  final last = parts.last.characters.take(1).toString();
  return (first + last).toUpperCase();
}

class HeroTripCard extends StatelessWidget {
  const HeroTripCard({
    super.key,
    required this.studentCode,
    this.booking,
    this.onTrack,
  });

  final String studentCode;
  final BookingModel? booking;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final activeBooking = booking;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFFBF1E23), Color(0xFF7B0F12), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2AA61C1C),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terhal Student Pass',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: $studentCode',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/terhal2.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (activeBooking == null)
            Text(
              'لا توجد رحلة نشطة اليوم.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            )
          else ...[
            Text(
              activeBooking.trip.route.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${activeBooking.trip.route.originName} → ${activeBooking.trip.route.destinationName}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _WhiteMetric(
                      label: 'الانطلاق',
                      value: formatTime(activeBooking.trip.departureTime),
                    ),
                  ),
                  Expanded(
                    child: _WhiteMetric(
                      label: 'الحافلة',
                      value: activeBooking.trip.bus.code,
                    ),
                  ),
                  Expanded(
                    child: _WhiteMetric(
                      label: 'المقعد',
                      value: activeBooking.seatNumber.isEmpty
                          ? '--'
                          : activeBooking.seatNumber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatusChip(
                    label: activeBooking.trip.statusAr,
                    color: const Color(0xFF17A267),
                    inverted: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onTrack,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFA61C1C),
                    ),
                    icon: const Icon(Icons.location_searching_rounded),
                    label: const Text('متابعة الرحلة'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MiniBookingCard extends StatelessWidget {
  const MiniBookingCard({
    super.key,
    required this.title,
    required this.booking,
    required this.accent,
  });

  final String title;
  final BookingModel? booking;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusChip(
                label: booking == null ? 'غير محجوز' : booking!.trip.statusAr,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            booking?.trip.route.destinationName ?? 'لم يتم اختيار رحلة بعد',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            booking == null ? '--' : formatTime(booking!.trip.departureTime),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class QuickTile extends StatelessWidget {
  const QuickTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFFA61C1C)),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF72798D)),
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EDEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7D2D4)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF72131B),
            child: Icon(Icons.shield_outlined, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'سلامتك تهمنا. في حالة الطوارئ تواصل فورًا مع المشرف أو الدعم الفني.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4F0D13),
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TripListCard extends StatelessWidget {
  const TripListCard({super.key, required this.trip, this.footer});

  final TripModel trip;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.route.originName} → ${trip.route.destinationName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF72798D),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(
                    label: trip.directionAr,
                    color: trip.isDeparture
                        ? const Color(0xFF17A267)
                        : const Color(0xFFFFA53B),
                  ),
                  if (trip.price != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${trip.price!.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        color: Color(0xFF72131B),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InfoMetric(
                  label: 'الكود',
                  value: trip.tripCode,
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InfoMetric(
                  label: 'الوقت',
                  value: formatTime(trip.departureTime),
                  icon: Icons.access_time_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InfoMetric(
                  label: 'السائق',
                  value: trip.driverName,
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InfoMetric(
                  label: 'الحافلة',
                  value: trip.bus.code,
                  icon: Icons.directions_bus_rounded,
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.inverted = false,
  });

  final String label;
  final Color color;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: inverted
            ? Colors.white.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: inverted ? Colors.white : color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class InfoMetric extends StatelessWidget {
  const InfoMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE7E1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFECEC),
            child: Icon(icon, size: 18, color: const Color(0xFFA61C1C)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF72798D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFFFECEC),
          child: Icon(icon, color: const Color(0xFFA61C1C)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF72798D)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFA61C1C)),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF72798D)),
          ),
        ],
      ),
    );
  }
}

class MetricPanel extends StatelessWidget {
  const MetricPanel({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.auto_graph_rounded, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF72798D)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _WhiteMetric extends StatelessWidget {
  const _WhiteMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFECEC),
            child: Text(
              title.characters.first,
              style: const TextStyle(
                color: Color(0xFFA61C1C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  textDirection: ui.TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFF475467),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RouteMapPainter extends CustomPainter {
  RouteMapPainter({required this.routePoints, required this.travelledPoints});

  final List<GeoPoint> routePoints;
  final List<GeoPoint> travelledPoints;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF8F9FD), Color(0xFFEFF2FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()..color = const Color(0xFFE1E6F1);
    for (double x = 0; x < size.width; x += 38) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint..strokeWidth = 1,
      );
    }
    for (double y = 0; y < size.height; y += 38) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint..strokeWidth = 1,
      );
    }

    final mappedRoute = _mapPoints(routePoints, size);
    final mappedTravelled = _mapPoints(
      travelledPoints.isEmpty ? routePoints : travelledPoints,
      size,
    );
    if (mappedRoute.length < 2) {
      return;
    }

    final basePath = Path()..moveTo(mappedRoute.first.dx, mappedRoute.first.dy);
    for (final point in mappedRoute.skip(1)) {
      basePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      basePath,
      Paint()
        ..color = const Color(0xFFCCD3E2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    final progressPath = Path()
      ..moveTo(mappedTravelled.first.dx, mappedTravelled.first.dy);
    for (final point in mappedTravelled.skip(1)) {
      progressPath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      progressPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF4B4B), Color(0xFFA61C1C)],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      mappedRoute.first,
      10,
      Paint()..color = const Color(0xFF17A267),
    );
    canvas.drawCircle(
      mappedRoute.last,
      10,
      Paint()..color = const Color(0xFF087B66),
    );
    final busPoint = mappedTravelled.last;
    canvas.drawCircle(busPoint, 18, Paint()..color = Colors.white);
    canvas.drawCircle(busPoint, 12, Paint()..color = const Color(0xFFA61C1C));
  }

  List<Offset> _mapPoints(List<GeoPoint> points, Size size) {
    if (points.isEmpty) {
      return [
        Offset(size.width * 0.18, size.height * 0.7),
        Offset(size.width * 0.82, size.height * 0.3),
      ];
    }
    final minLat = points.map((p) => p.lat).reduce(math.min);
    final maxLat = points.map((p) => p.lat).reduce(math.max);
    final minLng = points.map((p) => p.lng).reduce(math.min);
    final maxLng = points.map((p) => p.lng).reduce(math.max);
    return points.map((point) {
      final dx =
          ((point.lng - minLng) /
                  ((maxLng - minLng).abs() < 0.0001 ? 1 : (maxLng - minLng))) *
              (size.width * 0.72) +
          size.width * 0.14;
      final dy =
          ((point.lat - minLat) /
                  ((maxLat - minLat).abs() < 0.0001 ? 1 : (maxLat - minLat))) *
              (size.height * 0.66) +
          size.height * 0.14;
      return Offset(dx, size.height - dy);
    }).toList();
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) {
    return oldDelegate.routePoints != routePoints ||
        oldDelegate.travelledPoints != travelledPoints;
  }
}

String formatTime(String raw) {
  try {
    final normalized = raw.length == 5 ? '$raw:00' : raw;
    final parsed = DateFormat('HH:mm:ss').parse(normalized);
    return DateFormat('HH:mm').format(parsed);
  } catch (_) {
    return raw;
  }
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return '--';
  }
  final value = DateFormat('dd/MM/yyyy • HH:mm').format(dateTime.toLocal());
  // Keep the numeric date/time in a stable left-to-right order when it is
  // embedded in Arabic text.
  return '\u2066$value\u2069';
}

extension TripUi on TripModel {
  String get directionAr => isDeparture ? 'ذهاب' : 'عودة';

  String get statusAr {
    switch (status) {
      case 'boarding':
        return 'جارٍ الصعود';
      case 'in_progress':
        return 'في الطريق';
      case 'completed':
        return 'مكتملة';
      case 'scheduled':
        return 'مجدولة';
      case 'delayed':
        return 'متأخرة';
      default:
        return status;
    }
  }
}

IconData _notificationIcon(String type) {
  switch (type) {
    case 'trip':
      return Icons.directions_bus_rounded;
    case 'payment':
      return Icons.account_balance_wallet_outlined;
    case 'safety':
      return Icons.shield_outlined;
    default:
      return Icons.notifications_none_rounded;
  }
}
