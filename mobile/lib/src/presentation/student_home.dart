part of '../app.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({
    super.key,
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
    final home = state.studentHome;
    final booking = home?.departureBooking ?? home?.returnBooking;
    final name = home?.name ?? state.user?.fullName ?? '';

    return RefreshIndicator.adaptive(
      onRefresh: ref.read(sessionProvider.notifier).refresh,
      displacement: 56,
      color: const Color(0xFFA71920),
      child: CustomScrollView(
        key: const PageStorageKey('student-premium-home'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 38),
            sliver: SliverList.list(
              children: [
                _PremiumHomeTopBar(
                  unread: home?.unreadNotifications ?? 0,
                  onNotifications: () => onSwitchTab(4),
                  onProfile: () => onSwitchTab(5),
                ),
                const SizedBox(height: 28),
                _OneShotFadeIn(
                  child: _PremiumGreeting(
                    name: name,
                    faculty:
                        home?.faculty ??
                        state.user?.studentProfile?.faculty ??
                        '',
                    academicYear:
                        home?.academicYear ??
                        state.user?.studentProfile?.academicYear ??
                        '',
                  ),
                ),
                const SizedBox(height: 22),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 70),
                  child: _PremiumJourneyPass(
                    name: name,
                    code: home?.code ?? '',
                    booking: booking,
                    onTrack: booking == null
                        ? null
                        : () => onOpenTracking(booking.trip),
                  ),
                ),
                const SizedBox(height: 28),
                const _PremiumSectionHeader(
                  title: 'خدماتك',
                  caption: 'كل ما تحتاجه في لمسة واحدة',
                ),
                const SizedBox(height: 14),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 130),
                  child: _PremiumServicesGrid(
                    booking: booking,
                    duePayments: home?.duePayments ?? 0,
                    onOpenQr: () => onSwitchTab(3),
                    onTrack: booking == null
                        ? null
                        : () => onOpenTracking(booking.trip),
                    onOpenPayments: () => onSwitchTab(5),
                    onOpenSupport: onShowSupport,
                  ),
                ),
                const SizedBox(height: 30),
                const _PremiumSectionHeader(
                  title: 'رحلات اليوم',
                  caption: 'مواعيدك المسجلة لليوم',
                ),
                const SizedBox(height: 14),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 190),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PremiumTripSummary(
                          title: 'الذهاب',
                          booking: home?.departureBooking,
                          accent: const Color(0xFF158A6A),
                          icon: Icons.north_east_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PremiumTripSummary(
                          title: 'العودة',
                          booking: home?.returnBooking,
                          accent: const Color(0xFFD88A22),
                          icon: Icons.south_west_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 250),
                  child: _PremiumTrackingBanner(
                    enabled: booking != null,
                    onTap: booking == null
                        ? null
                        : () => onOpenTracking(booking.trip),
                  ),
                ),
                const SizedBox(height: 18),
                _OneShotFadeIn(
                  delay: const Duration(milliseconds: 310),
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

class _PremiumHomeTopBar extends StatelessWidget {
  const _PremiumHomeTopBar({
    required this.unread,
    required this.onNotifications,
    required this.onProfile,
  });

  final int unread;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(_brandMarkAsset, width: 44, height: 44),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ter7al',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: Color(0xFF241E1A),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'UNIVERSITY MOBILITY',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: Color(0xFF8B8179),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          _PremiumHeaderButton(
            icon: Icons.notifications_none_rounded,
            badge: unread,
            onTap: onNotifications,
          ),
          const SizedBox(width: 8),
          _PremiumHeaderButton(
            icon: Icons.person_outline_rounded,
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class _PremiumHeaderButton extends StatelessWidget {
  const _PremiumHeaderButton({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFFE8E0D8)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 21, color: const Color(0xFF4D4540)),
            ),
          ),
        ),
        if (badge > 0)
          PositionedDirectional(
            top: -4,
            end: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFA71920),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFF8F4EE), width: 2),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PremiumGreeting extends StatelessWidget {
  const _PremiumGreeting({
    required this.name,
    required this.faculty,
    required this.academicYear,
  });

  final String name;
  final String faculty;
  final String academicYear;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء النور';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    final details = [
      faculty,
      academicYear,
    ].where((value) => value.trim().isNotEmpty).join('  •  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          style: const TextStyle(
            color: Color(0xFF8A817B),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          name.isEmpty ? 'أهلًا بك' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF191512),
            fontSize: 29,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: -0.7,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            details,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7A716B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _PremiumJourneyPass extends StatelessWidget {
  const _PremiumJourneyPass({
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
    final trip = booking?.trip;
    return Semantics(
      button: onTrack != null,
      label: 'بطاقة رحلة الطالب',
      child: Container(
        height: 294,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x337A1118),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Material(
            color: const Color(0xFF74131B),
            child: InkWell(
              onTap: onTrack,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF8C1720), Color(0xFF500B11)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: -22,
                    top: 0,
                    bottom: 0,
                    width: 185,
                    child: Image.asset(
                      _identityBusAsset,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, 0.73),
                      cacheWidth: 520,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 225,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0x001F0305),
                            Color(0x99500B11),
                            Color(0xFF74131B),
                          ],
                          stops: [0, 0.58, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 80,
                    left: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'STUDENT PASS',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: Color(0xBFFFFFFF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.2,
                                ),
                              ),
                              const Spacer(),
                              _PremiumLiveBadge(active: booking != null),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.54,
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            code.isEmpty ? 'ID • —' : 'ID • $code',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Spacer(),
                          if (trip == null)
                            const Text(
                              'لا توجد رحلة نشطة الآن',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else ...[
                            Text(
                              trip.route.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    trip.route.originName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xD9FFFFFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: Color(0x99FFFFFF),
                                    size: 15,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    trip.route.destinationName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0x2B000000)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            _PremiumPassMetric(
                              icon: Icons.schedule_rounded,
                              label: 'الانطلاق',
                              value: trip == null
                                  ? '--:--'
                                  : formatTime(trip.departureTime),
                            ),
                            _PremiumPassMetric(
                              icon: Icons.directions_bus_filled_rounded,
                              label: 'الحافلة',
                              value: trip?.bus.code ?? '—',
                            ),
                            _PremiumPassMetric(
                              icon: Icons.event_seat_rounded,
                              label: 'المقعد',
                              value: booking?.seatNumber.isNotEmpty == true
                                  ? booking!.seatNumber
                                  : '—',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumLiveBadge extends StatelessWidget {
  const _PremiumLiveBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF54E59B) : const Color(0xFFB8AAA8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'LIVE' : 'STANDBY',
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPassMetric extends StatelessWidget {
  const _PremiumPassMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0x99FFFFFF), size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSectionHeader extends StatelessWidget {
  const _PremiumSectionHeader({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E1916),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF918780),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumServicesGrid extends StatelessWidget {
  const _PremiumServicesGrid({
    required this.booking,
    required this.duePayments,
    required this.onOpenQr,
    required this.onTrack,
    required this.onOpenPayments,
    required this.onOpenSupport,
  });

  final BookingModel? booking;
  final int duePayments;
  final VoidCallback onOpenQr;
  final VoidCallback? onTrack;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenSupport;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _PremiumAction(
        icon: Icons.qr_code_2_rounded,
        title: 'رمز الحضور',
        caption: 'افتح الكود',
        color: const Color(0xFFA71920),
        tint: const Color(0xFFFFECE9),
        onTap: onOpenQr,
      ),
      _PremiumAction(
        icon: Icons.near_me_rounded,
        title: 'تتبع الحافلة',
        caption: booking == null ? 'لا توجد رحلة' : 'مباشر الآن',
        color: const Color(0xFF087A68),
        tint: const Color(0xFFE6F5F0),
        onTap: onTrack,
        disabled: booking == null,
      ),
      _PremiumAction(
        icon: Icons.account_balance_wallet_outlined,
        title: 'المدفوعات',
        caption: duePayments > 0 ? '$duePayments مستحقات' : 'الحساب منتظم',
        color: const Color(0xFF3268A8),
        tint: const Color(0xFFEAF1FA),
        onTap: onOpenPayments,
      ),
      _PremiumAction(
        icon: Icons.support_agent_rounded,
        title: 'الدعم',
        caption: 'نحن معك',
        color: const Color(0xFFD0801C),
        tint: const Color(0xFFFFF3DF),
        onTap: onOpenSupport,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 11,
        crossAxisSpacing: 11,
        childAspectRatio: 2.05,
      ),
      itemBuilder: (context, index) =>
          _PremiumActionTile(action: actions[index]),
    );
  }
}

class _PremiumAction {
  const _PremiumAction({
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
    required this.tint,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final String caption;
  final Color color;
  final Color tint;
  final VoidCallback? onTap;
  final bool disabled;
}

class _PremiumActionTile extends StatefulWidget {
  const _PremiumActionTile({required this.action});

  final _PremiumAction action;

  @override
  State<_PremiumActionTile> createState() => _PremiumActionTileState();
}

class _PremiumActionTileState extends State<_PremiumActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final enabled = !action.disabled && action.onTap != null;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: enabled ? Colors.white : const Color(0xFFF2EFEB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: enabled ? const Color(0xFFE9E2DA) : const Color(0xFFE4DFDA),
          ),
        ),
        child: InkWell(
          onTap: enabled ? action.onTap : null,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: enabled ? action.tint : const Color(0xFFE6E2DE),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    action.icon,
                    color: enabled ? action.color : const Color(0xFFAAA39E),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled
                              ? const Color(0xFF28221E)
                              : const Color(0xFF9E9792),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        action.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF938A84),
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
    );
  }
}

class _PremiumTripSummary extends StatelessWidget {
  const _PremiumTripSummary({
    required this.title,
    required this.booking,
    required this.accent,
    required this.icon,
  });

  final String title;
  final BookingModel? booking;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E1D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF706761),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            booking == null ? '--:--' : formatTime(booking!.trip.departureTime),
            style: const TextStyle(
              color: Color(0xFF211C19),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            booking?.trip.route.destinationName ?? 'لم تُحجز بعد',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: booking == null ? const Color(0xFFA29A94) : accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTrackingBanner extends StatelessWidget {
  const _PremiumTrackingBanner({required this.enabled, this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Material(
        color: const Color(0xFF311014),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _identityBusAsset,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.70),
                  cacheWidth: 820,
                  filterQuality: FilterQuality.medium,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Color(0xF237080C),
                        Color(0x992A0609),
                        Color(0x11000000),
                      ],
                      stops: [0, 0.60, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          enabled ? 'تتبّع حي' : 'بعد حجز الرحلة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'حافلتك على الخريطة\nلحظة بلحظة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            enabled ? 'افتح التتبع الآن' : 'احجز رحلة أولًا',
                            style: const TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
