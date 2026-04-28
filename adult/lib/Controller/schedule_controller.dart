import 'package:flutter/material.dart';
import '../model/schedule_model.dart';
import '../service/schedule_service.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleService _service = ScheduleService();

  List<ScheduleEntry> _entries = [];
  bool isLoading = false;
  String? errorMessage;

  List<ScheduleEntry> get entries => _entries;

  List<ScheduleEntry> entriesForDay(DateTime day) {
    return _entries
        .where(
          (e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day,
        )
        .toList();
  }

  Future<void> loadEntries(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _entries = await _service.fetchSchedules(email);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEntry(ScheduleEntry entry) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final saved = await _service.createSchedule(entry);
      _entries.add(saved);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _service.deleteSchedule(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
