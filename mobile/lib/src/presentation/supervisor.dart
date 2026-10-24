part of '../app.dart';

class SupervisorShell extends ConsumerStatefulWidget {
  const SupervisorShell({super.key});

  @override
  ConsumerState<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends ConsumerState<SupervisorShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      SupervisorOverviewPage(),
      SupervisorTripsPage(),
      SupervisorBookingsPage(),
      SupervisorScanPage(),
      SupervisorProfilePage(),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          top: false,
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
              selectedIcon: Icon(Icons.dashboard),
              label: 'لوحة التحكم',
            ),
            NavigationDestination(
              icon: Icon(Icons.alt_route_outlined),
              selectedIcon: Icon(Icons.alt_route),
              label: 'الرحلات',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'الحجوزات',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner),
              label: 'المسح',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

class SupervisorOverviewPage extends ConsumerWidget {
  const SupervisorOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final overview = state.supervisorOverview;
    if (state.isLoading && overview == null) {
      return const _SupervisorLoadingView();
    }
    final cards = [
      ('رحلات اليوم', '${overview?.todayTrips ?? 0}', const Color(0xFFA61C1C)),
      ('نشطة الآن', '${overview?.activeTrips ?? 0}', const Color(0xFFFFA53B)),
      (
        'طلاب على متن الحافلة',
        '${overview?.studentsOnBoard ?? 0}',
        const Color(0xFF17A267),
      ),
      (
        'سجل الحضور',
        '${overview?.attendanceLogs ?? 0}',
        const Color(0xFF087B66),
      ),
    ];
    return RefreshIndicator(
      onRefresh: ref.read(sessionProvider.notifier).refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          HeaderBlock(
            title: 'مرحبًا ${state.user?.fullName ?? ''}',
            subtitle: 'إدارة الرحلات والطلاب لحظيًا من تطبيق المشرف.',
            trailing: AppAvatar(name: state.user?.fullName ?? ''),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  appBar: null,
                  body: SafeArea(child: SupervisorBookingsPage()),
                ),
              ),
            ),
            icon: const Icon(Icons.people_alt_outlined),
            label: Text(
              'حجوزات الطلاب الحالية والقادمة (${state.bookings.where((b) => b.isConfirmed).length})',
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.18,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, idx) {
              final card = cards[idx];
              return MetricPanel(
                title: card.$1,
                value: card.$2,
                color: card.$3,
              );
            },
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الحجوزات الحالية والقادمة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'حجوزات مؤكدة: ${state.bookings.where((b) => b.isConfirmed).length}',
                ),
                Text('حجوزات اليوم: ${overview?.todayBookings ?? 0}'),
                if (overview?.nextTripDate != null)
                  Text(
                    'أقرب يوم رحلات: ${DateFormat('yyyy-MM-dd').format(overview!.nextTripDate!)}',
                  ),
                if (overview != null && overview.todayTrips == 0)
                  const Text(
                    'لا توجد رحلات اليوم. حجوزات الأيام القادمة متاحة في تبويب الحجوزات.',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle(
            title: 'آخر عمليات المسح',
            subtitle: 'أحدث حركات تأكيد حضور الطلبة.',
          ),
          const SizedBox(height: 12),
          if (overview == null || overview.recentScans.isEmpty)
            const EmptyPanel(
              title: 'لا توجد سجلات',
              subtitle: 'سيتم عرض آخر عمليات الحضور هنا.',
            )
          else
            ...overview.recentScans.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFECEC),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFFA61C1C),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.studentName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${record.tripCode} • ${formatDateTime(record.createdAt)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF72798D)),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: record.scanType == 'board' ? 'صعود' : 'نزول',
                        color: const Color(0xFF17A267),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SupervisorTripsPage extends ConsumerWidget {
  const SupervisorTripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final trips = state.trips;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        const HeaderBlock(
          title: 'الرحلات المخصصة لك',
          subtitle: 'إدارة الرحلات المرتبطة بحساب المشرف الحالي.',
        ),
        const SizedBox(height: 18),
        if (state.isLoading && trips.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (trips.isEmpty)
          const EmptyPanel(
            title: 'لا توجد رحلات',
            subtitle: 'سيتم عرض الرحلات المخصصة لك هنا.',
          )
        else
          ...trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TripListCard(
                trip: trip,
                footer: Row(
                  children: [
                    IconButton(
                      tooltip: 'حجوزات الطلاب',
                      icon: const Icon(Icons.people_alt_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('حجوزات الرحلة')),
                            body: SafeArea(
                              child: SupervisorBookingsPage(
                                initialTripId: trip.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: StatusChip(
                        label: trip.bus.code,
                        color: const Color(0xFF087B66),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatusChip(
                        label: trip.driverName,
                        color: const Color(0xFF17A267),
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

class _SupervisorLoadingView extends StatelessWidget {
  const _SupervisorLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري تحميل بيانات الرحلات...'),
        ],
      ),
    );
  }
}

class SupervisorScanPage extends ConsumerStatefulWidget {
  const SupervisorScanPage({super.key});

  @override
  ConsumerState<SupervisorScanPage> createState() => _SupervisorScanPageState();
}

class _SupervisorScanPageState extends ConsumerState<SupervisorScanPage> {
  final tokenController = TextEditingController();
  int? selectedTripId;
  bool submitting = false;

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionProvider);
    final trips = state.trips;
    selectedTripId ??= trips.firstOrNull?.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        const HeaderBlock(
          title: 'تسجيل الحضور',
          subtitle: 'امسح رمز QR من شاشة الطالب أو أدخل الكود الجامعي.',
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedTripId,
                items: trips
                    .map(
                      (trip) => DropdownMenuItem<int>(
                        value: trip.id,
                        child: Text(
                          '${trip.tripCode} • ${trip.route.originName}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedTripId = value),
                decoration: const InputDecoration(
                  labelText: 'اختر الرحلة',
                  prefixIcon: Icon(Icons.directions_bus_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: tokenController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'رمز QR أو كود الطالب',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed:
                    submitting ||
                        selectedTripId == null ||
                        tokenController.text.trim().isEmpty
                    ? null
                    : () => _submit(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFFA61C1C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('تأكيد الحضور'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('حجوزات الطلاب')),
                body: const SafeArea(child: SupervisorBookingsPage()),
              ),
            ),
          ),
          icon: const Icon(Icons.people_outline),
          label: const Text('عرض كشف الطلاب كاملًا'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => submitting = true);
    try {
      final name = await ref
          .read(sessionProvider.notifier)
          .scanAttendance(
            tripId: selectedTripId!,
            qrToken: tokenController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل حضور $name بنجاح'),
            backgroundColor: const Color(0xFF17A267),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: const Color(0xFFA61C1C),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }
}

class SupervisorProfilePage extends ConsumerWidget {
  const SupervisorProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final user = state.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        HeaderBlock(
          title: user?.fullName ?? '',
          subtitle: user?.supervisorProfile?.department ?? '',
          trailing: AppAvatar(name: user?.fullName ?? ''),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            children: [
              InfoRow(
                icon: Icons.badge_outlined,
                label: 'الرقم الوظيفي',
                value: user?.supervisorProfile?.employeeId ?? '',
              ),
              const Divider(height: 26),
              InfoRow(
                icon: Icons.phone_outlined,
                label: 'الهاتف',
                value: user?.phoneNumber ?? '',
              ),
              const Divider(height: 26),
              InfoRow(
                icon: Icons.notifications_active_outlined,
                label: 'الإشعارات',
                value: '${state.notifications.length} عنصر',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: controller.logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('تسجيل الخروج'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
          ),
        ),
      ],
    );
  }
}
