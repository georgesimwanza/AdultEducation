import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/coursepage.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/lms_api.dart';

/// "My courses" (course history with progress) and "Find courses"
/// (enroll in any open course).
class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: LmsPage(
        title: 'My Courses',
        bottom: const TabBar(
          labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          tabs: [Tab(text: 'My courses'), Tab(text: 'Find courses')],
        ),
        body: const TabBarView(children: [_Enrolled(), _Catalogue()]),
      ),
    );
  }
}

class _Enrolled extends StatelessWidget {
  const _Enrolled();

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Enrollment>>(
      load: () async => ((await LmsApi.get('/enrollments/me')) as List)
          .map((e) => Enrollment.fromJson(e))
          .where((e) => e.status != 'DROPPED')
          .toList(),
      builder: (context, list, reload) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_rounded,
            title: 'No courses yet',
            message: 'Open "Find courses" to join one.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final e in list)
              LmsCard(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CoursePage(subjectId: e.courseId)),
                  );
                  reload();
                },
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(e.courseName,
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                    ),
                    if (e.status == 'COMPLETED')
                      const StatusChip('Completed', color: EduColors.success)
                    else
                      const StatusChip('In progress', color: EduColors.primary),
                  ]),
                  const SizedBox(height: 4),
                  Text('${e.courseCode} · ${e.lessonsViewed} of ${e.totalLessons} lessons opened',
                      style: TextStyle(color: EduColors.textSecondary)),
                  const SizedBox(height: 10),
                  ProgressLine(percent: e.progressPercentage),
                  const SizedBox(height: 8),
                  Text(
                    e.status == 'COMPLETED'
                        ? 'Finished on ${formatDate(e.completedAt)}'
                        : 'Joined ${formatDate(e.enrolledAt)}'
                            '${e.lastAccessed != null ? ' · last studied ${relativeTime(e.lastAccessed!)}' : ''}',
                    style: TextStyle(fontSize: 13, color: EduColors.textSecondary),
                  ),
                ]),
              ),
          ],
        );
      },
    );
  }
}

class _Catalogue extends StatelessWidget {
  const _Catalogue();

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<CourseSummary>>(
      load: () async =>
          ((await LmsApi.get('/enrollments/catalogue')) as List).map((e) => CourseSummary.fromJson(e)).toList(),
      builder: (context, list, reload) {
        if (list.isEmpty) {
          return const EmptyState(icon: Icons.search_off_rounded, title: 'No courses are open right now');
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [for (final c in list) _CatalogueCard(course: c, onChanged: reload)],
        );
      },
    );
  }
}

class _CatalogueCard extends StatefulWidget {
  final CourseSummary course;
  final Future<void> Function() onChanged;
  const _CatalogueCard({required this.course, required this.onChanged});

  @override
  State<_CatalogueCard> createState() => _CatalogueCardState();
}

class _CatalogueCardState extends State<_CatalogueCard> {
  bool _busy = false;

  Future<void> _toggle() async {
    final c = widget.course;
    if (c.enrolled) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave this course?'),
          content: Text('You will stop getting updates for ${c.name}. Your progress is kept if you join again.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      if (c.enrolled) {
        await LmsApi.delete('/enrollments/${c.id}');
        if (mounted) showMessage(context, 'You left ${c.name}');
      } else {
        await LmsApi.post('/enrollments/${c.id}');
        if (mounted) showMessage(context, 'You joined ${c.name}');
      }
      await widget.onChanged();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return LmsCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          [c.courseCode, if (c.level != null) c.level!, '${c.lessonCount} lessons', '${c.credits} credits'].join(' · '),
          style: TextStyle(color: EduColors.textSecondary),
        ),
        if (c.description != null && c.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(c.description!, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: c.enrolled
              ? OutlinedButton.icon(
                  onPressed: _busy ? null : _toggle,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Leave course'),
                )
              : BigButton(label: 'Join course', icon: Icons.add_rounded, busy: _busy, onPressed: _toggle),
        ),
      ]),
    );
  }
}
