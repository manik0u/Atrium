import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The outcome of testing one URL of an instance before it is saved.
enum ConnectionOutcome { connected, authFailed, unreachable }

/// One URL test result: an [outcome] and a short human message.
class ConnectionTestResult {
  const ConnectionTestResult(this.outcome, this.message);

  final ConnectionOutcome outcome;
  final String message;
}

/// Maps a [Health] verdict from a lightweight probe to a [ConnectionTestResult].
ConnectionTestResult connectionResultFromHealth(Health health) {
  switch (health) {
    case Health.ok:
      return const ConnectionTestResult(
        ConnectionOutcome.connected,
        'Connected',
      );
    case Health.warning:
      return ConnectionTestResult(
        ConnectionOutcome.authFailed,
        S.t('reachableButTheCheckDidNotPass'),
      );
    case Health.error:
      return ConnectionTestResult(
        ConnectionOutcome.unreachable,
        S.t('couldNotReachTheServer_2'),
      );
    case Health.unknown:
      return ConnectionTestResult(
        ConnectionOutcome.unreachable,
        S.t('couldNotDetermineTheConnection'),
      );
  }
}

/// Maps an error thrown while verifying a session service (qBittorrent,
/// Jellyfin, Emby, Plex) to a [ConnectionTestResult]. A rejected credential
/// surfaces as [NetworkAuthException]; anything else is treated as a transport
/// or server problem.
ConnectionTestResult connectionResultFromError(Object error) {
  Object unwrapped = error;
  if (unwrapped is AsyncError) {
    unwrapped = unwrapped.error;
  }
  if (unwrapped is NetworkAuthException) {
    return ConnectionTestResult(
      ConnectionOutcome.authFailed,
      S.t('reachableButTheCredentialsWereRejected'),
    );
  }
  final String errStr = unwrapped.toString().toLowerCase();
  if (errStr.contains('429') || errStr.contains('rate limit')) {
    return const ConnectionTestResult(
      ConnectionOutcome.authFailed,
      'Reachable, but rate limit exceeded on server',
    );
  }
  if (errStr.contains('401') || errStr.contains('403') || errStr.contains('unauthorized')) {
    return ConnectionTestResult(
      ConnectionOutcome.authFailed,
      S.t('reachableButTheCredentialsWereRejected'),
    );
  }
  return ConnectionTestResult(
    ConnectionOutcome.unreachable,
    S.t('couldNotReachTheServer_2'),
  );
}
