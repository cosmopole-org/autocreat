/// Client-side demo data providers.
///
/// Each provider in this file returns the corresponding [DemoData] constant
/// directly — no HTTP call is made.  Screens that want to support demo mode
/// should watch [isDemoModeProvider] and, when it is `true`, watch the
/// `demo*Provider` instead of the real API-backed provider.
///
/// Example usage inside a widget:
/// ```dart
/// final isDemo = ref.watch(isDemoModeProvider);
/// final ticketsAsync = isDemo
///     ? AsyncValue.data(ref.watch(demoTicketsProvider))
///     : ref.watch(ticketsProvider(null));
/// ```
library demo_overrides;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company.dart';
import '../models/flow.dart';
import '../models/form_definition.dart';
import '../models/letter_template.dart';
import '../models/model_definition.dart';
import '../models/role.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../providers/demo_provider.dart';
import 'demo_data.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Raw-map providers (instant, zero cost)
// ──────────────────────────────────────────────────────────────────────────────

/// All users as raw maps (matches [User.fromJson] shape).
final demoUsersProvider =
    Provider<List<Map<String, dynamic>>>((ref) => DemoData.users);

/// All roles as raw maps (matches [Role.fromJson] shape).
final demoRolesProvider =
    Provider<List<Map<String, dynamic>>>((ref) => DemoData.roles);

/// All flows as raw maps (matches [Flow.fromJson] shape).
final demoFlowsProvider =
    Provider<List<Map<String, dynamic>>>((ref) => DemoData.flows);

/// All forms as raw maps (matches [FormDefinition.fromJson] shape).
final demoFormsProvider =
    Provider<List<Map<String, dynamic>>>((ref) => DemoData.forms);

/// All letter templates as raw maps (matches [LetterTemplate.fromJson] shape).
final demoLettersProvider =
    Provider<List<Map<String, dynamic>>>((ref) => DemoData.letters);

/// All model definitions as raw maps (matches [ModelDefinition.fromJson] shape).
final demoModelsProvider =
    Provider<List<Map<String, dynamic>>>((ref) => DemoData.models);

/// All tickets as raw maps (matches [Ticket.fromJson] shape).
final demoTicketsProvider =
    Provider<List<Map<String, dynamic>>>((ref) => DemoData.tickets);

/// Dashboard stats map.
final demoStatsProvider =
    Provider<Map<String, dynamic>>((ref) => DemoData.stats);

/// Company data map (matches [Company.fromJson] shape).
final demoCompanyProvider =
    Provider<Map<String, dynamic>>((ref) => DemoData.company);

/// Flow instances raw maps.
final demoInstancesProvider =
    Provider<List<Map<String, dynamic>>>((ref) => DemoData.instances);

// ──────────────────────────────────────────────────────────────────────────────
// Typed model providers — deserialized from the raw maps above.
// These are the drop-in equivalents for the API-backed providers and return
// the same model types so existing widgets can accept them without changes.
// ──────────────────────────────────────────────────────────────────────────────

/// Demo equivalent of `usersProvider(null)`.
final demoTypedUsersProvider = Provider<AsyncValue<List<User>>>((ref) {
  final maps = ref.watch(demoUsersProvider);
  return AsyncValue.data(maps.map(User.fromJson).toList());
});

/// Demo equivalent of `companiesProvider`.
final demoTypedCompaniesProvider = Provider<AsyncValue<List<Company>>>((ref) {
  return AsyncValue.data([Company.fromJson(DemoData.company)]);
});

/// Demo equivalent of `flowsProvider(null)`.
final demoTypedFlowsProvider = Provider<AsyncValue<List<Flow>>>((ref) {
  final maps = ref.watch(demoFlowsProvider);
  return AsyncValue.data(maps.map(Flow.fromJson).toList());
});

/// Demo equivalent of `ticketsProvider(null)`.
final demoTypedTicketsProvider = Provider<AsyncValue<List<Ticket>>>((ref) {
  final maps = ref.watch(demoTicketsProvider);
  return AsyncValue.data(maps.map(Ticket.fromJson).toList());
});

/// Demo equivalent of `formsProvider`.
final demoTypedFormsProvider =
    Provider<AsyncValue<List<FormDefinition>>>((ref) {
  final maps = ref.watch(demoFormsProvider);
  return AsyncValue.data(maps.map(FormDefinition.fromJson).toList());
});

/// Demo equivalent of `lettersProvider`.
final demoTypedLettersProvider =
    Provider<AsyncValue<List<LetterTemplate>>>((ref) {
  final maps = ref.watch(demoLettersProvider);
  return AsyncValue.data(maps.map(LetterTemplate.fromJson).toList());
});

/// Demo equivalent of `modelsProvider`.
final demoTypedModelsProvider =
    Provider<AsyncValue<List<ModelDefinition>>>((ref) {
  final maps = ref.watch(demoModelsProvider);
  return AsyncValue.data(maps.map(ModelDefinition.fromJson).toList());
});

/// Demo equivalent of `rolesProvider`.
final demoTypedRolesProvider = Provider<AsyncValue<List<Role>>>((ref) {
  final maps = ref.watch(demoRolesProvider);
  return AsyncValue.data(maps.map(Role.fromJson).toList());
});

/// The authenticated demo [User] derived from [DemoData.currentUser].
final demoCurrentUserProvider = Provider<User?>((ref) {
  return User.fromJson(DemoData.currentUser);
});

// ──────────────────────────────────────────────────────────────────────────────
// Convenience: isDemo-aware selectors.
//
// These providers transparently switch between the real and demo data sources
// based on [isDemoModeProvider].  Widgets can watch these instead of watching
// `isDemoModeProvider` themselves and manually branching.
// ──────────────────────────────────────────────────────────────────────────────

/// Returns the demo [User] when in demo mode, or `null` otherwise (so the
/// real [currentUserProvider] from auth_provider.dart still governs auth).
final demoAwareCurrentUserProvider = Provider<User?>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  if (!isDemo) return null;
  return ref.watch(demoCurrentUserProvider);
});

/// Returns `AsyncValue<List<Ticket>>` from demo data when in demo mode.
final demoAwareTicketsProvider = Provider<AsyncValue<List<Ticket>>>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  if (!isDemo) return const AsyncValue.loading();
  return ref.watch(demoTypedTicketsProvider);
});

/// Returns `AsyncValue<List<Flow>>` from demo data when in demo mode.
final demoAwareFlowsProvider = Provider<AsyncValue<List<Flow>>>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  if (!isDemo) return const AsyncValue.loading();
  return ref.watch(demoTypedFlowsProvider);
});

/// Returns `AsyncValue<List<Company>>` from demo data when in demo mode.
final demoAwareCompaniesProvider = Provider<AsyncValue<List<Company>>>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  if (!isDemo) return const AsyncValue.loading();
  return ref.watch(demoTypedCompaniesProvider);
});
