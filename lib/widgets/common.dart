import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/status_colors.dart';

/// A simple military-style crest mark built from shapes (no image asset needed).
class VaultCrest extends StatelessWidget {
  final double size;
  const VaultCrest({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.crimson, AppColors.crimsonDeep],
        ),
        border: Border.all(color: AppColors.brass, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(Icons.shield_moon_outlined,
          color: Colors.white, size: size * 0.5),
    );
  }
}

/// Coloured status pill for DeviceStatus / AlertStatus / ComplianceState.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.alert(String status) =>
      StatusBadge(label: status, color: StatusColors.alertStatus(status));
  factory StatusBadge.device(String status) =>
      StatusBadge(label: status, color: StatusColors.deviceStatus(status));
  factory StatusBadge.compliance(String state) => StatusBadge(
        label: state,
        color: state.toLowerCase() == 'compliant'
            ? AppColors.success
            : state.toLowerCase() == 'noncompliant'
                ? AppColors.danger
                : AppColors.neutral,
      );

  @override
  Widget build(BuildContext context) => _pill(label, color);
}

/// Coloured pill for EventSeverity / AlertSeverity.
class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});
  @override
  Widget build(BuildContext context) =>
      _pill(severity, StatusColors.severity(severity));
}

Widget _pill(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.6)),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}

/// Kept for backwards compatibility with earlier screens.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => _pill(label, color);
}

class PlatformIcon extends StatelessWidget {
  final String platform;
  final double size;
  const PlatformIcon(this.platform, {super.key, this.size = 24});

  IconData get _icon {
    switch (platform.toLowerCase()) {
      case 'windows':
        return Icons.laptop_windows;
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.terminal;
      default:
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) => Icon(_icon, size: size);
}

/// "X minutes ago" / "X hours ago" / "X days ago" / "Never".
class TimeAgoText extends StatelessWidget {
  final DateTime? time;
  final TextStyle? style;
  final String neverLabel;
  const TimeAgoText(this.time, {super.key, this.style, this.neverLabel = 'Never'});

  static String format(DateTime? t, {String never = 'Never'}) {
    if (t == null) return never;
    final d = DateTime.now().difference(t.toLocal());
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} hr ago';
    if (d.inDays < 30) return '${d.inDays} day${d.inDays == 1 ? "" : "s"} ago';
    final months = (d.inDays / 30).floor();
    if (months < 12) return '$months mo ago';
    return '${(d.inDays / 365).floor()} yr ago';
  }

  @override
  Widget build(BuildContext context) =>
      Text(format(time, never: neverLabel), style: style);
}

class SectionHeader extends StatelessWidget {
  final String label;
  const SectionHeader(this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const InfoRow(
      {super.key, required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(value,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              if (copyable)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')));
                  },
                ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

/// PII masked as bullets until revealed with the eye toggle.
class RevealableText extends StatefulWidget {
  final String label;
  final String value;
  const RevealableText({super.key, required this.label, required this.value});
  @override
  State<RevealableText> createState() => _RevealableTextState();
}

class _RevealableTextState extends State<RevealableText> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  _revealed ? widget.value : '••••••••••',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                    _revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18),
                onPressed: () => setState(() => _revealed = !_revealed),
              ),
              if (_revealed)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.value));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')));
                  },
                ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor ?? scheme.outline),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: scheme.onSurface.withValues(alpha: 0.6))),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

// Older names kept so earlier screens still compile.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const MessageView(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.action});
  @override
  Widget build(BuildContext context) => EmptyState(
      icon: icon, title: title, subtitle: subtitle, action: action);
}

class LoadingOverlay extends StatelessWidget {
  final bool visible;
  final Widget child;
  const LoadingOverlay({super.key, required this.visible, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

/// Standard yes/no confirmation. Returns true if confirmed.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel)),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Destructive double-confirm: user must type [requiredWord] exactly.
Future<bool> showDoubleConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String requiredWord = 'CONFIRM',
}) async {
  final first = await showConfirmationDialog(context,
      title: title, body: body, confirmLabel: 'Continue', danger: true);
  if (!first || !context.mounted) return false;

  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final matches = controller.text.trim() == requiredWord;
        return AlertDialog(
          title: const Text('Type to confirm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type "$requiredWord" to proceed. This cannot be undone.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: requiredWord),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor:
                      matches ? AppColors.danger : AppColors.neutral),
              onPressed: matches ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    ),
  );
  return ok == true;
}
