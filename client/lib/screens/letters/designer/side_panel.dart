import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/ui_text.dart';
import '../../../theme/app_colors.dart';

class _SysVar {
  final String token;
  final String label;
  const _SysVar(this.token, this.label);
}

List<_SysVar> _systemVars() => [
      _SysVar(r'{{user.name}}', UiText.userSFullName),
      _SysVar(r'{{user.email}}', UiText.userSEmail),
      _SysVar(r'{{company.name}}', UiText.companyName),
      _SysVar(r'{{date}}', UiText.currentDate),
      _SysVar(r'{{flow.name}}', UiText.flowName),
    ];

class SidePanel extends StatefulWidget {
  final bool isDark;
  final bool compact;
  final List<String> letterVariables;
  final List<PlatformFile> attachments;
  final ValueChanged<String> onInsertVariable;
  final ValueChanged<PlatformFile> onInsertAttachment;
  final VoidCallback onPickAttachment;
  final void Function(int index) onRemoveAttachment;
  final VoidCallback? onClose;

  const SidePanel({
    super.key,
    required this.isDark,
    required this.letterVariables,
    required this.attachments,
    required this.onInsertVariable,
    required this.onInsertAttachment,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
    this.compact = false,
    this.onClose,
  });

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    final content = Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              widget.compact ? 14 : 14, widget.compact ? 6 : 12, 6, 0),
          decoration: BoxDecoration(
            gradient: widget.compact
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: isDark ? 0.16 : 0.10),
                      accent.withValues(alpha: isDark ? 0.05 : 0.02),
                    ],
                  )
                : null,
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (widget.compact) ...[
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.78),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      'Library',
                      style: TextStyle(
                        fontSize: widget.compact ? 15 : 13,
                        fontWeight:
                            widget.compact ? FontWeight.w800 : FontWeight.w700,
                        letterSpacing: 0.4,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      onPressed: widget.onClose,
                    ),
                ],
              ),
              TabBar(
                controller: _tabs,
                labelColor: accent,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                indicatorColor: accent,
                indicatorWeight: widget.compact ? 2.4 : 2,
                labelStyle: TextStyle(
                    fontSize: widget.compact ? 13 : 12,
                    fontWeight: FontWeight.w800),
                tabs: const [
                  Tab(text: 'Variables'),
                  Tab(text: 'Attachments'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _VariablesTab(
                isDark: isDark,
                letterVariables: widget.letterVariables,
                onInsert: widget.onInsertVariable,
              ),
              _AttachmentsTab(
                isDark: isDark,
                attachments: widget.attachments,
                onPick: widget.onPickAttachment,
                onRemove: widget.onRemoveAttachment,
                onInsert: widget.onInsertAttachment,
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.compact) {
      return Container(color: bg, child: content);
    }
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: border)),
      ),
      child: content,
    );
  }
}

class _VariablesTab extends StatelessWidget {
  final bool isDark;
  final List<String> letterVariables;
  final ValueChanged<String> onInsert;

  const _VariablesTab({
    required this.isDark,
    required this.letterVariables,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    final sys = _systemVars();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      children: [
        _section('System'),
        for (final v in sys) _row(v.token, v.label),
        if (letterVariables.isNotEmpty) ...[
          const SizedBox(height: 14),
          _section('Template'),
          for (final v in letterVariables) _row('{{$v}}', v),
        ],
      ],
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Text(
          t.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      );

  Widget _row(String token, String label) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onInsert(token),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  token,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkText
                        : AppColors.lightText,
                  ),
                ),
              ),
              Icon(Icons.east_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentsTab extends StatelessWidget {
  final bool isDark;
  final List<PlatformFile> attachments;
  final VoidCallback onPick;
  final void Function(int index) onRemove;
  final ValueChanged<PlatformFile> onInsert;

  const _AttachmentsTab({
    required this.isDark,
    required this.attachments,
    required this.onPick,
    required this.onRemove,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPick,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file_rounded, color: accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upload files',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
                Icon(Icons.add_rounded, color: accent, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (attachments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(Icons.folder_open_rounded,
                    size: 28,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint),
                const SizedBox(height: 6),
                Text(
                  'No attachments yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        for (var i = 0; i < attachments.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _AttachmentRow(
              file: attachments[i],
              isDark: isDark,
              onInsert: () => onInsert(attachments[i]),
              onRemove: () => onRemove(i),
            ),
          ),
      ],
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final PlatformFile file;
  final bool isDark;
  final VoidCallback onInsert;
  final VoidCallback onRemove;

  const _AttachmentRow({
    required this.file,
    required this.isDark,
    required this.onInsert,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ext = file.extension ?? 'file';
    final size = file.size;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    String human(int s) {
      if (s < 1024) return '$s B';
      if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(1)} KB';
      return '${(s / 1024 / 1024).toStringAsFixed(1)} MB';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              ext.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkText
                        : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  human(size),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Insert on page',
            icon: Icon(Icons.add_to_photos_rounded, size: 16, color: accent),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onInsert,
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
