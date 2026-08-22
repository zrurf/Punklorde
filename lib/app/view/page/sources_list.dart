import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:punklorde/utils/etc/fdialog.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/resource/model.dart';
import 'package:punklorde/core/status/resource.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

class SourcesListPage extends StatelessWidget {
  const SourcesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final colors = context.theme.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.setting.sources_list),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
              suffixes: [
                FHeaderAction(
                  icon: const Icon(LucideIcons.plus),
                  onPress: () => _showSourceAddDialog(context),
                ),
              ],
            ),
            Expanded(
              child: SignalBuilder(
                builder: (context) {
                  final sources = resourceManager.sourcesSignal.value;

                  if (sources.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.separated(
                      itemCount: sources.length,
                      separatorBuilder: (_, _) => const FDivider(),
                      itemBuilder: (context, index) {
                        final source = sources[index];
                        return InkWell(
                          onTap: () => _showSourceEditDialog(context, source),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 4,
                                    children: [
                                      Text(
                                        source.id,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        source.baseUrl,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.mutedForeground,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Row(
                                        spacing: 4,
                                        children: [
                                          FBadge(
                                            variant: .secondary,
                                            child: Text(
                                              'P${source.priority}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          if (!source.enabled)
                                            FBadge(
                                              variant: .destructive,
                                              child: Text(t.label.expired),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 18,
                                  color: colors.mutedForeground,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Icon(LucideIcons.unlink, color: colors.primary, size: 24),
          Text(
            t.setting.source_no_sources,
            style: TextStyle(color: colors.mutedForeground, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSourceAddDialog(BuildContext context) {
    _showSourceFormDialog(context, null);
  }

  void _showSourceEditDialog(BuildContext context, Source source) {
    _showSourceFormDialog(context, source);
  }

  void _showSourceFormDialog(BuildContext context, Source? existing) {
    final t = Translations.of(context);
    final colors = context.theme.colors;
    final isEdit = existing != null;

    final idSignal = signal(existing?.id ?? '');
    final urlSignal = signal(existing?.baseUrl ?? '');
    final prioritySignal = signal((existing?.priority ?? 0).toString());
    final enabledSignal = signal(existing?.enabled ?? true);

    showFSheet(
      context: context,
      builder: (sheetContext) => Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? t.setting.source_edit : t.setting.source_add,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const FDivider(),
                FTextField(
                  control: .managed(
                    initial: TextEditingValue(text: idSignal.value),
                    onChange: (v) => idSignal.value = v.text,
                  ),
                  label: Text(t.setting.source_id),
                  hint: t.setting.source_id_hint,
                ),
                FTextField(
                  control: .managed(
                    initial: TextEditingValue(text: urlSignal.value),
                    onChange: (v) => urlSignal.value = v.text,
                  ),
                  label: Text(t.setting.source_url),
                  hint: t.setting.source_url_hint,
                ),
                FTextField(
                  control: .managed(
                    initial: TextEditingValue(text: prioritySignal.value),
                    onChange: (v) => prioritySignal.value = v.text,
                  ),
                  label: Text(t.setting.source_priority),
                  hint: t.setting.source_priority_hint,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.setting.source_enabled,
                      style: TextStyle(color: colors.foreground),
                    ),
                    SignalBuilder(
                      builder: (context) => Switch(
                        value: enabledSignal.value,
                        onChanged: (v) => enabledSignal.value = v,
                      ),
                    ),
                  ],
                ),
                if (isEdit)
                  FButton(
                    variant: .destructive,
                    size: .xs,
                    onPress: () {
                      Navigator.of(sheetContext).pop();
                      _showDeleteConfirmDialog(context, existing);
                    },
                    child: Text(t.setting.source_delete),
                  ),
                const FDivider(),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: FButton(
                        variant: .secondary,
                        size: .xs,
                        onPress: () => Navigator.of(sheetContext).pop(),
                        child: Text(t.notice.cancel),
                      ),
                    ),
                    Expanded(
                      child: FButton(
                        size: .xs,
                        onPress: () {
                          final id = idSignal.value;
                          final url = urlSignal.value;
                          if (id.isEmpty || url.isEmpty) return;

                          final source = Source(
                            id: id,
                            baseUrl: url,
                            priority: int.tryParse(prioritySignal.value) ?? 0,
                            enabled: enabledSignal.value,
                          );

                          if (isEdit) {
                            resourceManager.updateSource(existing.id, source);
                          } else {
                            resourceManager.addSource(source);
                          }

                          Navigator.of(sheetContext).pop();
                          showFToast(
                            context: context,
                            variant: .primary,
                            alignment: .topCenter,
                            title: Text(
                              isEdit
                                  ? t.setting.source_update_success
                                  : t.setting.source_add_success,
                            ),
                            duration: const Duration(seconds: 2),
                            icon: const Icon(LucideIcons.circleCheck),
                          );
                        },
                        child: Text(t.action.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      side: .btt,
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Source source) {
    final t = Translations.of(context);
    showFDialog(
      context: context,
      builder: (context, style, animation) => punklordeDialog(
        style: style,
        animation: animation,
        title: Text(t.setting.source_delete),
        body: Text(t.setting.source_delete_confirm),
        actions: [
          FButton(
            variant: .secondary,
            size: .xs,
            onPress: () => Navigator.of(context).pop(),
            child: Text(t.notice.cancel),
          ),
          FButton(
            variant: .destructive,
            size: .xs,
            onPress: () {
              resourceManager.removeSource(source.id);
              Navigator.of(context).pop();
              showFToast(
                context: context,
                variant: .destructive,
                alignment: .topCenter,
                title: Text(t.setting.source_delete_success),
                duration: const Duration(seconds: 2),
                icon: const Icon(LucideIcons.circleCheck),
              );
            },
            child: Text(t.action.delete),
          ),
        ],
      ),
    );
  }
}
