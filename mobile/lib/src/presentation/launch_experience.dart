part of '../app.dart';

const _identityBusAsset = 'assets/images/terhal_identity_bus_bnu_v3.png';
const _brandMarkAsset = 'assets/images/LOGO.png';

/// A deliberately light launch surface: paint first, decode the hero second.
/// There is no blur, blocking spinner, or continuous animation on this path.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.sizeOf(context).height * 0.64,
            child: Image.asset(
              _identityBusAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.72),
              cacheWidth: 720,
              filterQuality: FilterQuality.medium,
              frameBuilder: (context, child, frame, _) => AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                child: child,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00F8F4EE),
                  Color(0x00F8F4EE),
                  Color(0x44F8F4EE),
                  Color(0xDDF8F4EE),
                ],
                stops: [0, 0.52, 0.76, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      _brandMarkAsset,
                      width: 58,
                      height: 58,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        width: 92 * value,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA71920),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, required this.onEnter});

  final VoidCallback onEnter;

  @override
  State<LandingScreen> createState() => _PremiumLandingScreenState();
}

class _PremiumLandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
    );
    final panelAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 1, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            bottom: MediaQuery.sizeOf(context).height * 0.36,
            child: FadeTransition(
              opacity: heroAnimation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 1.035,
                  end: 1,
                ).animate(heroAnimation),
                child: Image.asset(
                  _identityBusAsset,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.62),
                  cacheWidth: 1080,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          Positioned.fill(
            bottom: MediaQuery.sizeOf(context).height * 0.36,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x00000000)],
                  stops: [0, 0.42],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: heroAnimation,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          _brandMarkAsset,
                          width: 46,
                          height: 46,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ter7al travel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'نقل طلاب الجامعات والرحلات التعليمية',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xD9FFFFFF),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.sizeOf(context).height * 0.44,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.10),
                end: Offset.zero,
              ).animate(panelAnimation),
              child: FadeTransition(
                opacity: panelAnimation,
                child: _LandingContentPanel(onEnter: widget.onEnter),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingContentPanel extends StatelessWidget {
  const _LandingContentPanel({required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F4EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA71920),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تجربة تنقّل مصممة للجامعة',
                      style: TextStyle(
                        color: Color(0xFF8B2026),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'رحلتك تبدأ\nقبل ما توصل المحطة',
                style: TextStyle(
                  color: Color(0xFF181412),
                  fontSize: 30,
                  height: 1.10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'حجز أسرع، حضور آمن، وموقع الحافلة لحظة بلحظة — في مكان واحد.',
                style: TextStyle(
                  color: Color(0xFF746D68),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Row(
                children: [
                  Expanded(
                    child: _LandingFeature(
                      icon: Icons.location_on_rounded,
                      label: 'تتبع مباشر',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _LandingFeature(
                      icon: Icons.qr_code_2_rounded,
                      label: 'حضور سريع',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _LandingFeature(
                      icon: Icons.shield_outlined,
                      label: 'رحلة آمنة',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: onEnter,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA71920),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ابدأ رحلتك',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_back_rounded, size: 20),
                    ],
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

class _LandingFeature extends StatelessWidget {
  const _LandingFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E1D8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFA71920), size: 16),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF453E39),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// In-app live status capsule inspired by Dynamic Island. It remains tiny and
/// non-interactive, expands only when status changes, then gets out of the way.
class _TerhalExperienceLayer extends ConsumerWidget {
  const _TerhalExperienceLayer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final unread = session.studentHome?.unreadNotifications ?? 0;
    final label = session.isLoading
        ? 'تحديث رحلتك'
        : unread > 0
        ? '$unread تنبيهات جديدة'
        : 'متصل وجاهز';

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        // Native devices have a real status-bar safe area where the capsule
        // can live. On web it competed with the app header, so the status is
        // represented by the header badges instead.
        if (session.isAuthenticated && !kIsWeb)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 7,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: _TerhalStatusIsland(
                  label: label,
                  unread: unread,
                  loading: session.isLoading,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TerhalStatusIsland extends StatefulWidget {
  const _TerhalStatusIsland({
    required this.label,
    required this.unread,
    required this.loading,
  });

  final String label;
  final int unread;
  final bool loading;

  @override
  State<_TerhalStatusIsland> createState() => _TerhalStatusIslandState();
}

class _TerhalStatusIslandState extends State<_TerhalStatusIsland> {
  Timer? _collapseTimer;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _scheduleCollapse();
  }

  @override
  void didUpdateWidget(covariant _TerhalStatusIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label) {
      setState(() => _expanded = true);
      _scheduleCollapse();
    }
  }

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.unread > 0
        ? const Color(0xFFFFB34A)
        : const Color(0xFF4DD789);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      width: _expanded ? 160 : 64,
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: _expanded ? 13 : 12),
      decoration: BoxDecoration(
        color: const Color(0xF2161719),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_expanded) ...[
            const Icon(
              Icons.directions_bus_filled_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
          ],
          if (widget.loading)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: accent),
            )
          else
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
          if (_expanded) ...[
            const SizedBox(width: 8),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  widget.label,
                  key: ValueKey(widget.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
