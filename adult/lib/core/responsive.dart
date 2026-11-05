import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Layout breakpoints and building blocks shared by every screen.
///
/// Rule of thumb: on phone widths every helper here returns its child
/// untouched, so the mobile layout stays exactly as designed. The helpers
/// only change how tablets and desktops use the extra space.
enum ScreenSize { mobile, tablet, desktop }

class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  /// Max content width for dashboards and lists.
  static const double content = 1200;

  /// Max content width for forms, login and reading pages.
  static const double reading = 720;

  /// Max width of dialogs that replace bottom sheets on large screens.
  static const double dialog = 560;

  /// Max width of a card inside a [ResponsiveGrid].
  static const double gridItem = 340;

  static ScreenSize of(double width) {
    if (width >= desktop) return ScreenSize.desktop;
    if (width >= tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize => Breakpoints.of(MediaQuery.sizeOf(this).width);
  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Picks a value for the current screen size; tablet falls back to mobile
  /// and desktop falls back to tablet when not given.
  T responsive<T>(T mobile, {T? tablet, T? desktop}) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Centres [child] and caps its width on tablet and desktop.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.content,
  });

  /// For forms, login and reading pages.
  const ResponsiveCenter.reading({super.key, required this.child})
      : maxWidth = Breakpoints.reading;

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Gives a full-width ListView/GridView side padding that centres its
/// content at [maxWidth], so the mouse wheel scrolls anywhere on the page
/// (wrapping the list in [ResponsiveCenter] would leave dead margins).
class CenteredScrollPadding extends StatelessWidget {
  const CenteredScrollPadding({
    super.key,
    required this.padding,
    required this.builder,
    this.maxWidth = Breakpoints.content,
  });

  final EdgeInsets padding;
  final double maxWidth;
  final Widget Function(BuildContext context, EdgeInsets padding) builder;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) return builder(context, padding);
    return LayoutBuilder(
      builder: (context, box) {
        final extra = ((box.maxWidth - maxWidth) / 2).clamp(0.0, double.infinity);
        return builder(
          context,
          padding.copyWith(
            left: padding.left + extra,
            right: padding.right + extra,
          ),
        );
      },
    );
  }
}

/// Lays cards out in columns: 1 on mobile, 2 on tablet, 3-4 on desktop.
///
/// Items keep their natural height (rows align to the top), so a card can
/// never overflow because of a fixed cell height.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 14,
    this.runSpacing = 14,
    this.maxItemWidth = Breakpoints.gridItem,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double maxItemWidth;

  /// Desktop uses the fewest columns (3-4) that keep cards within
  /// [maxItemWidth], so rows fill the width instead of leaving a gap.
  int _columns(BuildContext context, double width) {
    switch (context.screenSize) {
      case ScreenSize.mobile:
        return 1;
      case ScreenSize.tablet:
        return 2;
      case ScreenSize.desktop:
        return ((width + spacing) / (maxItemWidth + spacing)).ceil().clamp(3, 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = _columns(context, box.maxWidth);
        final fit = (box.maxWidth - spacing * (columns - 1)) / columns;
        // Tablets always fill their two columns; desktop cards are capped.
        final itemWidth = context.isDesktop ? fit.clamp(0.0, maxItemWidth) : fit;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Places form fields side by side on desktop and stacks them otherwise.
class ResponsiveFormRow extends StatelessWidget {
  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.gap = 12,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// A bottom sheet on mobile; a centred dialog with a max width elsewhere.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  double maxWidth = Breakpoints.dialog,
}) {
  if (context.isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      shape: shape,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final height = MediaQuery.sizeOf(ctx).height;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: height * 0.85,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: backgroundColor == Colors.transparent
                  ? Colors.transparent
                  : (backgroundColor ?? Theme.of(ctx).colorScheme.surface),
              child: builder(ctx),
            ),
          ),
        ),
      );
    },
  );
}

/// Adds a hover lift and a pointer cursor on devices with a mouse.
///
/// Pass [onTap] to make the whole card clickable, or leave it null when the
/// card already handles taps itself and only needs the hover feedback.
class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.clickable = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool clickable;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return widget.onTap == null
          ? widget.child
          : GestureDetector(onTap: widget.onTap, child: widget.child);
    }
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _hovered ? 0.94 : 1,
        child: widget.child,
      ),
    );
    return MouseRegion(
      cursor: widget.clickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.onTap == null
          ? card
          : GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}

/// Mouse and trackpad can drag horizontal lists (chips, carousels), and
/// vertical scrollbars stay visible on mouse-driven platforms. Touch
/// platforms keep Flutter's default (no scrollbars), so phones are unchanged.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final touchPlatform = switch (getPlatform(context)) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };
    if (touchPlatform ||
        axisDirectionToAxis(details.direction) == Axis.horizontal) {
      return super.buildScrollbar(context, child, details);
    }
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }
}
