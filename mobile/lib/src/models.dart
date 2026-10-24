// Safe numeric parsers — Django REST Framework sometimes returns numbers as
// strings (e.g. DecimalField → "5.20"), so we never cast directly.
int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  final s = v?.toString().toLowerCase();
  return s == 'true' || s == '1';
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

// ─────────────────────────────────────────────────────────────────────────────

class CampusModel {
  const CampusModel({
    required this.code,
    required this.name,
    required this.city,
  });

  final String code;
  final String name;
  final String city;

  factory CampusModel.fromJson(Map<String, dynamic> json) => CampusModel(
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
  );
}

class AuthPayload {
  const AuthPayload({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserProfile user;
  final String accessToken;
  final String refreshToken;

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>? ?? const {};
    return AuthPayload(
      user: UserProfile.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
      accessToken: tokens['access']?.toString() ?? '',
      refreshToken: tokens['refresh']?.toString() ?? '',
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.phoneNumber,
    required this.universityName,
    this.studentProfile,
    this.supervisorProfile,
    this.parentProfile,
  });

  final int id;
  final String username;
  final String fullName;
  final String role;
  final String phoneNumber;
  final String universityName;
  final StudentProfile? studentProfile;
  final SupervisorProfile? supervisorProfile;
  final ParentProfile? parentProfile;

  bool get isStudent => role == 'student';
  bool get isSupervisor => role == 'supervisor';
  bool get isAdmin => role == 'admin';
  bool get isParent => role == 'parent';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final studentJson = json['student_profile'];
    final supervisorJson = json['supervisor_profile'];
    final parentJson = json['parent_profile'];
    return UserProfile(
      id: _parseInt(json['id']),
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      phoneNumber: json['phone_number']?.toString() ?? '',
      universityName: json['university_name']?.toString() ?? '',
      studentProfile: studentJson is Map<String, dynamic>
          ? StudentProfile.fromJson(studentJson)
          : null,
      supervisorProfile: supervisorJson is Map<String, dynamic>
          ? SupervisorProfile.fromJson(supervisorJson)
          : null,
      parentProfile: parentJson is Map<String, dynamic>
          ? ParentProfile.fromJson(parentJson)
          : null,
    );
  }

  /// Round-trips through [UserProfile.fromJson] so a saved session can be
  /// restored offline (no network) on app start.
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'role': role,
    'phone_number': phoneNumber,
    'university_name': universityName,
    'student_profile': studentProfile?.toJson(),
    'supervisor_profile': supervisorProfile?.toJson(),
    'parent_profile': parentProfile?.toJson(),
  };
}

class StudentProfile {
  const StudentProfile({
    required this.studentCode,
    required this.faculty,
    required this.academicYear,
    this.preferredRoute,
    this.preferredPickupStop,
  });

  final String studentCode;
  final String faculty;
  final String academicYear;
  final RouteModel? preferredRoute;
  final StopModel? preferredPickupStop;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final pickup = json['preferred_pickup_stop'];
    final route = json['preferred_route'];
    return StudentProfile(
      studentCode: json['student_code']?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? '',
      preferredRoute: route is Map<String, dynamic>
          ? RouteModel.fromJson(route)
          : null,
      preferredPickupStop: pickup is Map<String, dynamic>
          ? StopModel.fromJson(pickup)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'student_code': studentCode,
    'faculty': faculty,
    'academic_year': academicYear,
    'preferred_route': preferredRoute == null
        ? null
        : {
            'id': preferredRoute!.id,
            'code': preferredRoute!.code,
            'name': preferredRoute!.name,
            'origin_name': preferredRoute!.originName,
            'destination_name': preferredRoute!.destinationName,
          },
    'preferred_pickup_stop': preferredPickupStop?.toJson(),
  };
}

class SupervisorProfile {
  const SupervisorProfile({required this.employeeId, required this.department});

  final String employeeId;
  final String department;

  factory SupervisorProfile.fromJson(Map<String, dynamic> json) {
    return SupervisorProfile(
      employeeId: json['employee_id']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId,
    'department': department,
  };
}

class ParentProfile {
  const ParentProfile({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.relation,
  });

  final int studentId;
  final String studentName;
  final String studentCode;
  final String relation;

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      studentId: _parseInt(json['student']),
      studentName: json['student_name']?.toString() ?? '',
      studentCode: json['student_code']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'student': studentId,
    'student_name': studentName,
    'student_code': studentCode,
    'relation': relation,
  };
}

class StudentHomeModel {
  const StudentHomeModel({
    required this.name,
    required this.code,
    required this.faculty,
    required this.academicYear,
    this.departureBooking,
    this.returnBooking,
    this.unreadNotifications = 0,
    this.duePayments = 0,
    this.supportContacts = const [],
  });

  final String name;
  final String code;
  final String faculty;
  final String academicYear;
  final BookingModel? departureBooking;
  final BookingModel? returnBooking;
  final int unreadNotifications;
  final int duePayments;
  final List<SupportContactModel> supportContacts;

  factory StudentHomeModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>? ?? const {};
    final departure = json['departure_booking'];
    final returning = json['return_booking'];
    return StudentHomeModel(
      name: student['name']?.toString() ?? '',
      code: student['code']?.toString() ?? '',
      faculty: student['faculty']?.toString() ?? '',
      academicYear: student['academic_year']?.toString() ?? '',
      departureBooking: departure is Map<String, dynamic>
          ? BookingModel.fromJson(departure)
          : null,
      returnBooking: returning is Map<String, dynamic>
          ? BookingModel.fromJson(returning)
          : null,
      unreadNotifications: _parseInt(json['unread_notifications']),
      duePayments: _parseInt(json['due_payments']),
      supportContacts: (json['support_contacts'] as List? ?? const [])
          .map(
            (item) => SupportContactModel.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class SupportContactModel {
  const SupportContactModel({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.phone,
  });
  final String key;
  final String title;
  final String subtitle;
  final String phone;

  String get whatsappUrl {
    var digits = phone.trim();
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < arabic.length; i++) {
      digits = digits.replaceAll(arabic[i], '$i');
    }
    digits = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length == 11 && digits.startsWith('01')) digits = '2$digits';
    if (digits.length < 8 || digits.length > 15) return '';
    return 'https://wa.me/$digits';
  }

  factory SupportContactModel.fromJson(Map<String, dynamic> json) =>
      SupportContactModel(
        key: json['key']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
      );
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.trip,
    this.pickupStop,
    required this.seatNumber,
    required this.status,
    required this.qrToken,
    required this.qrExpiresAt,
    this.studentName = '',
    this.studentPhone = '',
    this.paymentMethod = '',
    this.paymentStatus = '',
  });

  final int id;
  final TripModel trip;
  final StopModel? pickupStop;
  final String seatNumber;
  final String status;
  final String qrToken;
  final DateTime? qrExpiresAt;
  final String studentName;
  final String studentPhone;
  final String paymentMethod;
  final String paymentStatus;

  bool get isConfirmed =>
      const ['booked', 'checked_in', 'completed'].contains(status) &&
      trip.status != 'cancelled';

  String get statusLabel => switch (status) {
    'booked' => 'محجوز — لم يحضر بعد',
    'checked_in' => 'تم الحضور',
    'completed' => 'مكتملة',
    'pending_payment' => 'بانتظار الدفع — غير مؤكد',
    'cancelled' => 'ملغاة',
    _ => status,
  };

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: _parseInt(json['id']),
      trip: TripModel.fromJson(
        json['trip'] as Map<String, dynamic>? ?? const {},
      ),
      pickupStop: json['pickup_stop'] is Map
          ? StopModel.fromJson(
              (json['pickup_stop'] as Map).cast<String, dynamic>(),
            )
          : null,
      seatNumber: json['seat_number']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      qrToken: json['qr_token']?.toString() ?? '',
      qrExpiresAt: _parseDateTime(json['qr_expires_at']),
      studentName: json['student_name']?.toString() ?? '',
      studentPhone: json['student_phone']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
    );
  }
}

class TripModel {
  const TripModel({
    required this.id,
    required this.tripCode,
    required this.date,
    required this.direction,
    required this.status,
    required this.departureTime,
    required this.scheduledArrivalTime,
    required this.availableSeats,
    required this.bookingCount,
    required this.attendanceCount,
    required this.absentCount,
    required this.route,
    required this.bus,
    required this.driverName,
    required this.supervisorName,
    required this.notes,
    this.price,
  });

  final int id;
  final String tripCode;
  final DateTime? date;
  final String direction;
  final String status;
  final String departureTime;
  final String scheduledArrivalTime;
  final int availableSeats;
  final int bookingCount;
  final int attendanceCount;
  final int absentCount;
  final RouteModel route;
  final BusModel bus;
  final String driverName;
  final String supervisorName;
  final String notes;
  final double? price;

  bool get isDeparture => direction == 'departure';

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: _parseInt(json['id']),
      tripCode: json['trip_code']?.toString() ?? '',
      date: _parseDateTime(json['date']),
      direction: json['direction']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      departureTime: json['departure_time']?.toString() ?? '',
      scheduledArrivalTime: json['scheduled_arrival_time']?.toString() ?? '',
      availableSeats: _parseInt(json['available_seats']),
      bookingCount: _parseInt(json['booking_count']),
      attendanceCount: _parseInt(json['attendance_count']),
      absentCount: _parseInt(json['absent_count']),
      route: RouteModel.fromJson(
        json['route'] as Map<String, dynamic>? ?? const {},
      ),
      bus: BusModel.fromJson(json['bus'] as Map<String, dynamic>? ?? const {}),
      driverName: json['driver_name']?.toString() ?? '',
      supervisorName: json['supervisor_name']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      price: json['price'] == null ? null : _parseDouble(json['price']),
    );
  }
}

class RouteModel {
  const RouteModel({
    required this.id,
    required this.code,
    required this.name,
    this.campusCode = '',
    required this.originName,
    required this.destinationName,
    required this.distanceKm,
    required this.durationMinutes,
    required this.pathPoints,
    required this.stops,
  });

  final int id;
  final String code;
  final String name;
  final String campusCode;
  final String originName;
  final String destinationName;
  final double distanceKm;
  final int durationMinutes;
  final List<GeoPoint> pathPoints;
  final List<StopModel> stops;

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['path_points'] as List<dynamic>? ?? const [];
    final rawStops = json['stops'] as List<dynamic>? ?? const [];
    return RouteModel(
      id: _parseInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      campusCode: json['campus_code']?.toString() ?? '',
      originName: json['origin_name']?.toString() ?? '',
      destinationName: json['destination_name']?.toString() ?? '',
      distanceKm: _parseDouble(json['distance_km']),
      durationMinutes: _parseInt(json['estimated_duration_minutes']),
      pathPoints: rawPoints
          .map((p) => GeoPoint.fromJson((p as Map).cast<String, dynamic>()))
          .toList(),
      stops: rawStops
          .map((s) => StopModel.fromJson((s as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      lat: _parseDouble(json['lat'] ?? json['latitude']),
      lng: _parseDouble(json['lng'] ?? json['longitude']),
    );
  }
}

class StopModel {
  const StopModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.campusName,
    this.campusCode = '',
  });

  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String campusName;
  final String campusCode;

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      campusName: json['campus_name']?.toString() ?? '',
      campusCode: json['campus_code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'campus_name': campusName,
    'campus_code': campusCode,
  };
}

class BusModel {
  const BusModel({
    required this.id,
    required this.code,
    required this.plateNumber,
    required this.capacity,
    required this.status,
    required this.color,
  });

  final int id;
  final String code;
  final String plateNumber;
  final int capacity;
  final String status;
  final String color;

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: _parseInt(json['id']),
      code: json['code']?.toString() ?? '',
      plateNumber: json['plate_number']?.toString() ?? '',
      capacity: _parseInt(json['capacity']),
      status: json['status']?.toString() ?? '',
      color: json['color']?.toString() ?? '#A61C1C',
    );
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data = const {},
    this.linkUrl = '',
    this.imageUrl = '',
  });

  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;
  final String linkUrl;
  final String imageUrl;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isRead: _parseBool(json['is_read']),
      createdAt: _parseDateTime(json['created_at']),
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      linkUrl: json['link_url']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}

class ScanAttendanceResult {
  const ScanAttendanceResult({
    required this.studentName,
    required this.tripCode,
    required this.status,
    required this.availableReturnTrips,
  });

  final String studentName;
  final String tripCode;
  final String status;
  final List<TripModel> availableReturnTrips;

  factory ScanAttendanceResult.fromJson(Map<String, dynamic> json) {
    final returns =
        json['available_return_trips'] as List<dynamic>? ?? const [];
    return ScanAttendanceResult(
      studentName: json['student_name']?.toString() ?? 'تم التسجيل بنجاح',
      tripCode: json['trip_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      availableReturnTrips: returns
          .map(
            (item) => TripModel.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

class LocationShareModel {
  const LocationShareModel({
    required this.id,
    required this.trip,
    required this.studentName,
    required this.token,
    required this.expiresAt,
    this.latestLocation,
  });

  final int id;
  final TripModel trip;
  final String studentName;
  final String token;
  final DateTime? expiresAt;
  final GeoPoint? latestLocation;

  factory LocationShareModel.fromJson(Map<String, dynamic> json) {
    final latest = json['latest_location'];
    return LocationShareModel(
      id: _parseInt(json['id']),
      trip: TripModel.fromJson(
        json['trip'] as Map<String, dynamic>? ?? const {},
      ),
      studentName: json['student_name']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      expiresAt: _parseDateTime(json['expires_at']),
      latestLocation: latest is Map<String, dynamic>
          ? GeoPoint.fromJson(latest)
          : null,
    );
  }
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.paidAt,
    this.createdAt,
    this.tripCode = '',
    this.bookingId,
    this.subscriptionId,
    this.installmentId,
  });

  final int id;
  final String invoiceNumber;
  final double amount;
  final String status;
  final String paymentMethod;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final String tripCode;
  final int? bookingId;
  final int? subscriptionId;
  final int? installmentId;

  String get purpose {
    if (installmentId != null) return 'قسط اشتراك';
    if (subscriptionId != null) return 'اشتراك نقل';
    if (tripCode.isNotEmpty) return 'رحلة $tripCode';
    return 'دفعة';
  }

  String get paymentMethodAr => switch (paymentMethod) {
    'cash' => 'نقدي',
    'wallet' => 'محفظة إلكترونية',
    'bank_transfer' => 'تحويل بنكي',
    'card' => 'بطاقة بنكية',
    'kashier' => 'دفع إلكتروني',
    'subscription' => 'من رصيد الاشتراك',
    'manual_transfer' => 'تحويل يدوي',
    _ => paymentMethod,
  };

  String get statusAr => switch (status) {
    'paid' => 'مدفوعة',
    'pending' => 'معلّقة',
    'failed' => 'فشلت',
    _ => status,
  };

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: _parseInt(json['id']),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      status: json['status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paidAt: _parseDateTime(json['paid_at']),
      createdAt: _parseDateTime(json['created_at']),
      tripCode: json['trip_code']?.toString() ?? '',
      bookingId: json['booking_id'] == null
          ? null
          : _parseInt(json['booking_id']),
      subscriptionId: json['subscription_id'] == null
          ? null
          : _parseInt(json['subscription_id']),
      installmentId: json['installment_id'] == null
          ? null
          : _parseInt(json['installment_id']),
    );
  }
}

class AppExperienceModel {
  const AppExperienceModel({
    this.tripBookingButtonLabel = 'احجز من الاشتراك',
    this.tripBookedButtonLabel = 'تم الحجز',
    this.announcementTitle = '',
    this.announcementBody = '',
    this.announcementImageUrl = '',
    this.announcementLinkUrl = '',
    this.announcementButtonLabel = 'اعرف المزيد',
    this.announcementIsActive = false,
    this.announcementPopupEnabled = false,
  });

  final String tripBookingButtonLabel;
  final String tripBookedButtonLabel;
  final String announcementTitle;
  final String announcementBody;
  final String announcementImageUrl;
  final String announcementLinkUrl;
  final String announcementButtonLabel;
  final bool announcementIsActive;
  final bool announcementPopupEnabled;

  bool get hasPopup =>
      announcementIsActive &&
      announcementPopupEnabled &&
      (announcementTitle.isNotEmpty ||
          announcementBody.isNotEmpty ||
          announcementImageUrl.isNotEmpty);
  String get announcementKey => [
    announcementTitle,
    announcementBody,
    announcementImageUrl,
    announcementLinkUrl,
    announcementButtonLabel,
  ].join('|');

  factory AppExperienceModel.fromJson(Map<String, dynamic> json) {
    String label(String key, String fallback) {
      final value = json[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return AppExperienceModel(
      tripBookingButtonLabel: label(
        'trip_booking_button_label',
        'احجز من الاشتراك',
      ),
      tripBookedButtonLabel: label('trip_booked_button_label', 'تم الحجز'),
      announcementTitle: label('announcement_title', ''),
      announcementBody: label('announcement_body', ''),
      announcementImageUrl: label('announcement_image_url', ''),
      announcementLinkUrl: label('announcement_link_url', ''),
      announcementButtonLabel: label(
        'announcement_button_label',
        'اعرف المزيد',
      ),
      announcementIsActive: _parseBool(json['announcement_is_active']),
      announcementPopupEnabled: _parseBool(json['announcement_popup_enabled']),
    );
  }
}

class StudentSubscriptionModel {
  const StudentSubscriptionModel({
    required this.id,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.totalRides,
    required this.usedRides,
    required this.remainingRides,
    required this.remainingDays,
    required this.status,
    required this.isCurrent,
    required this.notes,
  });

  final int id;
  final String planName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalRides;
  final int usedRides;
  final int remainingRides;
  final int remainingDays;
  final String status;
  final bool isCurrent;
  final String notes;

  factory StudentSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return StudentSubscriptionModel(
      id: _parseInt(json['id']),
      planName: json['plan_name']?.toString() ?? '',
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      totalRides: _parseInt(json['total_rides']),
      usedRides: _parseInt(json['used_rides']),
      remainingRides: _parseInt(json['remaining_rides']),
      remainingDays: _parseInt(json['remaining_days']),
      status: json['status']?.toString() ?? '',
      isCurrent: _parseBool(json['is_current']),
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class ParentChildSummary {
  const ParentChildSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.faculty,
    required this.academicYear,
  });

  final int id;
  final String name;
  final String code;
  final String faculty;
  final String academicYear;

  factory ParentChildSummary.fromJson(Map<String, dynamic> json) {
    return ParentChildSummary(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? '',
    );
  }
}

class ParentSummaryModel {
  const ParentSummaryModel({
    required this.student,
    required this.subscriptions,
    required this.bookings,
    required this.payments,
  });

  final ParentChildSummary student;
  final List<StudentSubscriptionModel> subscriptions;
  final List<BookingModel> bookings;
  final List<PaymentModel> payments;

  factory ParentSummaryModel.fromJson(Map<String, dynamic> json) {
    final subscriptions = json['subscriptions'] as List<dynamic>? ?? const [];
    final bookings = json['bookings'] as List<dynamic>? ?? const [];
    final payments = json['payments'] as List<dynamic>? ?? const [];
    return ParentSummaryModel(
      student: ParentChildSummary.fromJson(
        json['student'] as Map<String, dynamic>? ?? const {},
      ),
      subscriptions: subscriptions
          .map(
            (item) => StudentSubscriptionModel.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
      bookings: bookings
          .map(
            (item) =>
                BookingModel.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      payments: payments
          .map(
            (item) =>
                PaymentModel.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

class SupervisorOverviewModel {
  const SupervisorOverviewModel({
    required this.todayTrips,
    required this.activeTrips,
    required this.studentsOnBoard,
    required this.completedTrips,
    required this.attendanceLogs,
    required this.recentScans,
    this.upcomingTrips = 0,
    this.upcomingBookings = 0,
    this.todayBookings = 0,
    this.nextTripDate,
  });

  final int todayTrips;
  final int activeTrips;
  final int studentsOnBoard;
  final int completedTrips;
  final int attendanceLogs;
  final List<ScanRecordModel> recentScans;
  final int upcomingTrips;
  final int upcomingBookings;
  final int todayBookings;
  final DateTime? nextTripDate;

  factory SupervisorOverviewModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    final recent = json['recent_scans'] as List<dynamic>? ?? const [];
    return SupervisorOverviewModel(
      todayTrips: _parseInt(stats['today_trips']),
      activeTrips: _parseInt(stats['active_trips']),
      studentsOnBoard: _parseInt(stats['students_on_board']),
      completedTrips: _parseInt(stats['completed_trips']),
      attendanceLogs: _parseInt(stats['attendance_logs']),
      upcomingTrips: _parseInt(stats['upcoming_trips']),
      upcomingBookings: _parseInt(stats['upcoming_bookings']),
      todayBookings: _parseInt(stats['today_bookings']),
      nextTripDate: _parseDateTime(json['next_trip_date']),
      recentScans: recent
          .map(
            (item) =>
                ScanRecordModel.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

class ScanRecordModel {
  const ScanRecordModel({
    required this.studentName,
    required this.tripCode,
    required this.scanType,
    required this.createdAt,
  });

  final String studentName;
  final String tripCode;
  final String scanType;
  final DateTime? createdAt;

  factory ScanRecordModel.fromJson(Map<String, dynamic> json) {
    return ScanRecordModel(
      studentName: json['student_name']?.toString() ?? '',
      tripCode: json['trip_code']?.toString() ?? '',
      scanType: json['scan_type']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class TrackingPayload {
  const TrackingPayload({
    required this.trip,
    required this.routePoints,
    required this.timeline,
  });

  final TripModel trip;
  final List<GeoPoint> routePoints;
  final List<GeoPoint> timeline;

  factory TrackingPayload.fromJson(Map<String, dynamic> json) {
    final routePoints = json['route_points'] as List<dynamic>? ?? const [];
    final timeline = json['timeline'] as List<dynamic>? ?? const [];
    return TrackingPayload(
      trip: TripModel.fromJson(
        json['trip'] as Map<String, dynamic>? ?? const {},
      ),
      routePoints: routePoints
          .map(
            (item) => GeoPoint.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      timeline: timeline
          .map(
            (item) => GeoPoint.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}
