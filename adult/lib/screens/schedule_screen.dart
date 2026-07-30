import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
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

  /// Builds a full 6-row month grid, padding with the trailing days of the
  /// previous month and the leading days of the next month, Monday-first.
  List<DateTime> _buildMonthGrid(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingBlanks));
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  void _showAddScheduleSheet(DateTime day) {
    final titleController = TextEditingController();
    String? startTime;
    String? endTime;

    final email = context.read<AuthController>().currentUser?.email ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Schedule — ${day.day}/${day.month}/${day.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextField(
                    controller: titleController,
                    cursorColor: Colors.black,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.access_time,
                            color: Colors.black,
                          ),
                          label: Text(
                            startTime ?? 'Start Time',
                            style: const TextStyle(color: Colors.black),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.black,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              final formatted =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              setSheetState(() => startTime = formatted);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.access_time_filled,
                            color: Colors.black,
                          ),
                          label: Text(
                            endTime ?? 'End Time',
                            style: const TextStyle(color: Colors.black),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.black,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              final formatted =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              setSheetState(() => endTime = formatted);
                            }
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
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            ctrl.errorMessage!,
                            style: const TextStyle(color: Colors.red),
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
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: ctrl.isLoading
                              ? null
                              : () async {
                                  if (titleController.text.trim().isEmpty ||
                                      startTime == null ||
                                      endTime == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.black,
                                        content: Text(
                                          'Please fill in all fields',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
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
                                  }
                                },
                          child: ctrl.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Schedule',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScheduleController>();
    final dayEntries = _selectedDay != null
        ? controller.entriesForDay(_selectedDay!)
        : const [];
    final grid = _buildMonthGrid(_visibleMonth);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      body: controller.isLoading && controller.entries.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.black,
                              ),
                              onPressed: () => _changeMonth(-1),
                            ),
                            Text(
                              '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.black,
                              ),
                              onPressed: () => _changeMonth(1),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _goToToday,
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF0F0F0),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _weekdayLabels
                          .map(
                            (d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1,
                          ),
                      itemCount: grid.length,
                      itemBuilder: (context, index) {
                        final day = grid[index];
                        final inCurrentMonth = day.month == _visibleMonth.month;
                        final isSelected =
                            _selectedDay != null &&
                            _isSameDay(day, _selectedDay!);
                        final isToday = _isSameDay(day, today);
                        final hasEntries = controller
                            .entriesForDay(day)
                            .isNotEmpty;

                        return GestureDetector(
                          onTap: () => _onDayTapped(day),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isToday && !isSelected
                                    ? Border.all(
                                        color: Colors.black,
                                        width: 1.4,
                                      )
                                    : null,
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
                                          ? Colors.white
                                          : inCurrentMonth
                                          ? Colors.black
                                          : Colors.black26,
                                    ),
                                  ),
                                  if (hasEntries && !isSelected)
                                    Positioned(
                                      bottom: 4,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
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
                  ),
                  const Divider(color: Colors.black12, height: 24),
                  if (_selectedDay != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Schedule for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: dayEntries.isEmpty
                        ? const Center(
                            child: Text(
                              'No schedule for this day.\nTap the + button to add one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                            itemCount: dayEntries.length,
                            itemBuilder: (context, index) {
                              final entry = dayEntries[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7F7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.black,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.title,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${entry.startTime} - ${entry.endTime}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.black45,
                                      ),
                                      onPressed: () => entry.id != null
                                          ? controller.deleteEntry(entry.id!)
                                          : null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => _showAddScheduleSheet(_selectedDay ?? DateTime.now()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
