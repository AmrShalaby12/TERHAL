part of '../app.dart';

class SupervisorBookingsPage extends ConsumerStatefulWidget {
  const SupervisorBookingsPage({super.key, this.initialTripId});
  final int? initialTripId;

  @override
  ConsumerState<SupervisorBookingsPage> createState() =>
      _SupervisorBookingsPageState();
}

class _SupervisorBookingsPageState
    extends ConsumerState<SupervisorBookingsPage> {
  String selectedDate = '';
  String query = '';
  bool confirmedOnly = true;
  late int selectedTrip = widget.initialTripId ?? 0;

  String day(TripModel trip) =>
      trip.date == null ? '' : DateFormat('yyyy-MM-dd').format(trip.date!);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionProvider);
    final trips = <int, TripModel>{
      for (final trip in state.trips) trip.id: trip,
      for (final booking in state.bookings) booking.trip.id: booking.trip,
    };
    final dates =
        trips.values
            .map(day)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final options =
        trips.values
            .where((trip) => selectedDate.isEmpty || day(trip) == selectedDate)
            .toList()
          ..sort(
            (a, b) => '${day(a)} ${a.departureTime}'.compareTo(
              '${day(b)} ${b.departureTime}',
            ),
          );
    final rows = state.bookings.where((booking) {
      if (confirmedOnly && !booking.isConfirmed) return false;
      if (selectedTrip != 0 && booking.trip.id != selectedTrip) return false;
      if (selectedDate.isNotEmpty && day(booking.trip) != selectedDate) {
        return false;
      }
      final text =
          '${booking.studentName} ${booking.studentPhone} ${booking.pickupStop?.name ?? ''}'
              .toLowerCase();
      return text.contains(query.trim().toLowerCase());
    }).toList();
    return RefreshIndicator(
      onRefresh: ref.read(sessionProvider.notifier).refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        itemCount: rows.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HeaderBlock(
                  title: 'حجوزات الطلاب',
                  subtitle:
                      'كل حجوزات رحلاتك الحالية والقادمة. اسحب لأسفل لتحديث البيانات.',
                ),
                const SizedBox(height: 16),
                if (state.isLoading) const LinearProgressIndicator(),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'بحث باسم الطالب أو الهاتف أو النقطة',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('date-$selectedDate-${dates.length}'),
                  initialValue: dates.contains(selectedDate)
                      ? selectedDate
                      : '',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'تاريخ الرحلة'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('كل الأيام الحالية والقادمة'),
                    ),
                    ...dates.map(
                      (date) =>
                          DropdownMenuItem(value: date, child: Text(date)),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    selectedDate = value ?? '';
                    selectedTrip = 0;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(
                    'trip-$selectedTrip-$selectedDate-${options.length}',
                  ),
                  initialValue: options.any((trip) => trip.id == selectedTrip)
                      ? selectedTrip
                      : 0,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الخط والرحلة'),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('كل رحلاتك')),
                    ...options.map(
                      (trip) => DropdownMenuItem(
                        value: trip.id,
                        child: Text(
                          '${trip.route.name} • ${trip.route.campusCode} • ${day(trip)} • ${trip.directionAr} ${formatTime(trip.departureTime)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedTrip = value ?? 0),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الحجوزات المؤكدة فقط'),
                  subtitle: const Text(
                    'أوقفه لعرض الملغي وبانتظار الدفع أيضًا',
                  ),
                  value: confirmedOnly,
                  onChanged: (value) => setState(() => confirmedOnly = value),
                ),
                Text(
                  'عدد الحجوزات المعروضة: ${rows.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                if (rows.isEmpty && !state.isLoading)
                  const EmptyPanel(
                    title: 'لا توجد حجوزات مطابقة',
                    subtitle:
                        'جرّب كل الأيام أو كل الرحلات، أو أوقف فلتر الحجوزات المؤكدة.',
                  ),
              ],
            );
          }
          final booking = rows[index - 1];
          final payment = switch (booking.paymentMethod) {
            'subscription' => 'اشتراك',
            'cash' => 'نقدي',
            'kashier' => 'أونلاين',
            _ => 'غير مسجل',
          };
          final paymentStatus = switch (booking.paymentStatus) {
            'paid' => 'مدفوع',
            'pending' => 'بانتظار الدفع',
            'failed' => 'غير مكتمل',
            _ => '',
          };
          return Padding(
            key: ValueKey('booking-${booking.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.studentName.isEmpty
                        ? 'حجز رقم ${booking.id}'
                        : booking.studentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نقطة الركوب: ${booking.pickupStop?.name ?? 'غير مسجلة في الحجز'}',
                  ),
                  const SizedBox(height: 6),
                  const Text('رقم هاتف الطالب'),
                  SelectableText(
                    booking.studentPhone.isEmpty
                        ? 'غير مسجل'
                        : booking.studentPhone,
                    textDirection: TextDirection.ltr,
                  ),
                  Text(
                    '${booking.trip.route.name} • ${booking.trip.route.campusCode}',
                  ),
                  Text(
                    '${day(booking.trip)} • ${booking.trip.directionAr} ${formatTime(booking.trip.departureTime)}',
                  ),
                  Text('الرحلة: ${booking.trip.tripCode}'),
                  if (booking.seatNumber.isNotEmpty)
                    Text('المقعد: ${booking.seatNumber}'),
                  Text(
                    'الدفع: $payment${paymentStatus.isEmpty ? '' : ' — $paymentStatus'}',
                  ),
                  const SizedBox(height: 8),
                  StatusChip(
                    label: booking.statusLabel,
                    color: booking.isConfirmed
                        ? const Color(0xFF087B66)
                        : const Color(0xFFA61C1C),
                  ),
                  if (booking.trip.status == 'cancelled')
                    const Text(
                      'الرحلة ملغاة',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
