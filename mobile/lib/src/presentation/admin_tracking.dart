part of '../app.dart';

class AdminCompanionScreen extends ConsumerWidget {
  const AdminCompanionScreen({super.key});

  static const dashboardUrl = String.fromEnvironment('DASHBOARD_URL');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7EDEE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: Color(0xFF72131B),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'بوابة إدارة ترحال',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'مساحة عمل الإدارة والتشغيل',
                                  style: TextStyle(color: Color(0xFF667085)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'استخدم لوحة الويب لإدارة الطلاب والرحلات والحضور والرسائل من مكان واحد.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      const _AdminCapability(
                        icon: Icons.route_outlined,
                        title: 'إدارة الرحلات والأسطول',
                      ),
                      const _AdminCapability(
                        icon: Icons.fact_check_outlined,
                        title: 'متابعة الحضور والتقارير',
                      ),
                      const _AdminCapability(
                        icon: Icons.campaign_outlined,
                        title: 'إرسال الرسائل والتنبيهات',
                      ),
                      const SizedBox(height: 18),
                      if (dashboardUrl.isNotEmpty)
                        const _LinkTile(
                          title: 'رابط لوحة الإدارة',
                          value: dashboardUrl,
                        )
                      else
                        const SafetyBanner(),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              ref.read(sessionProvider.notifier).logout(),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('تسجيل الخروج'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminCapability extends StatelessWidget {
  const _AdminCapability({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF087B66)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Color(0xFF087B66),
          ),
        ],
      ),
    );
  }
}

class TripTrackingScreen extends ConsumerWidget {
  const TripTrackingScreen({super.key, required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة الرحلة')),
      body: AppBackground(
        child: FutureBuilder<TrackingPayload>(
          future: ref.read(sessionProvider.notifier).trackingForTrip(trip.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final tracking = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/terhal4.png',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF1A0303).withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        bottom: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.satellite_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'متابعة لحظية',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GlassCard(
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
                                  tracking.trip.route.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${tracking.trip.route.originName} → ${tracking.trip.route.destinationName}',
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            label: tracking.trip.bus.code,
                            color: const Color(0xFFA61C1C),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 280,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: CustomPaint(
                            painter: RouteMapPainter(
                              routePoints: tracking.routePoints,
                              travelledPoints: tracking.timeline,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: InfoMetric(
                              label: 'الانطلاق',
                              value: formatTime(tracking.trip.departureTime),
                              icon: Icons.play_circle_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InfoMetric(
                              label: 'الوصول المتوقع',
                              value: formatTime(
                                tracking.trip.scheduledArrivalTime,
                              ),
                              icon: Icons.flag_circle_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
