import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import '../drivers/supabase_storefront.dart';

/// Live status (plus any proposed pickup time) of a placed preorder.
final _stateProvider = StreamProvider.autoDispose.family<OrderState, String>((
  ref,
  orderId,
) {
  final storefront = ref.watch(storefrontProvider);
  if (storefront == null) return const Stream.empty();
  return storefront.watchState(orderId);
});

class StatusScreen extends ConsumerWidget {
  final String orderId;
  final domain.Money total;

  const StatusScreen({super.key, required this.orderId, required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_stateProvider(orderId)).value;
    final status = state?.status;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.statusTitle),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon(status), size: 72, color: _color(context, status)),
              const SizedBox(height: 16),
              Text(
                _headline(context, status),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_detail(context, state), textAlign: TextAlign.center),
              if (status == domain.OnlineOrderStatus.timeProposed) ...[
                const SizedBox(height: 24),
                _ProposedTimeActions(orderId: orderId),
              ],
              const SizedBox(height: 24),
              Text(
                context.l10n.statusTotalPayAtPickup(total.format()),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(context.l10n.statusBackToMenu),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(domain.OnlineOrderStatus? s) => switch (s) {
    domain.OnlineOrderStatus.timeProposed => Icons.schedule,
    domain.OnlineOrderStatus.accepted => Icons.restaurant,
    domain.OnlineOrderStatus.ready => Icons.check_circle,
    domain.OnlineOrderStatus.pickedUp => Icons.done_all,
    domain.OnlineOrderStatus.rejected => Icons.cancel_outlined,
    _ => Icons.hourglass_top,
  };

  Color? _color(BuildContext context, domain.OnlineOrderStatus? s) =>
      switch (s) {
        domain.OnlineOrderStatus.ready => context.posStatus.success,
        domain.OnlineOrderStatus.timeProposed => context.posStatus.warning,
        domain.OnlineOrderStatus.rejected => Theme.of(
          context,
        ).colorScheme.error,
        _ => Theme.of(context).colorScheme.primary,
      };

  String _headline(
    BuildContext context,
    domain.OnlineOrderStatus? s,
  ) => switch (s) {
    null => context.l10n.statusSendingHeadline,
    domain.OnlineOrderStatus.submitted => context.l10n.statusSubmittedHeadline,
    domain.OnlineOrderStatus.timeProposed =>
      context.l10n.statusTimeProposedHeadline,
    domain.OnlineOrderStatus.accepted => context.l10n.statusAcceptedHeadline,
    domain.OnlineOrderStatus.ready => context.l10n.statusReadyHeadline,
    domain.OnlineOrderStatus.pickedUp => context.l10n.statusPickedUpHeadline,
    domain.OnlineOrderStatus.rejected => context.l10n.statusRejectedHeadline,
  };

  String _detail(BuildContext context, OrderState? state) {
    final s = state?.status;
    if (s == domain.OnlineOrderStatus.timeProposed) {
      final at = state?.proposedPickupAt;
      final time = at == null ? '' : TimeOfDay.fromDateTime(at).format(context);
      return context.l10n.statusTimeProposedDetail(time);
    }
    return switch (s) {
      domain.OnlineOrderStatus.submitted => context.l10n.statusSubmittedDetail,
      domain.OnlineOrderStatus.accepted => context.l10n.statusAcceptedDetail,
      domain.OnlineOrderStatus.ready => context.l10n.statusReadyDetail,
      domain.OnlineOrderStatus.rejected => context.l10n.statusRejectedDetail,
      _ => '',
    };
  }
}

/// Approve / decline buttons shown when the merchant proposed a new time.
class _ProposedTimeActions extends ConsumerStatefulWidget {
  final String orderId;

  const _ProposedTimeActions({required this.orderId});

  @override
  ConsumerState<_ProposedTimeActions> createState() =>
      _ProposedTimeActionsState();
}

class _ProposedTimeActionsState extends ConsumerState<_ProposedTimeActions> {
  bool _busy = false;

  Future<void> _respond({required bool approve}) async {
    final storefront = ref.read(storefrontProvider);
    if (storefront == null) return;
    setState(() => _busy = true);
    try {
      if (approve) {
        await storefront.approveProposedTime(widget.orderId);
      } else {
        await storefront.declineProposedTime(widget.orderId);
      }
      ref.invalidate(_stateProvider(widget.orderId));
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.menuLoadError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: () => _respond(approve: false),
          child: Text(context.l10n.statusDeclineTime),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => _respond(approve: true),
          child: Text(context.l10n.statusApproveTime),
        ),
      ],
    );
  }
}
