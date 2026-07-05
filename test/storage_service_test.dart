import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shuttle_mobile_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns null for malformed stored user data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', '{invalid json');

      final storageService = StorageService();
      final user = await storageService.getCurrentUser();

      expect(user, isNull);
    });
  });
}
