part of '../app.dart';

class TerhalApp extends ConsumerWidget {
  const TerhalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tajawal is bundled locally, so the first screen never waits on a font
    // request and the typography stays identical offline.
    final baseText = ThemeData.light().textTheme.apply(fontFamily: 'Tajawal');
    final theme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF72131B),
        primary: const Color(0xFF72131B),
        secondary: const Color(0xFF087B66),
        surface: Colors.white,
        error: const Color(0xFFB42318),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F6F2),
      textTheme: baseText.apply(
        bodyColor: const Color(0xFF17181B),
        displayColor: const Color(0xFF17181B),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F6F2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF17181B),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE7E1DC)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _LiquidPageTransitionsBuilder(),
          TargetPlatform.iOS: _LiquidPageTransitionsBuilder(),
          TargetPlatform.windows: _LiquidPageTransitionsBuilder(),
          TargetPlatform.macOS: _LiquidPageTransitionsBuilder(),
          TargetPlatform.linux: _LiquidPageTransitionsBuilder(),
        },
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: const Color(0xFF72131B),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFF554C47),
            size: 23,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return baseText.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF72131B)
                : const Color(0xFF554C47),
            fontWeight: FontWeight.w800,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: baseText.bodyMedium?.copyWith(
          color: const Color(0xFF969AAF),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCD7D1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF72131B), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          backgroundColor: const Color(0xFF72131B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          foregroundColor: const Color(0xFF72131B),
          side: const BorderSide(color: Color(0xFFD7C8C6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE7E1DC),
        thickness: 1,
        space: 1,
      ),
    );

    return MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final content = kDebugMode
            ? DevicePreview.appBuilder(context, child)
            : child ?? const SizedBox.shrink();
        return _TerhalExperienceLayer(child: content);
      },
      debugShowCheckedModeBanner: false,
      title: 'Terhal',
      theme: theme,
      scrollBehavior: const SmoothScrollBehavior(),
      home: const AppShell(),
    );
  }
}

/// App-wide ScrollBehavior that picks BouncingScrollPhysics on every platform
/// for a buttery iOS-style scroll feel, removes the Material overscroll glow,
/// and supports mouse/trackpad/touch dragging out of the box.
class SmoothScrollBehavior extends ScrollBehavior {
  const SmoothScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// Custom page transition: a soft fade + scale that fits the liquid-glass
/// aesthetic — gentler than the default Material vertical slide.
class _LiquidPageTransitionsBuilder extends PageTransitionsBuilder {
  const _LiquidPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _seenLanding = false;
  StreamSubscription<String>? _pushTokenSubscription;
  String? _pushToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setUpPush());
  }

  Future<void> _setUpPush() async {
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supported) return;
    try {
      await PlatformBootstrap.ensureInitialized();
      _pushToken = await PushService.instance.setUp(
        onOpen: (data) {
          final link = data['link_url']?.toString() ?? '';
          if (link.isNotEmpty) unawaited(openExternalLink(link));
          if (mounted) unawaited(ref.read(sessionProvider.notifier).refresh());
        },
      );
      final token = _pushToken;
      if (token != null && token.isNotEmpty) {
        await ref.read(sessionProvider.notifier).bindDevice(token);
      }
      _pushTokenSubscription = PushService.instance.onTokenRefresh.listen((
        token,
      ) {
        _pushToken = token;
        unawaited(ref.read(sessionProvider.notifier).bindDevice(token));
      });
    } catch (error) {
      debugPrint('Push notifications are unavailable: $error');
    }
  }

  @override
  void dispose() {
    _pushTokenSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        final token = _pushToken;
        if (token != null && token.isNotEmpty) {
          unawaited(ref.read(sessionProvider.notifier).bindDevice(token));
        }
      }
      // Network failures are handled by retaining cached data and pull-to-refresh.
      // Never expose Dio/socket exception text as a red application banner.
    });

    final session = ref.watch(sessionProvider);
    if (session.isLoading && !session.isAuthenticated) {
      return const _SplashScreen();
    }
    final user = session.user;
    if (user == null) {
      if (!_seenLanding) {
        return LandingScreen(
          onEnter: () => setState(() => _seenLanding = true),
        );
      }
      return const AuthScreen();
    }
    if (user.isStudent) {
      return const StudentShell();
    }
    if (user.isSupervisor) {
      return const SupervisorShell();
    }
    if (user.isParent) {
      return const ParentShell();
    }
    return const AdminCompanionScreen();
  }
}

// ignore: unused_element
class _LegacySplashScreen extends StatelessWidget {
  const _LegacySplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF250606), Color(0xFFA61C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Terhal',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'منظومة النقل الجامعي',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Landing screen — first impression. Uses the branded background asset, has a
// gentle parallax/zoom on the image, a swipeable feature carousel under a
// liquid-glass card, and a confident CTA into the Auth screen.
// ═════════════════════════════════════════════════════════════════════════════

// ignore: unused_element
class _LegacyLandingScreen extends StatefulWidget {
  const _LegacyLandingScreen({required this.onEnter});

  final VoidCallback onEnter;

  @override
  State<_LegacyLandingScreen> createState() => _LegacyLandingScreenState();
}

class _LegacyLandingScreenState extends State<_LegacyLandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _entryController;
  late final PageController _pageController;
  int _page = 0;

  static const _slides = <_LandingSlide>[
    _LandingSlide(
      image: 'assets/images/terhal3.png',
      imageAlignment: Alignment.centerRight,
      eyebrow: 'تنقّل ذكي للجامعة',
      title: 'رحلتك الجامعية\nأبسط وأسرع',
      body:
          'حافلات مكيّفة، وحجز فوري، ومتابعة لحظية لموقعك إلى الكلية — تجربة طلابية بمعايير عالمية.',
    ),
    _LandingSlide(
      image: 'assets/images/terhal4.png',
      eyebrow: 'تتبّع لحظي وأمان',
      title: 'اعرف مكان حافلتك\nقبل ما توصل المحطة',
      body:
          'خريطة حيّة بالتحديث المباشر، تنبيهات وصول، ومشرف يضمن سلامتك من البداية للنهاية.',
    ),
    _LandingSlide(
      image: 'assets/images/terhal2.png',
      eyebrow: 'حضور بقراءة QR',
      title: 'صعود بدون كروت\nبدون انتظار',
      body:
          'كود حضور شخصي على جهازك، يتحقق منه المشرف في ثوانٍ — تجربة سلسة من باب البيت لباب المحاضرة.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Branded background with slow Ken-Burns zoom for a premium feel.
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final t = _bgController.value;
              return Transform.scale(
                scale: 1.08 + (t * 0.06),
                alignment: Alignment(-0.2 + t * 0.4, -0.1 + t * 0.2),
                child: Image.asset(
                  'assets/images/terhallanengpackgond.png',
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          // 2) Dark scrim so foreground text remains readable on any crop.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x00000000),
                  Color(0xCC120303),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          // 3) Foreground content.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  _FadeSlideIn(
                    controller: _entryController,
                    delay: 0.0,
                    child: const _LandingBrandHeader(),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _FadeSlideIn(
                      controller: _entryController,
                      delay: 0.15,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _slides.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) =>
                            _LandingSlideCard(slide: _slides[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FadeSlideIn(
                    controller: _entryController,
                    delay: 0.30,
                    child: _LandingDots(count: _slides.length, current: _page),
                  ),
                  const SizedBox(height: 24),
                  _FadeSlideIn(
                    controller: _entryController,
                    delay: 0.42,
                    child: _LandingCtaRow(
                      onEnter: widget.onEnter,
                      isLast: _page == _slides.length - 1,
                      onNext: () {
                        if (_page == _slides.length - 1) {
                          widget.onEnter();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
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

class _LandingSlide {
  const _LandingSlide({
    required this.image,
    this.imageAlignment = Alignment.center,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String image;
  final Alignment imageAlignment;
  final String eyebrow;
  final String title;
  final String body;
}

class _LandingBrandHeader extends StatelessWidget {
  const _LandingBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.40),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ter7al',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            Text(
              'travel',
              style: TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 11,
                letterSpacing: 3.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 7),
                  Text(
                    'العربية',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LandingSlideCard extends StatelessWidget {
  const _LandingSlideCard({required this.slide});

  final _LandingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // Big art card with the image inside a glass frame.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    slide.image,
                    fit: BoxFit.cover,
                    alignment: slide.imageAlignment,
                  ),
                  // Enhanced gradient for better text readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x44000000),
                          Color(0xBB1a0303),
                        ],
                        stops: [0.0, 0.50, 1.0],
                      ),
                    ),
                  ),
                  // Enhanced eyebrow badge
                  Positioned(
                    left: 16,
                    bottom: 20,
                    right: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.08),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFB74D),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  slide.eyebrow,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
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
          const SizedBox(height: 22),
          // Title - Enhanced typography
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Color(0x77000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Body copy - Better readability
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingDots extends StatelessWidget {
  const _LandingDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final active = i == current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: active ? 28 : 9,
                height: 9,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _LandingCtaRow extends StatelessWidget {
  const _LandingCtaRow({
    required this.onEnter,
    required this.onNext,
    required this.isLast,
  });

  final VoidCallback onEnter;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        // Secondary button - Skip / Log-in
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEnter,
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Text(
                      'تسجيل\nالدخول',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.2,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Primary button - Next / Start
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onNext,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF5F5F5)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'ابدأ الآن' : 'التالي',
                        style: const TextStyle(
                          color: Color(0xFFA61C1C),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLast ? Icons.login_rounded : Icons.arrow_back_rounded,
                        color: const Color(0xFFA61C1C),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable fade + upward-slide entrance for staggered hero animations.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    required this.controller,
    required this.delay,
    required this.child,
  });

  final AnimationController controller;
  final double delay; // 0..1 portion of the controller before this starts
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = delay.clamp(0.0, 0.9);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 22),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool registerMode = false;
  String registerRole = 'student';
  final formKey = GlobalKey<FormState>();
  final phoneLoginController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final guardianPhoneController = TextEditingController();
  final universityCodeController = TextEditingController();
  final facultyController = TextEditingController();
  final yearController = TextEditingController();
  final studentCodeController = TextEditingController();
  final relationController = TextEditingController();
  List<CampusModel> campuses = const [];
  List<RouteModel> routes = const [];
  String? selectedCampusCode;
  int? selectedRouteId;
  int? selectedPickupStopId;

  List<RouteModel> get campusRoutes => routes
      .where((route) => route.campusCode == selectedCampusCode)
      .toList(growable: false);

  RouteModel? get selectedRoute {
    for (final route in campusRoutes) {
      if (route.id == selectedRouteId) return route;
    }
    return null;
  }

  List<StopModel> get routePickupStops {
    final stops = selectedRoute?.stops ?? const <StopModel>[];
    final namedPickupStops = stops
        .where((stop) => stop.name.startsWith('نقطة ركوب'))
        .toList(growable: false);
    return namedPickupStops.isEmpty ? stops : namedPickupStops;
  }

  CampusModel? get selectedCampus {
    for (final campus in campuses) {
      if (campus.code == selectedCampusCode) return campus;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final api = ref.read(apiServiceProvider);
      final results = await Future.wait([
        api.fetchCampuses(),
        api.fetchRoutes(),
      ]);
      if (!mounted) return;
      setState(() {
        campuses = results[0] as List<CampusModel>;
        routes = results[1] as List<RouteModel>;
        selectedCampusCode = campuses.isEmpty ? null : campuses.first.code;
      });
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    phoneLoginController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    guardianPhoneController.dispose();
    universityCodeController.dispose();
    facultyController.dispose();
    yearController.dispose();
    studentCodeController.dispose();
    relationController.dispose();
    super.dispose();
  }

  void updateRegisterMode(bool value) {
    setState(() => registerMode = value);
    formKey.currentState?.reset();
  }

  void updateRegisterRole(String value) {
    setState(() => registerRole = value);
  }

  void selectCampus(String? value) {
    setState(() {
      selectedCampusCode = value;
      selectedRouteId = null;
      selectedPickupStopId = null;
    });
  }

  void selectPickupStop(int? value) {
    setState(() => selectedPickupStopId = value);
  }

  void selectRoute(int? value) {
    setState(() {
      selectedRouteId = value;
      selectedPickupStopId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isWide = MediaQuery.sizeOf(context).width > 720;

    return Scaffold(
      body: Container(
        color: const Color(0xFF72131B),
        child: Stack(
          children: [
            if (isWide)
              Row(
                children: [
                  Expanded(
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(48, 48, 24, 48),
                        child: _AuthHeroContent(registerMode: registerMode),
                      ),
                    ),
                  ),
                  _AuthGlassPanel(
                    width: 460,
                    isWide: true,
                    child: _AuthFormPanel(state: this, session: session),
                  ),
                ],
              )
            else
              Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: _AuthHeroContent(
                        registerMode: registerMode,
                        compact: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _AuthGlassPanel(
                      isWide: false,
                      child: SingleChildScrollView(
                        child: _AuthFormPanel(state: this, session: session),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Auth hero content (wide + compact mobile variant) ─────────────────────────

class _AuthHeroContent extends StatelessWidget {
  const _AuthHeroContent({this.compact = false, required this.registerMode});
  final bool compact;
  final bool registerMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: compact ? 44 : 52,
              height: compact ? 44 : 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                color: const Color(0xFF72131B),
                size: compact ? 24 : 29,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ترحال',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 20 : 27,
                  ),
                ),
                Text(
                  'النقل الجامعي',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: compact ? 11 : 13,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'دخول آمن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 20 : 34),
        Text(
          registerMode ? 'أنشئ حسابك في ترحال' : 'سجّل دخولك إلى ترحال',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 25 : 36,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          registerMode
              ? 'ابدأ رحلاتك الجامعية بحساب موحّد وآمن.'
              : 'رحلتك وحضورك وتنبيهاتك في مكان واحد.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.5,
            fontSize: compact ? 13 : 16,
          ),
        ),
        SizedBox(height: compact ? 18 : 28),
        const Row(
          children: [
            Expanded(
              child: _AuthFeature(
                icon: Icons.location_searching_outlined,
                label: 'تتبع مباشر',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _AuthFeature(
                icon: Icons.qr_code_2_rounded,
                label: 'حضور QR',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _AuthFeature(
                icon: Icons.notifications_none_rounded,
                label: 'تنبيهات فورية',
              ),
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/terhal_identity_bus_bnu_v3.png',
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Soft white specular border via a thin gradient frame.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthFeature extends StatelessWidget {
  const _AuthFeature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 19),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

// ── Stable form surface ──────────────────────────────────────────────────────

class _AuthGlassPanel extends StatelessWidget {
  const _AuthGlassPanel({
    required this.child,
    required this.isWide,
    this.width,
  });
  final Widget child;
  final bool isWide;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final br = isWide
        ? BorderRadius.zero
        : const BorderRadius.vertical(top: Radius.circular(24));

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F2),
        borderRadius: br,
        border: isWide
            ? const Border(left: BorderSide(color: Color(0x22FFFFFF)))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({required this.state, required this.session});

  final _AuthScreenState state;
  final SessionState session;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: state.formKey,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<bool>(value: false, label: Text('تسجيل دخول')),
                  ButtonSegment<bool>(value: true, label: Text('إنشاء حساب')),
                ],
                selected: {state.registerMode},
                onSelectionChanged: (values) {
                  state.updateRegisterMode(values.first);
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              state.registerMode ? 'إنشاء حساب جديد' : 'مرحبًا بعودتك',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              state.registerMode
                  ? 'أنشئ حساب طالب أو ولي أمر وابدأ استخدام خدمات ترحال.'
                  : 'أدخل بيانات حسابك المسجلة للمتابعة بأمان.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF72798D)),
            ),
            const SizedBox(height: 24),
            if (!state.registerMode) ...[
              TextFormField(
                controller: state.phoneLoginController,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().length < 10
                    ? 'أدخل رقم هاتف صحيح'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_iphone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: state.passwordController,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (state.formKey.currentState?.validate() != true) return;
                  state.ref
                      .read(sessionProvider.notifier)
                      .login(
                        phoneNumber: state.phoneLoginController.text.trim(),
                        password: state.passwordController.text,
                      );
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'أدخل كلمة المرور' : null,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF72131B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: session.isLoading
                    ? null
                    : () {
                        if (state.formKey.currentState?.validate() != true) {
                          return;
                        }
                        state.ref
                            .read(sessionProvider.notifier)
                            .login(
                              phoneNumber: state.phoneLoginController.text
                                  .trim(),
                              password: state.passwordController.text,
                            );
                      },
                child: session.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('الدخول إلى النظام'),
              ),
            ] else ...[
              TextFormField(
                controller: state.fullNameController,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().length < 3
                    ? 'أدخل الاسم بالكامل'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالكامل',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: state.phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().length < 10
                    ? 'أدخل رقم هاتف صحيح'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_iphone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: state.passwordController,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.length < 8
                    ? 'كلمة المرور يجب ألا تقل عن 8 أحرف'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<String>(value: 'student', label: Text('طالب')),
                  ButtonSegment<String>(
                    value: 'parent',
                    label: Text('ولي أمر'),
                  ),
                ],
                selected: {state.registerRole},
                onSelectionChanged: (values) {
                  state.updateRegisterRole(values.first);
                },
              ),
              if (state.registerRole == 'student') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: state.guardianPhoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      value == null || value.trim().length < 10
                      ? 'أدخل رقم هاتف ولي الأمر الصحيح'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'رقم هاتف ولي الأمر',
                    prefixIcon: Icon(Icons.family_restroom_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey(state.selectedCampusCode),
                  initialValue: state.selectedCampusCode,
                  decoration: const InputDecoration(
                    labelText: 'الجامعة أو المعهد',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: state.campuses
                      .map(
                        (campus) => DropdownMenuItem(
                          value: campus.code,
                          child: Text(campus.name),
                        ),
                      )
                      .toList(),
                  onChanged: state.selectCampus,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  key: ValueKey(
                    '${state.selectedCampusCode}-${state.selectedRouteId}',
                  ),
                  initialValue: state.selectedRouteId,
                  validator: (value) => value == null ? 'اختر خط السير' : null,
                  decoration: const InputDecoration(
                    labelText: 'خط السير',
                    prefixIcon: Icon(Icons.route_outlined),
                  ),
                  items: state.campusRoutes
                      .map(
                        (route) => DropdownMenuItem(
                          value: route.id,
                          child: Text(route.name),
                        ),
                      )
                      .toList(),
                  onChanged: state.selectRoute,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  key: ValueKey(
                    '${state.selectedRouteId}-${state.selectedPickupStopId}',
                  ),
                  initialValue: state.selectedPickupStopId,
                  validator: (value) =>
                      value == null ? 'اختر نقطة الركوب' : null,
                  decoration: const InputDecoration(
                    labelText: 'نقطة الركوب',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: state.routePickupStops
                      .map(
                        (stop) => DropdownMenuItem(
                          value: stop.id,
                          child: Text(stop.name.replaceFirst('نقطة ركوب ', '')),
                        ),
                      )
                      .toList(),
                  onChanged: state.selectPickupStop,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: state.universityCodeController,
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل الكود الجامعي'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'الكود الجامعي',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: state.facultyController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الكلية',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: state.yearController,
                  decoration: const InputDecoration(
                    labelText: 'السنة الدراسية',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: state.studentCodeController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل رقم تليفون الطالب المسجل في ترحال'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'رقم تليفون الطالب',
                    helperText: 'رقم الطالب المسجل في ترحال، وليس كود الجامعة',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: state.relationController,
                  decoration: const InputDecoration(
                    labelText: 'صلة القرابة',
                    prefixIcon: Icon(Icons.family_restroom_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFFA61C1C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: session.isLoading
                    ? null
                    : () {
                        if (state.formKey.currentState?.validate() != true) {
                          return;
                        }
                        state.ref
                            .read(sessionProvider.notifier)
                            .register(
                              fullName: state.fullNameController.text.trim(),
                              phoneNumber: state.phoneController.text.trim(),
                              password: state.passwordController.text,
                              role: state.registerRole,
                              faculty: state.facultyController.text.trim(),
                              academicYear: state.yearController.text.trim(),
                              universityCode: state
                                  .universityCodeController
                                  .text
                                  .trim(),
                              universityName: state.selectedCampus?.name ?? '',
                              studentPhoneNumber: state
                                  .studentCodeController
                                  .text
                                  .trim(),
                              relation: state.relationController.text.trim(),
                              guardianPhone: state.guardianPhoneController.text
                                  .trim(),
                              routeId: state.selectedRouteId,
                              pickupStopId: state.selectedPickupStopId,
                            );
                      },
                child: session.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('إنشاء الحساب'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Support / Help bottom sheet ───────────────────────────────────────────────
//
// Surfaced from the Home → Quick Action "الدعم والمساعدة". Pulls the student's
// own contact info (phone/university) from the session — purely backend-driven.

class SupportSheet extends ConsumerWidget {
  const SupportSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33091A2A),
              blurRadius: 40,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E5EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55E74C3C),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الدعم والمساعدة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF191919),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.universityName.isNotEmpty == true
                              ? user!.universityName
                              : 'فريق ترحال للدعم الطلابي',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF72798D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SupportTile(
                icon: Icons.phone_in_talk_rounded,
                title: 'اتصال مباشر',
                subtitle: 'تحدّث مع مشرف الرحلة فورًا',
                color: const Color(0xFF17A267),
              ),
              const SizedBox(height: 10),
              _SupportTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'دردشة الدعم',
                subtitle: 'استفسارات الحجز وتقارير الرحلات',
                color: const Color(0xFF087B66),
              ),
              const SizedBox(height: 10),
              _SupportTile(
                icon: Icons.shield_outlined,
                title: 'بلاغ طارئ',
                subtitle: 'في حالة حادثة أو حالة طارئة على الحافلة',
                color: const Color(0xFFA61C1C),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA61C1C),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F7FB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(title),
              backgroundColor: color,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF72798D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_rounded,
                size: 14,
                color: Color(0xFF969AAF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
