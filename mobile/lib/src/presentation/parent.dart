part of '../app.dart';

class ParentShell extends ConsumerStatefulWidget {
  const ParentShell({super.key});

  @override
  ConsumerState<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends ConsumerState<ParentShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ParentOverviewPage(onOpenTracking: _openTracking),
      _ParentTrackingPage(onOpenTracking: _openTracking),
      const _ParentProfilePage(),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: index, children: pages),
        ),
      ),
      bottomNavigationBar: _GlassNavBar(
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'المتابعة',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_searching_outlined),
              selectedIcon: Icon(Icons.location_searching_rounded),
              label: 'التتبع',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ],
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

class _ParentOverviewPage extends ConsumerWidget {
  const _ParentOverviewPage({required this.onOpenTracking});

  final void Function(TripModel trip) onOpenTracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final summary = state.parentSummary;
    final student = summary?.student;
    final currentSubscription = summary?.subscriptions.firstWhereOrNull(
      (item) => item.isCurrent,
    );

    return RefreshIndicator(
      onRefresh: ref.read(sessionProvider.notifier).refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        children: [
          _ParentHero(
            parentName: state.user?.fullName ?? '',
            studentName: student?.name ?? '',
            studentCode: student?.code ?? '',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ParentMetric(
                  icon: Icons.confirmation_number_outlined,
                  value: '${summary?.bookings.length ?? 0}',
                  label: 'الرحلات',
                  color: const Color(0xFF087B66),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ParentMetric(
                  icon: Icons.receipt_long_outlined,
                  value: '${summary?.payments.length ?? 0}',
                  label: 'الفواتير',
                  color: const Color(0xFFFFA53B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ParentMetric(
                  icon: Icons.route_outlined,
                  value: '${currentSubscription?.remainingRides ?? 0}',
                  label: 'رحلة متبقية',
                  color: const Color(0xFF17A267),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle(
            title: 'آخر الرحلات',
            subtitle: 'حجوزات الطالب المسجلة على حسابه.',
          ),
          const SizedBox(height: 12),
          if (summary == null || summary.bookings.isEmpty)
            const EmptyPanel(
              title: 'لا توجد رحلات مسجلة',
              subtitle: 'ستظهر حجوزات الطالب هنا بمجرد تأكيدها.',
            )
          else
            ...summary.bookings
                .take(3)
                .map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TripListCard(
                      trip: booking.trip,
                      footer: FilledButton.icon(
                        onPressed: () => onOpenTracking(booking.trip),
                        icon: const Icon(Icons.location_searching_rounded),
                        label: const Text('متابعة الرحلة'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFFA61C1C),
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          const SectionTitle(
            title: 'الاشتراك',
            subtitle: 'حالة اشتراك النقل وعدد الرحلات المتبقية.',
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: currentSubscription == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لا يوجد اشتراك نشط',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'يمكنك إرسال طلب اشتراك شهري وسيظهر للإدارة للمراجعة.',
                        style: TextStyle(color: Color(0xFF72798D)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => ref
                                  .read(sessionProvider.notifier)
                                  .requestSubscription(),
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('طلب اشتراك شهري'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      InfoRow(
                        icon: Icons.workspace_premium_outlined,
                        label: 'الخطة',
                        value: currentSubscription.planName,
                      ),
                      const Divider(height: 26),
                      InfoRow(
                        icon: Icons.route_outlined,
                        label: 'الرحلات المتبقية',
                        value: '${currentSubscription.remainingRides}',
                      ),
                      const Divider(height: 26),
                      InfoRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'الأيام المتبقية',
                        value: '${currentSubscription.remainingDays}',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ParentTrackingPage extends ConsumerWidget {
  const _ParentTrackingPage({required this.onOpenTracking});

  final void Function(TripModel trip) onOpenTracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    return RefreshIndicator(
      onRefresh: ref.read(sessionProvider.notifier).refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        children: [
          const HeaderBlock(
            title: 'التتبع المباشر',
            subtitle: 'الرحلات التي تمت مشاركتها معك بأمان.',
          ),
          const SizedBox(height: 18),
          if (state.parentTracking.isEmpty)
            const EmptyPanel(
              title: 'لا توجد رحلة مشاركة الآن',
              subtitle:
                  'سيظهر التتبع عندما يبدأ المشرف أو الطالب مشاركة الموقع.',
            )
          else
            ...state.parentTracking.map(
              (share) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TripListCard(
                  trip: share.trip,
                  footer: FilledButton.icon(
                    onPressed: () => onOpenTracking(share.trip),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('فتح الخريطة الحية'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color(0xFFA61C1C),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParentProfilePage extends ConsumerWidget {
  const _ParentProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final user = state.user;
    final child = state.parentSummary?.student;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      children: [
        HeaderBlock(
          title: user?.fullName.isNotEmpty == true
              ? user!.fullName
              : 'حساب ولي الأمر',
          subtitle: 'بيانات الحساب والطالب المرتبط به.',
          trailing: AppAvatar(name: user?.fullName ?? ''),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            children: [
              InfoRow(
                icon: Icons.phone_outlined,
                label: 'رقم الهاتف',
                value: user?.phoneNumber ?? '—',
              ),
              const Divider(height: 26),
              InfoRow(
                icon: Icons.family_restroom_outlined,
                label: 'الطالب',
                value: child?.name ?? '—',
              ),
              const Divider(height: 26),
              InfoRow(
                icon: Icons.numbers_outlined,
                label: 'الكود الجامعي',
                value: child?.code ?? '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => ref.read(sessionProvider.notifier).logout(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('تسجيل الخروج'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            foregroundColor: const Color(0xFFA61C1C),
          ),
        ),
      ],
    );
  }
}

class _ParentHero extends StatelessWidget {
  const _ParentHero({
    required this.parentName,
    required this.studentName,
    required this.studentCode,
  });

  final String parentName;
  final String studentName;
  final String studentCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF72131B),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1217181B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.family_restroom_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 18),
          Text(
            parentName.isEmpty ? 'مرحبًا بك' : 'مرحبًا، $parentName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            studentName.isEmpty
                ? 'متابعة آمنة لرحلات الطالب'
                : '$studentName${studentCode.isEmpty ? '' : ' · $studentCode'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentMetric extends StatelessWidget {
  const _ParentMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF72798D), fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
