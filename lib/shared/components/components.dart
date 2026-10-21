import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Surface decoration: limestone/paper fill, a hairline border and a soft
/// shadow. ([shadow] is a strength from 0 to ~4.)
BoxDecoration stickerDecoration({
  Color color = AppColors.paper,
  double radius = 14,
  double shadow = 2,
  Color border = AppColors.mineral,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border, width: 1),
    boxShadow: shadow <= 0
        ? null
        : [
            BoxShadow(
              color: AppColors.midnight.withValues(alpha: 0.05 + 0.02 * shadow),
              blurRadius: 6 + 4 * shadow,
              offset: Offset(0, 1 + shadow),
            ),
          ],
  );
}

/// Decoration for controls floating over imagery: midnight glass-free panel
/// with a light hairline, readable over bright sand and dark sea alike.
BoxDecoration mapControlDecoration({double radius = 22}) => BoxDecoration(
      color: AppColors.midnight.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 2)),
      ],
    );

/// A quiet surface. Used sparingly — the map and typography do most of the work.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.color = AppColors.paper,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: stickerDecoration(color: color, shadow: 0),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (semanticLabel == null) return content;
    return Semantics(button: onTap != null, label: semanticLabel, child: content);
  }
}

enum BladnaButtonStyle { primary, secondary, quiet }

/// Main call-to-action. Primary = survey orange, secondary = midnight,
/// quiet = outlined. Minimum 50 px tall.
class BladnaButton extends StatelessWidget {
  const BladnaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = BladnaButtonStyle.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BladnaButtonStyle style;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color fg, Color border) = switch (style) {
      BladnaButtonStyle.primary => (AppColors.action, Colors.white, AppColors.action),
      BladnaButtonStyle.secondary => (AppColors.midnight, AppColors.onDark, AppColors.midnight),
      BladnaButtonStyle.quiet => (Colors.transparent, AppColors.ink, AppColors.ink.withValues(alpha: 0.35)),
    };
    final enabled = onPressed != null;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: enabled ? fg : AppColors.disabled),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.bodyStrong.copyWith(color: enabled ? fg : AppColors.disabled, fontSize: 15),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: enabled ? fill : (style == BladnaButtonStyle.quiet ? Colors.transparent : AppColors.mineral),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: enabled ? border : AppColors.mineral, width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill label. Always text (plus optional icon), never color alone.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.text, this.color = AppColors.mineral, this.icon, this.textColor});

  final String text;
  final Color color;
  final IconData? icon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text.rich(
        TextSpan(children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(padding: const EdgeInsets.only(right: 4), child: Icon(icon, size: 13, color: fg)),
            ),
          TextSpan(text: text),
        ]),
        style: AppText.label.copyWith(color: fg, letterSpacing: 0.4, fontSize: 11),
      ),
    );
  }
}

/// Slim progress bar.
class ChunkyProgress extends StatelessWidget {
  const ChunkyProgress({
    super.key,
    required this.value,
    this.color = AppColors.action,
    this.height = 6,
    this.ticks = 0,
    this.semanticLabel,
    this.trackColor = AppColors.mineral,
  });

  final double value;
  final Color color;
  final double height;
  final int ticks;
  final String? semanticLabel;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final double v = value.isNaN ? 0.0 : (value < 0 ? 0.0 : (value > 1 ? 1.0 : value));
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()} percent',
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(height)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: v, heightFactor: 1, child: Container(color: color)),
          ),
        ),
      ),
    );
  }
}

/// Overline section header.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Semantics(header: true, child: Text(text.toUpperCase(), style: AppText.label))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Circular control. [onMap] = midnight style for use over imagery.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onMap = false,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool onMap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Container(
              width: 46,
              height: 46,
              decoration: onMap
                  ? mapControlDecoration(radius: 23)
                  : BoxDecoration(
                      color: color ?? AppColors.paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mineral),
                    ),
              child: Icon(icon, color: onMap ? AppColors.onDark : AppColors.ink, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain back bar for full-screen activities: always one tap back to the map.
class ActivityHeader extends StatelessWidget {
  const ActivityHeader({super.key, required this.title, this.subtitle, this.trailing, this.backTooltip = 'Back to the map'});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: backTooltip, onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) Text(subtitle!, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.travel_explore_rounded});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.inkFaint),
          const SizedBox(height: 10),
          Text(title, style: AppText.subheading, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(message, style: AppText.small, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// ★★☆
class StarRow extends StatelessWidget {
  const StarRow(this.count, {super.key, this.size = 16, this.color = AppColors.warning});

  final int count;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count of 3 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(i < count ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: color),
        ],
      ),
    );
  }
}
