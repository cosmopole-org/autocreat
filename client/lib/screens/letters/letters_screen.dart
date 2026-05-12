import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/letter_template.dart';
import '../../providers/letter_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class LettersScreen extends ConsumerStatefulWidget {
  const LettersScreen({super.key});

  @override
  ConsumerState<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends ConsumerState<LettersScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createLetter(BuildContext context) async {
    final repo = ref.read(letterRepositoryProvider);
    final letter = await repo.createLetter({
      'name': 'New Letter Template',
      'status': 'draft',
      'content': '',
      'deltaContent': {},
    });
    if (context.mounted) context.go('/letters/${letter.id}/edit');
  }

  @override
  Widget build(BuildContext context) {
    final lettersAsync = ref.watch(letterNotifierProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchController,
                    hintText: 'Search templates...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'New Template',
                  icon: Icons.add,
                  onPressed: () => _createLetter(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: lettersAsync.when(
              loading: () => const LoadingGrid(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (letters) {
                final filtered = _search.isEmpty
                    ? letters
                    : letters
                        .where((l) => l.name
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No letter templates',
                    subtitle: 'Create reusable letter templates',
                    icon: Icons.mail_outline,
                    actionLabel: 'Create Template',
                    onAction: () => _createLetter(context),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 160,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _LetterCard(
                    letter: filtered[i],
                    onEdit: () =>
                        context.go('/letters/${filtered[i].id}/edit'),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => const ConfirmDialog(
                          title: 'Delete Template',
                          message: 'Delete this letter template?',
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(letterNotifierProvider.notifier)
                            .delete(filtered[i].id);
                      }
                    },
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final LetterTemplate letter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LetterCard({
    required this.letter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mail_outline,
                    color: AppColors.warning, size: 20),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: AppColors.error))),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ),
          const Spacer(),
          Text(
            letter.name,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (letter.description != null)
            Text(
              letter.description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusChip(status: letter.status),
              const Spacer(),
              if (letter.category != null)
                Text(letter.category!,
                    style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
