import 'models/seerr_request.dart';
import 'package:core_models/core_models.dart';

/// The chips over the Requests tab. Each one keeps the requests of one
/// request status (1 pending, 2 approved, 3 declined, 4 failed,
/// 5 completed), as Seerr's own filters do: a request moves from approved
/// to completed once its media is available. [all] keeps every one.
enum SeerrRequestFilter {
  all(S.t('all'), 'No requests', S.t('noMediaRequestsYet')),
  pending(S.t('pending'), S.t('noPendingRequests'), S.t('nothingIsWaitingForApproval')),
  approved(S.t('approved'), S.t('noApprovedRequests'), S.t('noRequestHasBeenApproved')),
  completed(
    S.t('completed'),
    S.t('noCompletedRequests'),
    S.t('requestsShowHereOnceTheirMediaIsAvailable'),
  ),
  declined(S.t('declined'), S.t('noDeclinedRequests'), S.t('noRequestHasBeenDeclined')),
  failed(
    S.t('failed'),
    S.t('noFailedRequests'),
    'Every approved request reached Sonarr or Radarr.',
  );

  const SeerrRequestFilter(this.label, this.emptyTitle, this.emptyMessage);

  final String label;
  final String emptyTitle;
  final String emptyMessage;

  /// Whether [request] shows under this chip.
  bool keeps(SeerrRequest request) => switch (this) {
        SeerrRequestFilter.all => true,
        SeerrRequestFilter.pending => request.status == 1,
        SeerrRequestFilter.approved => request.status == 2,
        SeerrRequestFilter.declined => request.status == 3,
        SeerrRequestFilter.completed => request.status == 5,
        SeerrRequestFilter.failed => request.status == 4,
      };

  /// [requests] cut down to this chip, in the order they came.
  List<SeerrRequest> apply(List<SeerrRequest> requests) => this == all
      ? requests
      : <SeerrRequest>[
          for (final SeerrRequest r in requests)
            if (keeps(r)) r,
        ];
}
