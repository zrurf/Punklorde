import 'package:flutter/material.dart';
import 'package:built_collection/built_collection.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/schedule.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/module/model/semester.dart';
import 'package:punklorde/utils/uuid.dart';
import 'package:signals/signals_flutter.dart';

/// 打开自定义日程编辑面板
void showCustomEventEditor(BuildContext context, {ScheduleEvent? event}) {
  final semester = currentSemesterSignal.value;
  final slots = currentSchoolSignal.value?.scheduleServices.slots ?? [];
  if (semester == null || slots.isEmpty) return;

  showFSheet(
    context: context,
    builder: (sheetContext) =>
        _CustomEventEditorSheet(event: event, semester: semester, slots: slots),
    side: .btt,
  );
}

/// 自定义日程编辑底部面板
class _CustomEventEditorSheet extends SignalStatefulWidget {
  final ScheduleEvent? event;
  final Semester semester;
  final List<TimeSlot> slots;

  const _CustomEventEditorSheet({
    this.event,
    required this.semester,
    required this.slots,
  });

  @override
  State<_CustomEventEditorSheet> createState() =>
      _CustomEventEditorSheetState();
}

class _CustomEventEditorSheetState extends State<_CustomEventEditorSheet> {
  late final Signal<String> _title;
  late final Signal<String> _desc;
  late final Signal<String> _location;
  late final Signal<int> _selectedDay;
  late final Signal<int> _selectedSlotIndex;
  late final Signal<int> _slotSpan;
  late final Signal<Set<int>> _selectedWeeks;
  late final Signal<int> _selectedColor;
  late final TextEditingController _hexController;

  Coordinate? _pickedCoordinate;

  bool get _isEditing => widget.event != null;

  static const List<({int color, String label})> _colorOptions = [
    (color: 0xFF2177B8, label: '蓝'),
    (color: 0xFF4A4266, label: '紫'),
    (color: 0xFFCD6227, label: '橙'),
    (color: 0xFF758A99, label: '灰'),
    (color: 0xFF2E7D32, label: '绿'),
    (color: 0xFFC62828, label: '红'),
    (color: 0xFF6A1B9A, label: '深紫'),
    (color: 0xFF00838F, label: '青'),
    (color: 0xFFBF360C, label: '深赤'),
    (color: 0xFF283593, label: '靛蓝'),
    (color: 0xFFE65100, label: '深橙'),
    (color: 0xFF1B5E20, label: '深绿'),
  ];

  final _dayLabels = [
    t.label.calender_mon,
    t.label.calender_tue,
    t.label.calender_wed,
    t.label.calender_thu,
    t.label.calender_fri,
    t.label.calender_sat,
    t.label.calender_sun,
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _title = signal(ev?.title ?? '');
    _desc = signal(ev?.description ?? '');
    _location = signal(ev?.location ?? '');
    _selectedDay = signal(ev?.activeDay ?? 1);
    _selectedSlotIndex = signal(ev?.timeSlotIndex ?? 1);
    _slotSpan = signal(ev?.timeSlotCount ?? 1);
    _selectedWeeks = signal(
      (ev?.activeWeeks != null) ? Set.from(ev!.activeWeeks!) : <int>{},
    );
    _selectedColor = signal(ev?.color ?? _colorOptions[0].color);
    _hexController = TextEditingController(
      text: _colorToHex(_selectedColor.value),
    );

    // 当预设颜色改变时，同步更新 Hex 输入框
    effect(() {
      _hexController.text = _colorToHex(_selectedColor.value);
    });
  }

  int get _maxSpan => widget.slots.length - _selectedSlotIndex.value + 1;

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.value.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final id = _isEditing
        ? widget.event!.id
        : 'custom_${DeterministicUuidUtil.generate('${now.millisecondsSinceEpoch}_$title')}';

    final event = ScheduleEvent(
      id: id,
      type: ScheduleEventType.custom,
      anchor: ScheduleAnchor.slot,
      title: title,
      description: _desc.value.trim().isEmpty ? null : _desc.value.trim(),
      location: _location.value.trim().isEmpty ? null : _location.value.trim(),
      activeDay: _selectedDay.value,
      activeWeeks: _selectedWeeks.value.toList()..sort(),
      timeSlotIndex: _selectedSlotIndex.value,
      timeSlotCount: _slotSpan.value,
      color: _selectedColor.value,
      ext: _pickedCoordinate != null
          ? {'lat': _pickedCoordinate!.lat, 'lng': _pickedCoordinate!.lng}
          : null,
    );

    final current = scheduleCustomEventsSignal.value.asMap();
    final updated = Map<String, ScheduleEvent>.from(current);
    updated[id] = event;
    scheduleCustomEventsSignal.value = buildMapFromMap(updated);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _delete() {
    if (!_isEditing) return;
    final current = scheduleCustomEventsSignal.value.asMap();
    final updated = Map<String, ScheduleEvent>.from(current);
    updated.remove(widget.event!.id);
    scheduleCustomEventsSignal.value = buildMapFromMap(updated);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _applyHexColor() {
    final hex = _hexController.text.trim().replaceAll('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed != null) {
      _selectedColor.value = parsed;
    }
  }

  String _colorToHex(int color) {
    return '#${color.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: true,
        child: Container(
          height: .infinity,
          width: .infinity,
          decoration: BoxDecoration(
            color: colors.background,
            border: .symmetric(horizontal: BorderSide(color: colors.border)),
          ),
          child: SingleChildScrollView(
            padding: const .symmetric(horizontal: 16, vertical: 60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  spacing: 16,
                  children: [
                    // 标题行
                    _buildHeader(colors),
                    const FDivider(),

                    // 基本信息区域
                    _buildSectionLabel(t.title.basic_info),
                    FTextField(
                      label: Text(t.title.schedule_title),
                      description: Text(t.notice.schedule_title_hint),
                      control: .managed(
                        initial: TextEditingValue(text: _title.value),
                        onChange: (v) => _title.value = v.text,
                      ),
                    ),
                    FTextField(
                      label: Text(t.title.schedule_description),
                      control: .managed(
                        initial: TextEditingValue(text: _desc.value),
                        onChange: (v) => _desc.value = v.text,
                      ),
                    ),
                    FTextField(
                      label: Text(t.title.location),
                      control: .managed(
                        initial: TextEditingValue(text: _location.value),
                        onChange: (v) => _location.value = v.text,
                      ),
                    ),

                    const FDivider(),

                    // 时间安排区域
                    _buildSectionLabel(t.title.time_schedule),

                    // 星期 / 节次 / 跨节数 —— 多轮 Picker
                    SignalBuilder(
                      builder: (_) {
                        final dayIndex = _selectedDay.value - 1;
                        final slotIndex = widget.slots
                            .indexWhere(
                              (s) => s.index == _selectedSlotIndex.value,
                            )
                            .clamp(0, widget.slots.length - 1);
                        final mx = _maxSpan;
                        final spanIndex = _slotSpan.value.clamp(1, mx) - 1;

                        return SizedBox(
                          height: 150,
                          child: FPicker(
                            key: ValueKey('time_picker_$mx'),
                            control: FPickerControl.managed(
                              initial: [dayIndex, slotIndex, spanIndex],
                              onChange: (v) {
                                _selectedDay.value = v[0] + 1;
                                final newSlotIndex = widget.slots[v[1]].index;
                                _selectedSlotIndex.value = newSlotIndex;
                                final newSpan = v[2] + 1;
                                if (newSpan > _maxSpan) {
                                  _slotSpan.value = _maxSpan;
                                } else {
                                  _slotSpan.value = newSpan;
                                }
                              },
                            ),
                            children: [
                              FPickerWheel(
                                flex: 1,
                                children: [
                                  for (int i = 0; i < 7; i++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        _dayLabels[i],
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                ],
                              ),
                              FPickerWheel(
                                flex: 2,
                                children: [
                                  for (final slot in widget.slots)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        slot.name,
                                        overflow: .fade,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                ],
                              ),
                              FPickerWheel(
                                flex: 1,
                                children: [
                                  for (int i = 1; i <= mx; i++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        '$i节',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const FDivider(),

                    // 周次选择
                    _buildSectionLabel(t.title.schedule_weeks),
                    Row(
                      spacing: 8,
                      children: [
                        FButton(
                          variant: .secondary,
                          size: .xs,
                          onPress: () {
                            _selectedWeeks.value = {
                              for (int w = 1; w <= widget.semester.week; w++) w,
                            };
                          },
                          child: const Text(
                            '全选',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        FButton(
                          variant: .secondary,
                          size: .xs,
                          onPress: () => _selectedWeeks.value = {},
                          child: const Text(
                            '清空',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_selectedWeeks.value.length}/${widget.semester.week}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SignalBuilder(
                      builder: (_) {
                        return Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (int w = 1; w <= widget.semester.week; w++)
                              _buildWeekChip(w, colors),
                          ],
                        );
                      },
                    ),

                    const FDivider(),

                    // 颜色选择
                    _buildSectionLabel(t.title.schedule_color),
                    SignalBuilder(
                      builder: (_) {
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final opt in _colorOptions)
                              GestureDetector(
                                onTap: () => _selectedColor.value = opt.color,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Color(opt.color),
                                    shape: BoxShape.circle,
                                    border: _selectedColor.value == opt.color
                                        ? Border.all(
                                            color: colors.foreground,
                                            width: 2.5,
                                          )
                                        : Border.all(
                                            color: colors.border,
                                            width: 0.5,
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    // 自定义 Hex —— 始终显示当前颜色的 Hex，可直接修改
                    _buildLabel('Hex 颜色'),
                    SignalBuilder(
                      builder: (_) {
                        return Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: FTextField(
                                control: .managed(controller: _hexController),
                                hint: '#AARRGGBB',
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Color(_selectedColor.value),
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.border),
                              ),
                            ),
                            FButton(
                              variant: .secondary,
                              size: .xs,
                              onPress: _applyHexColor,
                              child: const Text(
                                '应用',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const FDivider(),

                    // 底部按钮
                    Row(
                      spacing: 16,
                      children: [
                        Expanded(
                          child: FButton(
                            variant: .secondary,
                            size: .sm,
                            onPress: () => Navigator.of(context).pop(),
                            child: Text(t.notice.cancel),
                          ),
                        ),
                        Expanded(
                          child: FButton(
                            variant: .primary,
                            size: .sm,
                            onPress: _save,
                            prefix: const Icon(LucideIcons.check, size: 18),
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
        ),
      ),
    );
  }

  Widget _buildHeader(FColors colors) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _isEditing ? t.title.edit_custom_event : t.title.add_custom_event,
            style: TextStyle(
              fontSize: 25,
              fontWeight: .bold,
              color: colors.foreground,
            ),
          ),
        ),
        if (_isEditing)
          FButton(
            variant: .destructive,
            size: .sm,
            onPress: _delete,
            prefix: const Icon(LucideIcons.trash2, size: 16),
            child: Text(t.action.delete),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.theme.colors.mutedForeground,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.theme.colors.foreground,
      ),
    );
  }

  Widget _buildWeekChip(int week, FColors colors) {
    final selected = _selectedWeeks.value.contains(week);
    return GestureDetector(
      onTap: () {
        final updated = Set<int>.from(_selectedWeeks.value);
        if (selected) {
          updated.remove(week);
        } else {
          updated.add(week);
        }
        _selectedWeeks.value = updated;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$week',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? colors.primaryForeground : colors.foreground,
          ),
        ),
      ),
    );
  }
}

/// Helper: 从 Map 构建 BuiltMap
BuiltMap<String, ScheduleEvent> buildMapFromMap(
  Map<String, ScheduleEvent> map,
) {
  return BuiltMap<String, ScheduleEvent>(map);
}
