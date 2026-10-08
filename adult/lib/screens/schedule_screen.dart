import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adult/screens/color.dart';
import '../Controller/auth_controller.dart';
import '../Controller/schedule_controller.dart';
import '../model/schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  static const List<String> _weekdayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Future.microtask(() {
      final email = context.read<AuthController>().currentUser?.email;
      if (email != null) {
        context.read<ScheduleController>().loadEntries(email);
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _goToToday() {
    setState(() {
      _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
      _selectedDay = DateTime.now();
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _onDayTapped(DateTime day) {
    setState(() => _selectedDay = day);
  }

  /// Full 6-row month grid, padded with neighbouring months, Monday-first.
  List<DateTime> _buildMonthGrid(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingBlanks));
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  String _formatDay(DateTime d) =>
      '${d.day} ${_monthNames[d.month - 1].substring(0, 3)} ${d.year}';

  Future<String?> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: EduColors.primary,
              onPrimary: EduColors.onPrimary,
              onSurface: EduColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Widget _timeButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? EduColors.primarySoft : EduColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? EduColors.primary : EduColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: filled ? EduColors.primary : EduColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled
                      ? EduColors.primary
                      : EduColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleSheet(DateTime day) {
    final titleController = TextEditingController();
    String? startTime;
    String? endTime;

    final email = context.read<AuthController>().currentUser?.email ?? '';
    // Captured before the sheet's own `context` shadows it, so the success
    // message can show on the main screen after the sheet closes.
    final rootMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EduColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: EduColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Add schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                      color: EduColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: EduColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 14, color: EduColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _formatDay(day),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: EduColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  TextField(
                    controller: titleController,
                    cursorColor: EduColors.primary,
                    style: const TextStyle(
                        color: EduColors.textPrimary, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle:
                      const TextStyle(color: EduColors.textSecondary),
                      floatingLabelStyle:
                      const TextStyle(color: EduColors.primary),
                      filled: true,
                      fillColor: EduColors.background,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: EduColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: EduColors.primary, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: _timeButton(
                          icon: Icons.access_time_rounded,
                          label: startTime ?? 'Start time',
                          filled: startTime != null,
                          onPressed: () async {
                            final t = await _pickTime(context);
                            if (t != null) setSheetState(() => startTime = t);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timeButton(
                          icon: Icons.access_time_filled_rounded,
                          label: endTime ?? 'End time',
                          filled: endTime != null,
                          onPressed: () async {
                            final t = await _pickTime(context);
                            if (t != null) setSheetState(() => endTime = t);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Error message
                  Consumer<ScheduleController>(
                    builder: (context, ctrl, _) {
                      if (ctrl.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: EduColors.danger, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ctrl.errorMessage!,
                                  style: const TextStyle(
                                      color: EduColors.danger, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Save button
                  Consumer<ScheduleController>(
                    builder: (context, ctrl, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EduColors.primary,
                            foregroundColor: EduColors.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: ctrl.isLoading
                              ? null
                              : () async {
                            if (titleController.text.trim().isEmpty ||
                                startTime == null ||
                                endTime == null) {
                              _showSnack(
                                ScaffoldMessenger.of(context),
                                'Please fill in all fields',
                                isError: true,
                              );
                              return;
                            }

                            // "HH:mm" strings compare correctly as text.
                            if (endTime!.compareTo(startTime!) <= 0) {
                              _showSnack(
                                ScaffoldMessenger.of(context),
                                'End time must be after start time',
                                isError: true,
                              );
                              return;
                            }

                            final entry = ScheduleEntry(
                              title: titleController.text.trim(),
                              userEmail: email,
                              date: day,
                              startTime: startTime!,
                              endTime: endTime!,
                            );

                            await ctrl.addEntry(entry);

                            if (ctrl.errorMessage == null &&
                                context.mounted) {
                              Navigator.pop(context);
                              _showSnack(
                                rootMessenger,
                                'Schedule added successfully',
                              );
                            }
                          },
                          child: ctrl.isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: EduColors.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Save schedule',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(ScaffoldMessengerState messenger, String text,
      {bool isError = false}) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? EduColors.danger : EduColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? EduColors.onPrimary : EduColors.success,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: EduColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScheduleController>();
    final dayEntries = _selectedDay != null
        ? controller.entriesForDay(_selectedDay!)
        : const [];
    final grid = _buildMonthGrid(_visibleMonth);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: EduColors.background,
      body: controller.isLoading && controller.entries.isEmpty
          ? const Center(
          child: CircularProgressIndicator(color: EduColors.primary))
          : SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildCalendarCard(controller, grid, today),
            ),
            const SizedBox(height: 22),
            if (_selectedDay != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSameDay(_selectedDay!, today)
                          ? 'Today'
                          : _formatDay(_selectedDay!),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: EduColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EduColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${dayEntries.length} ${dayEntries.length == 1 ? 'event' : 'events'}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: EduColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: dayEntries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: dayEntries.length,
                itemBuilder: (context, index) {
                  return _buildEntryCard(
                      dayEntries[index], controller);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: EduColors.primary,
        foregroundColor: EduColors.onPrimary,
        elevation: 4,
        onPressed: () => _showAddScheduleSheet(_selectedDay ?? DateTime.now()),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: EduColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: EduColors.border),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: EduColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Schedule',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: EduColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _goToToday,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: EduColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: EduColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
      ScheduleController controller,
      List<DateTime> grid,
      DateTime today,
      ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: EduColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    color: EduColors.textPrimary),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: EduColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded,
                    color: EduColors.textPrimary),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: _weekdayLabels
                  .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: EduColors.textSecondary,
                    ),
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: grid.length,
            itemBuilder: (context, index) {
              final day = grid[index];
              final inCurrentMonth = day.month == _visibleMonth.month;
              final isSelected =
                  _selectedDay != null && _isSameDay(day, _selectedDay!);
              final isToday = _isSameDay(day, today);
              final hasEntries = controller.entriesForDay(day).isNotEmpty;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onDayTapped(day),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? EduColors.primary
                          : isToday
                          ? EduColors.primarySoft
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? EduColors.onPrimary
                                : isToday
                                ? EduColors.primary
                                : inCurrentMonth
                                ? EduColors.textPrimary
                                : EduColors.border,
                          ),
                        ),
                        if (hasEntries)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? EduColors.onPrimary
                                    : EduColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: EduColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: EduColors.primary, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nothing scheduled',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: EduColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap Add to plan something for this day.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: EduColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(dynamic entry, ScheduleController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: EduColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: EduColors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: EduColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: EduColors.primarySoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 13, color: EduColors.primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${entry.startTime} – ${entry.endTime}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: EduColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: EduColors.textSecondary,
                        ),
                        onPressed: () => entry.id != null
                            ? controller.deleteEntry(entry.id!)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}