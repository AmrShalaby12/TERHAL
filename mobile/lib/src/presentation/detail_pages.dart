part of '../app.dart';

class _StudentNavigation extends StatelessWidget {
  const _StudentNavigation({
    required this.index,
    required this.onSelect,
    required this.unread,
  });
  final int index;
  final int unread;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'الرئيسية',
      'الرحلات',
      'حجوزاتي',
      'الحضور',
      'الإشعارات',
      'حسابي',
    ];
    const icons = [
      Icons.home_outlined,
      Icons.directions_bus_outlined,
      Icons.confirmation_number_outlined,
      Icons.qr_code_2_rounded,
      Icons.notifications_outlined,
      Icons.person_outline,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = index == i;
          return Expanded(
            child: Semantics(
              selected: selected,
              button: true,
              label: labels[i],
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF72131B)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Badge(
                          isLabelVisible: i == 4 && unread > 0,
                          child: Icon(
                            icons[i],
                            size: 22,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF756C68),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.2,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: selected
                                ? const Color(0xFF72131B)
                                : const Color(0xFF756C68),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key, this.initialStatus = 'all'});
  final String initialStatus;
  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage> {
  late String status = widget.initialStatus;
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final payments =
        session.payments
            .where((p) => status == 'all' || p.status == status)
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            ),
          );
    return Scaffold(
      appBar: AppBar(title: const Text('فواتيري')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sessionProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(18),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in const {
                  'all': 'الكل',
                  'paid': 'المدفوعة',
                  'pending': 'المعلقة',
                  'failed': 'الفاشلة',
                }.entries)
                  ChoiceChip(
                    label: Text(filter.value),
                    selected: status == filter.key,
                    onSelected: (_) => setState(() => status = filter.key),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '${payments.length} فاتورة',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (payments.isEmpty)
              const EmptyPanel(
                title: 'لا توجد فواتير في هذا القسم',
                subtitle: 'يمكنك اختيار قسم آخر أو سحب الصفحة للتحديث.',
              ),
            for (final payment in payments)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _InvoiceDetails(payment: payment),
              ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceDetails extends StatelessWidget {
  const _InvoiceDetails({required this.payment});
  final PaymentModel payment;
  @override
  Widget build(BuildContext context) {
    final color = payment.status == 'paid'
        ? const Color(0xFF087B66)
        : const Color(0xFF72131B);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                payment.purpose,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              StatusChip(label: payment.statusAr, color: color),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${payment.amount.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              fontSize: 26,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Divider(height: 28),
          _DetailLine(label: 'رقم الفاتورة', value: payment.invoiceNumber),
          _DetailLine(label: 'طريقة الدفع', value: payment.paymentMethodAr),
          _DetailLine(
            label: 'تاريخ الإنشاء',
            value: formatDateTime(payment.createdAt),
          ),
          _DetailLine(
            label: 'تاريخ السداد',
            value: payment.paidAt == null
                ? 'لم يُسجّل سداد'
                : formatDateTime(payment.paidAt),
          ),
          if (payment.tripCode.isNotEmpty)
            _DetailLine(label: 'الرحلة', value: payment.tripCode),
          if (payment.bookingId != null)
            _DetailLine(label: 'رقم الحجز', value: '${payment.bookingId}'),
          if (payment.subscriptionId != null)
            _DetailLine(
              label: 'رقم الاشتراك',
              value: '${payment.subscriptionId}',
            ),
          if (payment.installmentId != null)
            _DetailLine(label: 'رقم القسط', value: '${payment.installmentId}'),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF756C68), fontSize: 12),
        ),
        const SizedBox(height: 3),
        SelectableText(
          value.isEmpty ? '—' : value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    ),
  );
}

class NotificationDetailsPage extends StatelessWidget {
  const NotificationDetailsPage({super.key, required this.notification});
  final NotificationModel notification;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل الإشعار')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
            if (notification.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  formatDateTime(notification.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF756C68),
                  ),
                ),
              ),
            const Divider(height: 30),
            SelectableText(
              notification.body,
              style: const TextStyle(fontSize: 16, height: 1.8),
            ),
            if (notification.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    ApiService.absoluteMediaUrl(notification.imageUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            for (final link in <String>{
              if (notification.linkUrl.isNotEmpty) notification.linkUrl,
              ...RegExp(
                r'https?://[^\s<>]+',
              ).allMatches(notification.body).map((m) => m.group(0)!),
            })
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: () => openExternalLink(link),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('فتح الرابط'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
