import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autocreat/providers/auth_provider.dart';
import 'package:autocreat/providers/theme_provider.dart';
import 'package:autocreat/models/user.dart';

Future<ProviderContainer> buildAuthContainer() async {
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
    ],
  );
}

void main() {
  group('AuthNotifier', () {
    test('initial state is null when not logged in', () async {
      final container = await buildAuthContainer();
      addTearDown(container.dispose);

      // Wait for the async build to complete.
      final user = await container.read(authProvider.future);
      expect(user, isNull);
    });

    test('loginAsDemoUser sets a demo user', () async {
      final container = await buildAuthContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.future); // ensure initialized
      container.read(authProvider.notifier).loginAsDemoUser();

      final user = container.read(authProvider).value;
      expect(user, isNotNull);
      expect(user!.email, 'demo@autocreat.io');
      expect(user.firstName, 'Demo');
      expect(user.lastName, 'User');
      expect(user.role, 'owner');
    });

    test('forceLogout clears auth state', () async {
      final container = await buildAuthContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.future); // ensure initialized
      // First log in as demo.
      container.read(authProvider.notifier).loginAsDemoUser();
      expect(container.read(authProvider).value, isNotNull);

      // Force logout.
      container.read(authProvider.notifier).forceLogout();
      expect(container.read(authProvider).value, isNull);
    });

    test('isAuthenticatedProvider is false initially', () async {
      final container = await buildAuthContainer();
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isFalse);
    });

    test('isAuthenticatedProvider is true after demo login', () async {
      final container = await buildAuthContainer();
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      container.read(authProvider.notifier).loginAsDemoUser();

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isTrue);
    });

    test('currentUserProvider is null initially', () async {
      final container = await buildAuthContainer();
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      final user = container.read(currentUserProvider);
      expect(user, isNull);
    });

    test('currentUserProvider returns user after demo login', () async {
      final container = await buildAuthContainer();
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      container.read(authProvider.notifier).loginAsDemoUser();

      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.email, 'demo@autocreat.io');
    });
  });

  group('User model', () {
    test('User.fromJson parses correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'alice@example.com',
        'firstName': 'Alice',
        'lastName': 'Smith',
        'role': 'member',
        'isActive': true,
        'permissions': <String>[],
      };

      // Since User is a Freezed class, fromJson works via generated code.
      // We test the fields we know about.
      final user = User.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.email, 'alice@example.com');
      expect(user.firstName, 'Alice');
      expect(user.lastName, 'Smith');
      expect(user.role, 'member');
      expect(user.isActive, isTrue);
    });

    test('User default role is owner', () {
      const user = User(
        id: 'id',
        email: 'test@test.com',
        firstName: 'First',
        lastName: 'Last',
      );
      expect(user.role, 'owner');
    });

    test('User fullName extension', () {
      const user = User(
        id: 'id',
        email: 'test@test.com',
        firstName: 'John',
        lastName: 'Doe',
      );
      expect(user.fullName, contains('John'));
      expect(user.fullName, contains('Doe'));
    });

    test('User initials extension', () {
      const user = User(
        id: 'id',
        email: 'test@test.com',
        firstName: 'John',
        lastName: 'Doe',
      );
      final initials = user.initials;
      expect(initials, contains('J'));
      expect(initials, contains('D'));
    });

    test('User isActive defaults to true', () {
      const user = User(
        id: 'id',
        email: 'test@test.com',
        firstName: 'F',
        lastName: 'L',
      );
      expect(user.isActive, isTrue);
    });

    test('User permissions defaults to empty list', () {
      const user = User(
        id: 'id',
        email: 'test@test.com',
        firstName: 'F',
        lastName: 'L',
      );
      expect(user.permissions, isEmpty);
    });
  });
}
