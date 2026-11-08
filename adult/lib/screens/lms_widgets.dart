import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:adult/screens/color.dart';
import 'package:adult/service/connectivity_service.dart';
import 'package:adult/service/offline_cache.dart';

/// Shared building blocks for the learning screens. They favour large tap
/// targets, plain words and icons with labels, for learners who are new to
/// smartphones.

String formatDate(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy').format(d.toLocal());
String formatDateTime(DateTime? d) =>
    d == null ? '—' : DateFormat('d MMM yyyy, HH:mm').format(d.toLocal());

/// "in 3 days", "2 hours ago" and similar, for deadlines and activity.
String relativeTime(DateTime d) {
  final diff = d.difference(DateTime.now());
  final past = diff.isNegative;
  final a = diff.abs();
  String amount;
  if (a.inDays >= 1) {
    amount = '${a.inDays} day${a.inDays == 1 ? '' : 's'}';
  } else if (a.inHours >= 1) {
    amount = '${a.inHours} hour${a.inHours == 1 ? '' : 's'}';
  } else {
    amount = '${a.inMinutes.clamp(1, 59)} min';
  }
  return past ? '$amount ago' : 'in $amount';
}

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontSize: 15)),
      backgroundColor: error ? EduColors.danger : EduColors.success,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Shows what went wrong, or, when there was no connection, that the change
/// was kept on the device and will be sent after reconnecting.
void showError(BuildContext context, Object error) {
  if (error is QueuedOffline) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error.toString(), style: const TextStyle(fontSize: 15)),
        backgroundColor: EduColors.ink,
        behavior: SnackBarBehavior.floating,
      ));
    return;
  }
  showMessage(context, error.toString(), error: true);
}

/// Standard page frame: app bar with a title and a scrolling body.
class LmsPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  const LmsPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: EduColors.surface,
        foregroundColor: EduColors.textPrimary,
        elevation: 0,
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: body),
    );
  }
}

/// Loads data and shows a spinner, a friendly error with "Try again", or
/// the content. Pull down to refresh.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  const AsyncView({super.key, required this.load, required this.builder});

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;
  ConnectivityService? _connectivity;
  ConnectionStatus? _lastStatus;
  bool _wasChecking = false;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.read<ConnectivityService>();
    if (c == _connectivity) return;
    _connectivity?.removeListener(_onConnectionChanged);
    _connectivity = c..addListener(_onConnectionChanged);
    _lastStatus = c.status;
  }

  // Once a sync finishes (after reconnecting, or a quiet check that found
  // something new), show the fresh server data.
  void _onConnectionChanged() {
    final c = _connectivity!;
    final status = c.status;
    final synced = _lastStatus == ConnectionStatus.syncing && status == ConnectionStatus.online;
    final checkFoundNew = _wasChecking && !c.checkingForUpdates && (c.lastCheckNewItems ?? 0) > 0;
    if ((synced || checkFoundNew) && mounted) reload();
    _lastStatus = status;
    _wasChecking = c.checkingForUpdates;
  }

  @override
  void dispose() {
    _connectivity?.removeListener(_onConnectionChanged);
    super.dispose();
  }

  Future<void> reload() async {
    final next = widget.load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Could not load',
            message: snap.error.toString(),
            actionLabel: 'Try again',
            onAction: reload,
          );
        }
        return RefreshIndicator(
          onRefresh: reload,
          child: widget.builder(context, snap.data as T, reload),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // Scrollable so pull-to-refresh still works on an empty list
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        Icon(icon, size: 64, color: EduColors.textSecondary),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: EduColors.textPrimary)),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(message!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: EduColors.textSecondary)),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          Center(child: BigButton(label: actionLabel!, icon: Icons.refresh_rounded, onPressed: onAction)),
        ],
      ],
    );
  }
}

class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final Color? color;

  const BigButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color ?? EduColors.primary,
        minimumSize: const Size(160, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon ?? Icons.check_rounded),
      label: Text(label),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(text,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: EduColors.textPrimary)),
      );
}

class LmsCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const LmsCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: EduColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: EduColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A labelled percentage bar, e.g. course progress.
class ProgressLine extends StatelessWidget {
  final int percent;
  final String? label;
  final Color? color;

  const ProgressLine({super.key, required this.percent, this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(label ?? 'Progress',
                style: TextStyle(fontSize: 13, color: EduColors.textSecondary)),
          ),
          Text('$percent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 100) / 100,
            minHeight: 10,
            backgroundColor: EduColors.primarySoft,
            color: color ?? (percent >= 100 ? EduColors.success : EduColors.primary),
          ),
        ),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? EduColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduColors.border),
      ),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: c.withValues(alpha: 0.12), child: Icon(icon, color: c)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: EduColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}

/// Two-column grid of [StatTile]s that wraps on narrow phones.
class StatGrid extends StatelessWidget {
  final List<Widget> tiles;
  const StatGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth >= 360 ? (c.maxWidth - 12) / 2 : c.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    });
  }
}

/// Large icon button used on the hub screens.
class HubTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? caption;
  final int badge;
  final Color color;
  final VoidCallback onTap;

  const HubTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.badge = 0,
    this.color = EduColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return LmsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
            if (caption != null)
              Text(caption!, style: TextStyle(fontSize: 13.5, color: EduColors.textSecondary)),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: EduColors.textSecondary),
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
}
