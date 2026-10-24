import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:terhal_mobile/src/api_service.dart';
import 'package:terhal_mobile/src/models.dart';
import 'package:terhal_mobile/src/session_controller.dart';

final student = UserProfile.fromJson({'id': 1, 'username': '01012345678', 'role': 'student', 'full_name': 'Student', 'student_profile': {'faculty': 'Old', 'academic_year': '1'}});
final updatedStudent = UserProfile.fromJson({'id': 1, 'username': '01012345678', 'role': 'student', 'full_name': 'Updated', 'student_profile': {'faculty': 'Engineering', 'academic_year': '3'}});

class FakeApi extends ApiService {
  bool failPayments = false;
  @override
  Future<AuthPayload> login({required String phoneNumber, required String password}) async => AuthPayload(user: student, accessToken: 'token', refreshToken: 'refresh');
  @override
  Future<UserProfile> me(String token) async => updatedStudent;
  @override
  Future<List<PaymentModel>> fetchPayments(String token) async {
    if (failPayments) throw Exception('offline');
    return [PaymentModel.fromJson({'id': 7, 'invoice_number': 'PAID-7', 'amount': '500.50', 'status': 'paid', 'payment_method': 'cash'})];
  }
  @override
  Future<StudentHomeModel> fetchStudentHome(String token) async => throw Exception('home unavailable');
  @override
  Future<List<TripModel>> fetchTrips(String token) async => [];
  @override
  Future<List<BookingModel>> fetchBookings(String token) async => [];
  @override
  Future<List<NotificationModel>> fetchNotifications(String token) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('failed home does not hide successful invoices or updated profile', () async {
    final controller = SessionController(FakeApi(), restoreSession: false);
    await controller.login(phoneNumber: '01012345678', password: 'test');
    expect(controller.state.paymentsLoaded, isTrue);
    expect(controller.state.payments.single.amount, 500.50);
    expect(controller.state.user!.studentProfile!.faculty, 'Engineering');
    expect(controller.state.user!.studentProfile!.academicYear, '3');
    controller.dispose();
  });
  test('failed invoice refresh retains last known invoices with an error', () async {
    final api = FakeApi();
    final controller = SessionController(api, restoreSession: false);
    await controller.login(phoneNumber: '01012345678', password: 'test');
    api.failPayments = true;
    await controller.refresh();
    expect(controller.state.payments.single.invoiceNumber, 'PAID-7');
    expect(controller.state.paymentsError, isNotNull);
    api.failPayments = false;
    await controller.refresh();
    expect(controller.state.paymentsError, isNull);
    controller.dispose();
  });
  test('initial failure is not presented as an empty invoice list', () async {
    final api = FakeApi()..failPayments = true;
    final controller = SessionController(api, restoreSession: false);
    await controller.login(phoneNumber: '01012345678', password: 'test');
    expect(controller.state.paymentsLoaded, isFalse);
    expect(controller.state.paymentsError, isNotNull);
    controller.dispose();
  });
}
