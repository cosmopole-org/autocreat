import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/ui_text.dart';
import '../providers/flow_provider.dart';
import '../providers/form_provider.dart';
import '../providers/letter_provider.dart';
import '../providers/model_provider.dart';

/// Centralised "+ New X" handlers so creation buttons surfaced outside of
/// each entity's list screen (dashboard quick actions, company detail,
/// secondary panels, etc.) all funnel through the same logic and end up
/// on the correct editor route.
///
/// For flows/forms/models/letters we create a draft record via the
/// repository then push to its `/edit` route.  For users/roles the editor
/// itself handles the `new` id, so we just push.  Tickets/companies use
/// dialogs that live with their list screens, so for those we navigate to
/// the list with a query flag the list screen reads to auto-open its
/// create dialog.
class CreateActions {
  const CreateActions._();

  static Future<void> createFlow(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(flowRepositoryProvider);
    final flow = await repo.createFlow({
      'name': UiText.newFlow,
      'status': 'draft',
      'nodes': [
        {
          'id': 'start_1',
          'label': UiText.start,
          'type': 'start',
          'x': 100.0,
          'y': 200.0,
          'width': 160.0,
          'height': 60.0,
        },
        {
          'id': 'end_1',
          'label': UiText.end,
          'type': 'end',
          'x': 400.0,
          'y': 200.0,
          'width': 160.0,
          'height': 60.0,
        },
      ],
      'edges': [],
    });
    if (context.mounted) context.push('/flows/${flow.id}/edit');
  }

  static Future<void> createForm(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(formRepositoryProvider);
    final form = await repo.createForm({
      'name': UiText.newForm,
      'status': 'draft',
      'fields': [],
    });
    if (context.mounted) context.push('/forms/${form.id}/edit');
  }

  static Future<void> createModel(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(modelRepositoryProvider);
    final model = await repo.createModel({
      'name': UiText.newModel,
      'fields': [],
    });
    if (context.mounted) context.push('/models/${model.id}/edit');
  }

  static Future<void> createLetter(
      BuildContext context, WidgetRef ref) async {
    final repo = ref.read(letterRepositoryProvider);
    final letter = await repo.createLetter({
      'name': UiText.newLetterTemplate,
      'status': 'draft',
      'content': '',
      UiText.deltacontent: {},
    });
    if (context.mounted) context.push('/letters/${letter.id}/edit');
  }

  static void createUser(BuildContext context) {
    context.push('/users/new/edit');
  }

  static void createRole(BuildContext context) {
    context.push('/roles/new/edit');
  }

  /// Tickets are created via a dialog that lives inside the tickets list
  /// screen.  Navigating with `?create=1` asks that screen to open the
  /// dialog automatically on first build.
  static void createTicket(BuildContext context) {
    context.go('/tickets?create=1');
  }

  /// Companies (list) is itself a secondary route whose own create dialog
  /// lives on its screen.  Same `?create=1` convention.
  static void createCompany(BuildContext context) {
    context.push('/companies?create=1');
  }
}
