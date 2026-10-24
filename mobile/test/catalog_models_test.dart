import 'package:flutter_test/flutter_test.dart';
import 'package:terhal_mobile/src/models.dart';

void main() {
  test('parses campus and campus-scoped pickup stop', () {
    final campus = CampusModel.fromJson({
      'code': 'BNU',
      'name': 'جامعة بنها الأهلية',
      'city': 'العبور - القليوبية',
    });
    final stop = StopModel.fromJson({
      'id': 1,
      'name': 'نقطة ركوب الزقازيق',
      'address': 'الزقازيق',
      'latitude': '30.587700',
      'longitude': '31.502000',
      'campus_name': campus.name,
      'campus_code': campus.code,
    });

    expect(campus.code, 'BNU');
    expect(stop.campusCode, campus.code);
    expect(stop.campusName, campus.name);
  });
}
