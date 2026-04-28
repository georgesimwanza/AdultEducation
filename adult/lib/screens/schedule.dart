import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class Calendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final Function(DateTime?, DateTime?)? onRangeSelected;
  final Function(DateTime)? onDaySelected;

  const Calendar({
    required this.focusedDay,
    this.selectedStartDate,
    this.selectedEndDate,
    this.onRangeSelected,
    this.onDaySelected,
    super.key,
  });

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 1, 1),
      focusedDay: widget.focusedDay,
      rangeStartDay: widget.selectedStartDate,
      rangeEndDay: widget.selectedEndDate,

      // ✅ highlights the selected day
      selectedDayPredicate: (day) => isSameDay(widget.selectedStartDate, day),

      // ✅ fires when user taps a day
      onDaySelected: (selectedDay, focusedDay) {
        if (widget.onDaySelected != null) {
          widget.onDaySelected!(selectedDay);
        }
      },

      onRangeSelected: (start, end, _) {
        if (widget.onRangeSelected != null) {
          widget.onRangeSelected!(start, end);
        }
      },

      // ✅ toggledOff so single taps work
      rangeSelectionMode: RangeSelectionMode.toggledOff,

      calendarStyle: CalendarStyle(
        rangeHighlightColor: const Color.fromARGB(
          255,
          0,
          0,
          0,
        ).withOpacity(0.3),
        todayTextStyle: const TextStyle(fontSize: 20, fontFamily: 'Poppins'),
        todayDecoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          // ✅ shows tapped day in purple
          color: Colors.purple,
          shape: BoxShape.circle,
        ),
        defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
        rangeStartDecoration: const BoxDecoration(
          color: Color.fromARGB(255, 0, 0, 0),
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: const BoxDecoration(
          color: Color.fromARGB(255, 0, 0, 0),
          shape: BoxShape.circle,
        ),
        cellMargin: EdgeInsets.zero,
        defaultTextStyle: const TextStyle(fontSize: 20, fontFamily: 'Poppins'),
        weekendTextStyle: const TextStyle(
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: const TextStyle(
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
        ),
        weekendStyle: const TextStyle(
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
        ),
        dowTextFormatter: (date, locale) {
          return DateFormat.E(locale).format(date).substring(0, 1);
        },
      ),
      daysOfWeekHeight: 60,
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
      ),
    );
  }
}
