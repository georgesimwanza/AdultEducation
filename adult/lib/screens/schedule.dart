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
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        color: Colors.white,
        child: TableCalendar(
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 1, 1),
          focusedDay: widget.focusedDay,
          rangeStartDay: widget.selectedStartDate,
          rangeEndDay: widget.selectedEndDate,
          selectedDayPredicate: (day) =>
              isSameDay(widget.selectedStartDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            widget.onDaySelected?.call(selectedDay);
          },
          onRangeSelected: (start, end, _) {
            widget.onRangeSelected?.call(start, end);
          },
          rangeSelectionMode: RangeSelectionMode.toggledOff,
          calendarStyle: CalendarStyle(
            rangeHighlightColor: Colors.black.withOpacity(0.15),
            // Today
            todayTextStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
            todayDecoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              shape: BoxShape.circle,
            ),
            // Selected
            selectedTextStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            // Range start/end
            rangeStartTextStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
            rangeStartDecoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            rangeEndTextStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
            rangeEndDecoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            // Default days
            defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
            defaultTextStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
            // Weekend
            weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
            weekendTextStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            // Outside month days
            outsideTextStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              color: Colors.black26,
            ),
            disabledTextStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              color: Colors.black26,
            ),
            cellMargin: EdgeInsets.zero,
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            weekendStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            dowTextFormatter: (date, locale) {
              return DateFormat.E(locale).format(date).substring(0, 1);
            },
          ),
          daysOfWeekHeight: 60,
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
