import 'models/seerr_request.dart';

/// The chips over the Requests tab. Each one keeps the requests of one
/// request status (1 pending, 2 approved, 3 declined, 4 failed,
/// 5 completed), as Seerr's own filters do: a request moves from approved
/// to completed once its media is available. [all] keeps every one.
enum SeerrRequestFilter {
  all('All', 'No requests', 'Aucune demande de média pour le moment.'),
  pending('Pending', 'Aucune demande en attente', "Rien n'attend une approbation."),
  approved('Approved', 'Aucune demande approuvée', "Aucune demande n'a été approuvée."),
  completed(
    'Completed',
    'Aucune demande terminée',
    'Les demandes apparaissent ici une fois leur média disponible.',
  ),
  declined('Declined', 'Aucune demande refusée', "Aucune demande n'a été refusée."),
  failed(
    'Failed',
    'Aucune demande échouée',
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
