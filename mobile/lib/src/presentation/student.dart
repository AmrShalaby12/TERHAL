part of '../app.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int index = 0;
  final Set<int> _builtTabs = {0};

  void _switchTab(int target) {
    if (target < 0 || target > 5) return;
    setState(() {
      index = target;
      _builtTabs.add(target);
    });
    if (target == 5) unawaited(ref.read(sessionProvider.notifier).refresh());
  }

  void _showSupportSheet() {
    unawaited(ref.read(sessionProvider.notifier).refresh());
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SupportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final pages = [
      StudentHomePage(
        onOpenTracking: _openTracking,
        onSwitchTab: _switchTab,
        onShowSupport: _showSupportSheet,
      ),
      TripsPage(onOpenTracking: _openTracking),
      BookingsPage(onOpenTracking: _openTracking),
      const QrPage(),
      const NotificationsPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: index,
            children: List.generate(
              pages.length,
              (tabIndex) => _builtTabs.contains(tabIndex)
                  ? pages[tabIndex]
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _GlassNavBar(
        child: _StudentNavigation(
          index: index,
          onSelect: _switchTab,
          unread: session.studentHome?.unreadNotifications ?? 0,
        ),
      ),
    );
  }

  void _openTracking(TripModel trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LiveTrackingScreen(trip: trip)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Student Home Page — Liquid Glass redesign
// ═════════════════════════════════════════════════════════════════════════════

// ignore: unused_element
class _LegacyStudentHomePage extends ConsumerWidget {
  const _LegacyStudentHomePage({
    required this.onOpenTracking,
    required this.onSwitchTab,
    required this.onShowSupport,
  });

  final void Function(TripModel trip) onOpenTracking;
  final void Function(int target) onSwitchTab;
  final VoidCallback onShowSupport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final home = state.studentHome;
    final booking = home?.departureBooking ?? home?.returnBooking;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      edgeOffset: 200,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Gradient hero header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _HomeHeroHeader(
              name: home?.name ?? state.user?.fullName ?? '',
              faculty: state.user?.studentProfile?.faculty ?? '',
              academicYear: state.user?.studentProfile?.academicYear ?? '',
              unread: home?.unreadNotifications ?? 0,
              onNotifications: () => onSwitchTab(4),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
            sliver: SliverList.list(
              children: [
                // The Pass card is lifted ~52px so the top edge rests over
                // the bottom curve of the cinematic hero header — gives a
                // premium "ID card on a passport" feel without clipping.
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: _OneShotFadeIn(
                    delay: const Duration(milliseconds: 80),
                    child: _StudentPassCard(
                      name: home?.name ?? state.user?.fullName ?? '',
                      code: home?.code ?? '',
                      booking: booking,
                      onTrack: booking == null
                          ? null
                          : () => onOpenTracking(booking.trip),
                    ),
                  ),
                ),
                // Negative-spacer compensates for the pass card's -52 offset
                // so subsequent content doesn't pile up under it.
                const SizedBox(height: 4),
                // Quick action pills — every button is wired:
                //   QR        → switch to QR tab (index 2)
                //   Track     → live tracking screen (disabled if no booking)
                //   Payments  → switch to Profile tab (index 4) where payments live
                //   Support   → open contact / FAQ bottom sheet
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 160),
                  child: _QuickActionsRow(
                    booking: booking,
                    paymentCount: state.payments.length,
                    onTrack: booking == null
                        ? null
                        : () => onOpenTracking(booking.trip),
                    onOpenQr: () => onSwitchTab(3),
                    onOpenPayments: () => onSwitchTab(5),
                    onOpenSupport: onShowSupport,
                  ),
                ),
                const SizedBox(height: 26),
                // Featured "Track your bus" image-backed card (uses terhal4)
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: _FeatureBannerCard(
                    image: 'assets/images/terhal4.png',
                    eyebrow: 'تتبع حي',
                    title: 'شوف حافلتك على الخريطة',
                    subtitle:
                        'تحديثات لحظية بالموقع والسرعة ووقت الوصول المتوقع.',
                    ctaLabel: booking == null
                        ? 'احجز رحلة لتتبعها'
                        : 'تتبع الرحلة الآن',
                    onTap: booking == null
                        ? null
                        : () => onOpenTracking(booking.trip),
                  ),
                ),
                const SizedBox(height: 28),
                // Section title — Today's trips
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 260),
                  child: const _HomeSectionTitle(
                    title: 'رحلات اليوم',
                    subtitle: 'الذهاب والعودة المسجلة على حسابك.',
                  ),
                ),
                const SizedBox(height: 14),
                // Departure / return mini cards
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 320),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TripMiniCard(
                          label: 'رحلة الذهاب',
                          booking: home?.departureBooking,
                          accent: const Color(0xFF17A267),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TripMiniCard(
                          label: 'رحلة العودة',
                          booking: home?.returnBooking,
                          accent: const Color(0xFFFFA53B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                // Section title — Explore
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 360),
                  child: const _HomeSectionTitle(
                    title: 'استكشف',
                    subtitle: 'وجهات وميزات مختارة لطلبة ترحال.',
                  ),
                ),
                const SizedBox(height: 14),
                // Horizontal discover carousel — image-backed promo cards.
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: const _DiscoverCarousel(),
                ),
                const SizedBox(height: 22),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 460),
                  child: const SafetyBanner(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section title used on the Student home ──────────────────────────────────

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBF1E23), Color(0xFF7B0F12)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF191919),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF72798D),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Featured image-backed banner ────────────────────────────────────────────

class _FeatureBannerCard extends StatelessWidget {
  const _FeatureBannerCard({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.onTap,
  });

  final String image;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background image
            Image.asset(
              image,
              width: double.infinity,
              height: 210,
              fit: BoxFit.cover,
            ),
            // Dark left-to-right gradient so text on the left stays sharp
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1A0303).withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
            // Foreground text + CTA
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Glass eyebrow chip
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFA53B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                eyebrow,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Color(0x66000000), blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ctaLabel,
                                  style: const TextStyle(
                                    color: Color(0xFFA61C1C),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 16,
                                  color: Color(0xFFA61C1C),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Discover carousel ───────────────────────────────────────────────────────

class _DiscoverCarousel extends StatelessWidget {
  const _DiscoverCarousel();

  static const _items = <_DiscoverItem>[
    _DiscoverItem(
      image: 'assets/images/terhal3.png',
      label: 'مجتمع ترحال',
      sub: 'تجمعات طلابية',
      accent: Color(0xFFA61C1C),
    ),
    _DiscoverItem(
      image: 'assets/images/terhal4.png',
      label: 'محطات مميزة',
      sub: 'الجامعة • المطار',
      accent: Color(0xFFFFA53B),
    ),
    _DiscoverItem(
      image: 'assets/images/terhal2.png',
      label: 'أسطول حديث',
      sub: 'حافلات مكيّفة',
      accent: Color(0xFF087B66),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _DiscoverTile(item: _items[i]),
      ),
    );
  }
}

class _DiscoverItem {
  const _DiscoverItem({
    required this.image,
    required this.label,
    required this.sub,
    required this.accent,
  });

  final String image;
  final String label;
  final String sub;
  final Color accent;
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({required this.item});

  final _DiscoverItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(item.image, fit: BoxFit.cover)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1A0303).withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.sub,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Color(0x66000000), blurRadius: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One-shot fade + upward-slide entrance for any widget. Starts on first
/// build, plays once, then becomes a no-op rebuild. Use to stagger hero
/// content as a screen mounts.
class _OneShotFadeIn extends StatefulWidget {
  const _OneShotFadeIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_OneShotFadeIn> createState() => _OneShotFadeInState();
}

class _OneShotFadeInState extends State<_OneShotFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 20),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ── Compact production header ────────────────────────────────────────────────

class _HomeHeroHeader extends StatelessWidget {
  const _HomeHeroHeader({
    required this.name,
    required this.faculty,
    required this.academicYear,
    required this.unread,
    required this.onNotifications,
  });

  final String name;
  final String faculty;
  final String academicYear;
  final int unread;
  final VoidCallback onNotifications;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'ليلة طيبة';
    if (h < 12) return 'صباح الخير';
    if (h < 17) return 'مساء النور';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: SizedBox(
        height: topPad + 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) Solid brand red fallback.
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF72131B)),
            ),
            // 2) Branded landing background — high prominence (no heavy
            // overlay over the top portion so the pattern reads clearly).
            Positioned(
              top: -70,
              left: -50,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x16FFFFFF), width: 36),
                ),
              ),
            ),
            // 3) Gradient scrim from transparent (top) → deep red (bottom),
            // so the bg image stays vivid up top while the lower text area
            // gets full contrast.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x0072131B),
                    const Color(0x2472131B),
                    const Color(0x664F0D13),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            // 4) Status-bar top vignette.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPad + 60,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x55000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
            // 5) Foreground content.
            Padding(
              padding: EdgeInsets.fromLTRB(22, topPad + 18, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand mark + avatar row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Ter7al brand mark — small inline.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.directions_bus_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'ترحال',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Notifications glass icon.
                      _HeaderIconButton(
                        icon: Icons.notifications_none_rounded,
                        unread: unread,
                        onTap: onNotifications,
                      ),
                      const SizedBox(width: 10),
                      // Avatar (initials, glass)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.30),
                                  Colors.white.withValues(alpha: 0.10),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.50),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _initialsOf(name),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Big greeting + name block — cinematic.
                  Text(
                    _greeting,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name.isNotEmpty ? name : 'مرحبًا',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.1,
                      shadows: [
                        Shadow(color: Color(0x66000000), blurRadius: 18),
                      ],
                    ),
                  ),
                  if (faculty.isNotEmpty || academicYear.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA53B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            [
                              faculty,
                              academicYear,
                            ].where((s) => s.isNotEmpty).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small high-contrast icon button used in the branded header.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.unread = 0,
  });

  final IconData icon;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'الإشعارات',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0x32FFFFFF)),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA53B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF7B0F12),
                      width: 1.6,
                    ),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Premium student pass card ─────────────────────────────────────────────────

class _StudentPassCard extends StatelessWidget {
  const _StudentPassCard({
    required this.name,
    required this.code,
    required this.booking,
    this.onTrack,
  });

  final String name;
  final String code;
  final BookingModel? booking;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1417181B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: SizedBox(
          height: 230,
          child: Stack(
            children: [
              // 1) Base brand gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF72131B), Color(0xFF4F0D13)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // 2) Brand pattern overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.07,
                  child: Image.asset(
                    'assets/images/terhallanengpackgond.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
              // 3) Right-side bus image (Ticket-stub style)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/terhal2.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    // Left fade so the bus image blends into the ticket body
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1A0303).withValues(alpha: 0.55),
                            const Color(0xFF1A0303).withValues(alpha: 0.95),
                          ],
                          stops: const [0.35, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 4) Perforation dots between left content and right bus image
              // (classic travel ticket detail).
              Positioned(
                top: 0,
                bottom: 0,
                right: 116,
                width: 2,
                child: CustomPaint(painter: _TicketPerforationPainter()),
              ),
              // 5) Diagonal sheen
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                        stops: const [0.0, 0.30, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // 6) Content — magazine-style layout on the left
              Positioned.fill(
                right: 130,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top eyebrow + name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFA53B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'STUDENT PASS',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID • $code',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      // Booking detail (route + time)
                      if (booking == null)
                        Text(
                          'لا توجد رحلة نشطة اليوم',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Route name
                            Text(
                              booking!.trip.route.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // From → To row, ticket-stub style
                            Row(
                              children: [
                                _PassEndpoint(
                                  label: 'FROM',
                                  value: booking!.trip.route.originName,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    size: 14,
                                  ),
                                ),
                                _PassEndpoint(
                                  label: 'TO',
                                  value: booking!.trip.route.destinationName,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Time / Bus / Seat
                            Row(
                              children: [
                                _PassMetric(
                                  label: 'الانطلاق',
                                  value: formatTime(
                                    booking!.trip.departureTime,
                                  ),
                                  icon: Icons.schedule_rounded,
                                ),
                                _PassDivider(),
                                _PassMetric(
                                  label: 'الحافلة',
                                  value: booking!.trip.bus.code,
                                  icon: Icons.directions_bus_rounded,
                                ),
                                _PassDivider(),
                                _PassMetric(
                                  label: 'المقعد',
                                  value: booking!.seatNumber.isEmpty
                                      ? '--'
                                      : booking!.seatNumber,
                                  icon: Icons.event_seat_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              // 7) Tap-to-track full-card affordance.
              if (onTrack != null && booking != null)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: br,
                      onTap: onTrack,
                      splashColor: Colors.white.withValues(alpha: 0.06),
                      highlightColor: Colors.white.withValues(alpha: 0.03),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              // 8) Live-tracking pill bottom-right — visible CTA hint.
              if (onTrack != null && booking != null)
                Positioned(
                  bottom: 14,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7CFFB1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.2,
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
      ),
    );
  }
}

class _TicketPerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A0303).withValues(alpha: 0.55);
    const dotRadius = 1.4;
    const step = 6.0;
    for (double y = 8; y < size.height - 4; y += step) {
      canvas.drawCircle(Offset(size.width / 2, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PassEndpoint extends StatelessWidget {
  const _PassEndpoint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PassMetric extends StatelessWidget {
  const _PassMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white60, size: 11),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PassDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withValues(alpha: 0.20),
    );
  }
}

// ── Quick action pills ────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.booking,
    required this.paymentCount,
    required this.onOpenQr,
    required this.onOpenPayments,
    required this.onOpenSupport,
    this.onTrack,
  });

  final BookingModel? booking;
  final int paymentCount;
  final VoidCallback? onTrack;
  final VoidCallback onOpenQr;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenSupport;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionItem(
        icon: Icons.qr_code_2_rounded,
        label: 'رمز\nالحضور',
        color: const Color(0xFFA61C1C),
        bgColor: const Color(0xFFFFECEC),
        onTap: onOpenQr,
      ),
      _ActionItem(
        icon: Icons.location_on_rounded,
        label: 'تتبع\nالحافلة',
        color: const Color(0xFF087B66),
        bgColor: const Color(0xFFEBEFFF),
        onTap: onTrack,
        disabled: booking == null,
      ),
      _ActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'المدفوعات',
        color: const Color(0xFF17A267),
        bgColor: const Color(0xFFE8F7F1),
        badge: paymentCount > 0 ? '$paymentCount' : null,
        onTap: onOpenPayments,
      ),
      _ActionItem(
        icon: Icons.support_agent_outlined,
        label: 'الدعم\nوالمساعدة',
        color: const Color(0xFFFFA53B),
        bgColor: const Color(0xFFFFF4E5),
        onTap: onOpenSupport,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'الخدمات المتاحة',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF191919),
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: items
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _QuickActionPill(item: item),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    this.onTap,
    this.badge,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  final String? badge;
  final bool disabled;
}

class _QuickActionPill extends StatefulWidget {
  const _QuickActionPill({required this.item});

  final _ActionItem item;

  @override
  State<_QuickActionPill> createState() => _QuickActionPillState();
}

class _QuickActionPillState extends State<_QuickActionPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) {
        if (!item.disabled) setState(() => _pressed = true);
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: item.disabled ? null : item.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            // Solid white — guarantees the same crisp look in every
            // environment (production, DevicePreview, dark surfaces), since
            // a translucent gradient over a dark canvas was rendering grey.
            color: item.disabled ? const Color(0xFFF7F7FA) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEEEFF4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF091A2A).withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: const Color(0xFF091A2A).withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Specular top highlight
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.disabled
                          ? const Color(0xFFF0F0F0)
                          : item.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: item.disabled
                          ? null
                          : [
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.20),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Icon(
                      item.icon,
                      color: item.disabled
                          ? const Color(0xFFBBBBBB)
                          : item.color,
                      size: 24,
                    ),
                  ),
                  if (item.badge != null)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA61C1C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: item.disabled
                      ? const Color(0xFFBBBBBB)
                      : const Color(0xFF191919),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trip mini summary card ────────────────────────────────────────────────────

class _TripMiniCard extends StatelessWidget {
  const _TripMiniCard({
    required this.label,
    required this.booking,
    required this.accent,
  });

  final String label;
  final BookingModel? booking;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDeparture = accent == const Color(0xFF17A267);
    final icon = isDeparture
        ? Icons.flight_takeoff_rounded
        : Icons.flight_land_rounded;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Accent strip down the leading edge.
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent, accent.withValues(alpha: 0.55)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: booking == null
                            ? const Color(0xFFF0F0F5)
                            : accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: booking == null
                            ? const Color(0xFFAAAAAA)
                            : accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF72798D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  booking == null
                      ? '--:--'
                      : formatTime(booking!.trip.departureTime),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF191919),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking?.trip.route.destinationName ?? 'لم يُحجز بعد',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF72798D),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: booking == null
                        ? const Color(0xFFF0F0F5)
                        : accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: booking == null
                              ? const Color(0xFFAAAAAA)
                              : accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        booking == null ? 'غير محجوز' : booking!.trip.statusAr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: booking == null
                              ? const Color(0xFFAAAAAA)
                              : accent,
                        ),
                      ),
                    ],
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

class TripsPage extends ConsumerWidget {
  const TripsPage({super.key, required this.onOpenTracking});

  final void Function(TripModel trip) onOpenTracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final bookedIds = state.bookings.map((item) => item.trip.id).toSet();

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _OneShotFadeIn(
              child: _SimpleScreenHeader(
                title: 'الرحلات',
                subtitle: '${state.trips.length} رحلة متاحة على خطك',
                icon: Icons.directions_bus_rounded,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            sliver: SliverList.list(
              children: [
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 80),
                  child: const _HomeSectionTitle(
                    title: 'رحلات متاحة',
                    subtitle: 'اضغط احجز الآن لإضافة رحلة إلى حسابك.',
                  ),
                ),
                const SizedBox(height: 12),
                ...state.trips.mapIndexed((i, trip) {
                  final alreadyBooked = bookedIds.contains(trip.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OneShotFadeIn(
                      delay: Duration(milliseconds: 320 + i * 40),
                      child: TripListCard(
                        trip: trip,
                        footer: Row(
                          children: [
                            Expanded(
                              child: StatusChip(
                                label: '${trip.availableSeats} مقعد متاح',
                                color: const Color(0xFFFFA53B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: alreadyBooked
                                    ? null
                                    : () => controller.bookTrip(trip.id),
                                style: FilledButton.styleFrom(
                                  backgroundColor: alreadyBooked
                                      ? const Color(0xFFE3E5EE)
                                      : const Color(0xFFA61C1C),
                                  foregroundColor: alreadyBooked
                                      ? const Color(0xFF969AAF)
                                      : Colors.white,
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                child: Text(
                                  alreadyBooked
                                      ? state
                                            .appExperience
                                            .tripBookedButtonLabel
                                      : state
                                            .appExperience
                                            .tripBookingButtonLabel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key, required this.onOpenTracking});

  final void Function(TripModel trip) onOpenTracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final today = DateUtils.dateOnly(DateTime.now());
    final current = state.bookings.where((booking) {
      final date = booking.trip.date?.toLocal();
      return date != null &&
          !DateUtils.dateOnly(date).isBefore(today) &&
          booking.status != 'cancelled';
    }).toList();
    final currentIds = current.map((item) => item.id).toSet();
    final previous = state.bookings
        .where((booking) => !currentIds.contains(booking.id))
        .toList();

    Widget bookingCard(BookingModel booking, {required bool canTrack}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TripListCard(
          trip: booking.trip,
          footer: Row(
            children: [
              Expanded(
                child: StatusChip(
                  label: booking.statusLabel,
                  color: booking.status == 'cancelled'
                      ? const Color(0xFFA61C1C)
                      : const Color(0xFF17A267),
                ),
              ),
              if (canTrack) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onOpenTracking(booking.trip),
                    icon: const Icon(
                      Icons.location_searching_rounded,
                      size: 18,
                    ),
                    label: const Text('تتبع'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: _SimpleScreenHeader(
              title: 'حجوزاتي',
              subtitle: 'الحجوزات الحالية والرحلات السابقة.',
              icon: Icons.confirmation_number_rounded,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            sliver: SliverList.list(
              children: [
                const _HomeSectionTitle(
                  title: 'الحجوزات الحالية',
                  subtitle: 'الرحلات القادمة والمؤكدة.',
                ),
                const SizedBox(height: 12),
                if (current.isEmpty)
                  const EmptyPanel(
                    title: 'لا توجد حجوزات حالية',
                    subtitle: 'اختر رحلة من صفحة الرحلات.',
                  )
                else
                  ...current.map(
                    (booking) => bookingCard(booking, canTrack: true),
                  ),
                const SizedBox(height: 22),
                const _HomeSectionTitle(
                  title: 'الحجوزات السابقة',
                  subtitle: 'سجل الرحلات المكتملة أو الملغاة.',
                ),
                const SizedBox(height: 12),
                if (previous.isEmpty)
                  const EmptyPanel(
                    title: 'لا يوجد سجل سابق',
                    subtitle: 'تظهر الرحلات القديمة هنا بعد انتهائها.',
                  )
                else
                  ...previous.map(
                    (booking) => bookingCard(booking, canTrack: false),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QrPage extends ConsumerWidget {
  const QrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final byId = <int, BookingModel>{};
    for (final item in [
      state.studentHome?.departureBooking,
      state.studentHome?.returnBooking,
      ...state.bookings,
    ].whereType<BookingModel>()) {
      final date = item.trip.date;
      if (item.isConfirmed &&
          item.qrToken.isNotEmpty &&
          date != null &&
          DateUtils.isSameDay(date.toLocal(), DateTime.now())) {
        byId[item.id] = item;
      }
    }
    final bookings = byId.values.toList()
      ..sort((a, b) => a.trip.departureTime.compareTo(b.trip.departureTime));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _OneShotFadeIn(
            child: _SimpleScreenHeader(
              title: 'رمز الحضور',
              subtitle: 'اعرض الرمز للمشرف عند الصعود.',
              icon: Icons.qr_code_2_rounded,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          sliver: SliverList.list(
            children: [
              if (bookings.isEmpty)
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 80),
                  child: const EmptyPanel(
                    title: 'لا يوجد QR متاح',
                    subtitle: 'احجز رحلة أولًا ليتم توليد رمز الحضور.',
                  ),
                )
              else
                ...bookings.mapIndexed(
                  (index, booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _OneShotFadeIn(
                      delay: Duration(milliseconds: 80 + index * 70),
                      child: Column(
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              '${booking.trip.directionAr} · ${formatTime(booking.trip.departureTime)} · ${booking.trip.tripCode}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF191919),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _QrTicketCard(
                            name:
                                state.studentHome?.name ??
                                state.user?.fullName ??
                                '',
                            code: state.studentHome?.code ?? '',
                            token: booking.qrToken,
                            expiresAt: booking.qrExpiresAt,
                          ),
                          const SizedBox(height: 12),
                          GlassCard(
                            child: Column(
                              children: [
                                InfoRow(
                                  label: 'الخط',
                                  value: booking.trip.route.name,
                                  icon: Icons.route_rounded,
                                ),
                                const Divider(height: 24),
                                InfoRow(
                                  label: 'المقعد',
                                  value: booking.seatNumber.isEmpty
                                      ? '—'
                                      : booking.seatNumber,
                                  icon: Icons.event_seat_rounded,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Premium QR ticket card — name + ID at top on a red surface, then a white
/// inner panel containing the QR. Mirrors the language of the home Pass card.
class _QrTicketCard extends StatelessWidget {
  const _QrTicketCard({
    required this.name,
    required this.code,
    required this.token,
    required this.expiresAt,
  });

  final String name;
  final String code;
  final String token;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Base red gradient with brand pattern overlay (same language as
          // the home Pass card — keeps the visual identity tight).
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFF72131B)),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/terhallanengpackgond.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          // Foreground
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Identity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BOARDING PASS',
                            style: TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name.isEmpty ? '—' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (code.isNotEmpty)
                            Text(
                              'ID • $code',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Status pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.32),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'صالح',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // White inner QR plate
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: token,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      color: Color(0xFFA61C1C),
                      eyeShape: QrEyeShape.square,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      color: Color(0xFF191919),
                      dataModuleShape: QrDataModuleShape.square,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Token string + expiry
                Text(
                  token,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                if (expiresAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'صلاحية الرمز: ${formatDateTime(expiresAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact screen header used by the QR / Notifications / Profile pages so
/// they all share a tight visual rhythm with the Home page.
class _SimpleScreenHeader extends StatelessWidget {
  const _SimpleScreenHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF72131B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF191919),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF72798D),
                    height: 1.4,
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

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final unreadCount = state.notifications.where((n) => !n.isRead).length;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _OneShotFadeIn(
              child: _SimpleScreenHeader(
                title: 'الإشعارات',
                subtitle: unreadCount > 0
                    ? '$unreadCount إشعار غير مقروء'
                    : 'كل تحديثاتك ظاهرة هنا فور وصولها.',
                icon: Icons.notifications_active_rounded,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            sliver: SliverList.list(
              children: [
                if (state.notifications.isEmpty)
                  _OneShotFadeIn(
                    delay: const Duration(milliseconds: 80),
                    child: const EmptyPanel(
                      title: 'لا توجد إشعارات',
                      subtitle: 'سيتم عرض الإشعارات الجديدة هنا.',
                    ),
                  )
                else
                  ...state.notifications.mapIndexed(
                    (i, notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OneShotFadeIn(
                        delay: Duration(milliseconds: 60 + i * 40),
                        child: _NotificationTile(
                          notification: notification,
                          onMarkRead: notification.isRead
                              ? null
                              : () => controller.markNotificationRead(
                                  notification.id,
                                ),
                        ),
                      ),
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

class _NotificationTile extends StatefulWidget {
  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
  });

  final NotificationModel notification;
  final VoidCallback? onMarkRead;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  final bool expanded = false;

  void _openMessage() {
    widget.onMarkRead?.call();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            NotificationDetailsPage(notification: widget.notification),
      ),
    );
  }

  Color get _typeColor {
    switch (widget.notification.type) {
      case 'trip':
        return const Color(0xFF087B66);
      case 'payment':
        return const Color(0xFF17A267);
      case 'safety':
        return const Color(0xFFA61C1C);
      default:
        return const Color(0xFFFFA53B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final unread = !notification.isRead;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _openMessage,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Coloured left strip — quick categorical scan.
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: unread ? _typeColor : Colors.transparent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: unread
                          ? _typeColor.withValues(alpha: 0.14)
                          : const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _notificationIcon(notification.type),
                      color: unread ? _typeColor : const Color(0xFF7B8297),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: unread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: const Color(0xFF191919),
                              ),
                            ),
                            if (notification.createdAt != null)
                              Text(
                                _timeAgo(notification.createdAt!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF969AAF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: expanded ? null : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF72798D),
                            height: 1.4,
                          ),
                        ),
                        if (notification.imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              ApiService.absoluteMediaUrl(
                                notification.imageUrl,
                              ),
                              width: double.infinity,
                              height: expanded ? 210 : 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                        if (notification.linkUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: () =>
                                  openExternalLink(notification.linkUrl),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 17,
                              ),
                              label: const Text('فتح الرابط'),
                            ),
                          ),
                        ],
                        ...[
                          const SizedBox(height: 2),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed: _openMessage,
                              child: const Text('عرض الرسالة كاملة'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (unread) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _typeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _typeColor.withValues(alpha: 0.45),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight relative time helper for notification timestamps.
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes}د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours}س';
  if (diff.inDays < 7) return 'منذ ${diff.inDays}ي';
  return DateFormat('dd/MM/yyyy').format(dt);
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final user = state.user;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Cinematic profile header — name on top of the brand background.
          SliverToBoxAdapter(
            child: _ProfileHeader(
              name: user?.fullName ?? '',
              subtitle: [
                user?.studentProfile?.faculty ?? '',
                user?.studentProfile?.academicYear ?? '',
              ].where((item) => item.isNotEmpty).join(' • '),
              role: 'طالب',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            sliver: SliverList.list(
              children: [
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 80),
                  child: _FinancialCarousel(
                    payments: state.payments,
                    loaded: state.paymentsLoaded,
                  ),
                ),
                const SizedBox(height: 4),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 140),
                  child: const _HomeSectionTitle(
                    title: 'بيانات الحساب',
                    subtitle: 'معلومات تسجيلك في النظام.',
                  ),
                ),
                const SizedBox(height: 12),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: GlassCard(
                    child: Column(
                      children: [
                        InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'اسم المستخدم',
                          value: user?.username ?? '—',
                        ),
                        const Divider(height: 26),
                        InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'رقم الهاتف',
                          value: user?.phoneNumber.isNotEmpty == true
                              ? user!.phoneNumber
                              : '—',
                        ),
                        const Divider(height: 26),
                        InfoRow(
                          icon: Icons.account_balance_outlined,
                          label: 'الجامعة',
                          value: user?.universityName.isNotEmpty == true
                              ? user!.universityName
                              : '—',
                        ),
                        if (user?.studentProfile != null) ...[
                          const Divider(height: 26),
                          InfoRow(
                            icon: Icons.school_outlined,
                            label: 'الكلية',
                            value: user!.studentProfile!.faculty.isNotEmpty
                                ? user.studentProfile!.faculty
                                : '—',
                          ),
                          const Divider(height: 26),
                          InfoRow(
                            icon: Icons.route_outlined,
                            label: 'خط السير',
                            value:
                                user.studentProfile!.preferredRoute?.name ??
                                '—',
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const _StudentProfileEditor(),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('تعديل الجامعة والخط والكلية'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 260),
                  child: const _HomeSectionTitle(
                    title: 'المدفوعات',
                    subtitle: 'آخر الفواتير المسجلة على الحساب.',
                  ),
                ),
                const SizedBox(height: 12),
                if (!state.paymentsLoaded)
                  const EmptyPanel(
                    title: 'جارٍ تحديث البيانات المالية',
                    subtitle: 'يمكنك سحب الصفحة لأسفل للمحاولة مرة أخرى.',
                  )
                else if (state.payments.isEmpty)
                  _OneShotFadeIn(
                    delay: const Duration(milliseconds: 320),
                    child: const EmptyPanel(
                      title: 'لا توجد فواتير',
                      subtitle: 'الفواتير المستقبلية ستظهر هنا.',
                    ),
                  )
                else
                  ...state.payments.mapIndexed(
                    (i, payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OneShotFadeIn(
                        delay: Duration(milliseconds: 320 + i * 50),
                        child: _PaymentTile(payment: payment),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 480),
                  child: OutlinedButton.icon(
                    onPressed: controller.logout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFA61C1C),
                    ),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: Color(0xFFA61C1C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(
                        color: Color(0xFFFCD9D9),
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.white,
                    ),
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

class _FinancialCarousel extends StatelessWidget {
  const _FinancialCarousel({required this.payments, required this.loaded});

  final List<PaymentModel> payments;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final paid = payments.where((item) => item.status == 'paid').toList();
    final pending = payments.where((item) => item.status == 'pending').toList();
    final failed = payments.where((item) => item.status == 'failed').toList();
    final netPaid = paid.fold<double>(0, (sum, item) => sum + item.amount);
    final pendingTotal = pending.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final pages = [
      (
        icon: Icons.account_balance_wallet_rounded,
        title: 'صافي ما تم دفعه فعليًا',
        value: loaded ? '${netPaid.toStringAsFixed(2)} ج.م' : '—',
        detail: '${paid.length} عملية ناجحة فقط — لا يشمل المعلق أو الفاشل',
        color: const Color(0xFF17A267),
      ),
      (
        icon: Icons.pending_actions_rounded,
        title: 'العمليات المعلقة',
        value: loaded ? '${pendingTotal.toStringAsFixed(2)} ج.م' : '—',
        detail: '${pending.length} عملية ما زالت قيد المراجعة أو السداد',
        color: const Color(0xFFFFA53B),
      ),
      (
        icon: Icons.receipt_long_rounded,
        title: 'حالة كل العمليات',
        value: loaded ? '${payments.length} عملية' : '—',
        detail:
            '${paid.length} ناجحة · ${pending.length} معلقة · ${failed.length} فشلت',
        color: const Color(0xFFA61C1C),
      ),
    ];
    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final item = pages[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InvoicesPage(
                    initialStatus: index == 1 ? 'pending' : 'all',
                  ),
                ),
              ),
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.icon, color: item.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.detail,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF72798D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'عرض الفواتير والتفاصيل ←',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF72131B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StudentProfileEditor extends ConsumerStatefulWidget {
  const _StudentProfileEditor();

  @override
  ConsumerState<_StudentProfileEditor> createState() =>
      _StudentProfileEditorState();
}

class _StudentProfileEditorState extends ConsumerState<_StudentProfileEditor> {
  final facultyController = TextEditingController();
  List<CampusModel> campuses = const [];
  List<RouteModel> routes = const [];
  String? campusCode;
  int? routeId;
  int? stopId;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider).user;
    facultyController.text = user?.studentProfile?.faculty ?? '';
    routeId = user?.studentProfile?.preferredRoute?.id;
    stopId = user?.studentProfile?.preferredPickupStop?.id;
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final values = await Future.wait([
        api.fetchCampuses(),
        api.fetchRoutes(),
      ]);
      if (!mounted) return;
      campuses = values[0] as List<CampusModel>;
      routes = values[1] as List<RouteModel>;
      final user = ref.read(sessionProvider).user;
      campusCode = campuses
          .firstWhereOrNull((item) => item.name == user?.universityName)
          ?.code;
      campusCode ??= routes
          .firstWhereOrNull((item) => item.id == routeId)
          ?.campusCode;
    } catch (_) {
      // Keep the sheet usable for a later retry without surfacing transport errors.
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    facultyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campusRoutes = routes
        .where((item) => item.campusCode == campusCode)
        .toList();
    final selectedRoute = campusRoutes.firstWhereOrNull(
      (item) => item.id == routeId,
    );
    final stops = selectedRoute?.stops ?? const <StopModel>[];
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تعديل بيانات الحساب',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'الرحلات المتاحة ستتحدث حسب الجامعة والخط الجديدين.',
                style: TextStyle(color: Color(0xFF72798D)),
              ),
              const SizedBox(height: 20),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: campusCode,
                  decoration: const InputDecoration(labelText: 'الجامعة'),
                  items: campuses
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.code,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    campusCode = value;
                    routeId = null;
                    stopId = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: campusRoutes.any((item) => item.id == routeId)
                      ? routeId
                      : null,
                  decoration: const InputDecoration(labelText: 'خط السير'),
                  items: campusRoutes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    routeId = value;
                    stopId = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: stops.any((item) => item.id == stopId)
                      ? stopId
                      : null,
                  decoration: const InputDecoration(labelText: 'نقطة الركوب'),
                  items: stops
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => stopId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: facultyController,
                  decoration: const InputDecoration(
                    labelText: 'الكلية',
                    hintText: 'امسح النص واكتب الكلية الجديدة',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        saving ||
                            campusCode == null ||
                            routeId == null ||
                            stopId == null
                        ? null
                        : () async {
                            setState(() => saving = true);
                            try {
                              await ref
                                  .read(sessionProvider.notifier)
                                  .updateStudentProfile(
                                    universityCode: campusCode!,
                                    routeId: routeId!,
                                    pickupStopId: stopId!,
                                    faculty: facultyController.text,
                                  );
                              if (context.mounted) Navigator.of(context).pop();
                            } catch (_) {
                              if (mounted) setState(() => saving = false);
                            }
                          },
                    child: Text(saving ? 'جارٍ الحفظ…' : 'حفظ وتحديث الرحلات'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.subtitle,
    required this.role,
  });

  final String name;
  final String subtitle;
  final String role;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: SizedBox(
        height: topPad + 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF8B0F12)),
            ),
            Image.asset(
              'assets/images/terhallanengpackgond.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A0303).withValues(alpha: 0.05),
                    const Color(0xFF7B0F12).withValues(alpha: 0.45),
                    const Color(0xFF1A0303).withValues(alpha: 0.95),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22, topPad + 18, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role chip
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              role,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppAvatar(name: name),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name.isEmpty ? 'حسابي' : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final paid = payment.status == 'paid';
    final failed = payment.status == 'failed';
    final color = paid
        ? const Color(0xFF17A267)
        : failed
        ? const Color(0xFFA61C1C)
        : const Color(0xFFFFA53B);
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              paid
                  ? Icons.check_circle_rounded
                  : failed
                  ? Icons.cancel_rounded
                  : Icons.hourglass_bottom_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.purpose,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF191919),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    payment.invoiceNumber,
                    payment.paymentMethod.isEmpty
                        ? ''
                        : payment.paymentMethodAr,
                    if (payment.createdAt != null)
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(payment.createdAt!.toLocal()),
                  ].where((item) => item.isNotEmpty).join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF72798D),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(0)} EGP',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF191919),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.statusAr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
