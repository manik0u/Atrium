import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tracearr_models.dart';

/// Modal bottom sheet providing deep telemetry and diagnostics for a historical stream session.
class HistorySessionDiagnosticsSheet extends StatelessWidget {
  const HistorySessionDiagnosticsSheet({
    required this.item,
    super.key,
  });

  final TracearrHistoryItem item;

  static void show(
    BuildContext context, {
    required TracearrHistoryItem item,
  }) {
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      builder: (context) => HistorySessionDiagnosticsSheet(item: item),
    );
  }

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '0 min';
    final int minutes = (ms / (1000 * 60)).round();
    if (minutes < 60) return '$minutes min';
    final int hours = minutes ~/ 60;
    final int remMinutes = minutes % 60;
    return remMinutes > 0 ? '${hours}h ${remMinutes}m' : '${hours}h';
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, y • HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isTranscode = item.isTranscode ?? false;
    final String vDec = item.videoDecision?.toLowerCase() ?? '';
    final String videoDecision = vDec == 'copy'
        ? 'DIRECT STREAM (COPY)'
        : item.videoDecision?.toUpperCase() ??
            (isTranscode && item.audioDecision?.toLowerCase() == 'transcode'
                ? 'DIRECT STREAM'
                : isTranscode
                    ? 'TRANSCODE'
                    : 'DIRECT PLAY');
    final String audioDecision = item.audioDecision?.toUpperCase() ??
        (isTranscode ? 'TRANSCODE' : 'DIRECT PLAY');

    final bool isHw = item.isHwTranscode ||
        (item.hwDecoding != null && item.hwDecoding!.isNotEmpty) ||
        (item.hwEncoding != null && item.hwEncoding!.isNotEmpty);

    final String? containerRemux = (item.sourceContainer != null &&
            item.streamContainer != null)
        ? '${item.sourceContainer!.toUpperCase()} → ${item.streamContainer!.toUpperCase()}'
        : item.sourceContainer?.toUpperCase() ??
            item.streamContainer?.toUpperCase();

    final String? dimensions = (item.sourceResolution != null &&
            item.streamResolution != null &&
            item.sourceResolution != item.streamResolution)
        ? '${item.sourceResolution} → ${item.streamResolution}'
        : item.sourceResolution ?? item.streamResolution;

    final String? sourceDr = item.sourceDynamicRange;
    final String? streamDr = item.streamDynamicRange;
    final bool hasSourceDr = sourceDr != null && sourceDr.trim().isNotEmpty;
    final bool hasStreamDr = streamDr != null && streamDr.trim().isNotEmpty;
    final bool hasDifferentDr = hasSourceDr &&
        hasStreamDr &&
        sourceDr.trim().toUpperCase() != streamDr.trim().toUpperCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: Insets.sm),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(Insets.lg),
                children: [
                  // Title & User Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.mediaTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (item.showTitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${item.showTitle} • S${item.seasonNumber ?? 0}:E${item.episodeNumber ?? 0}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ] else if (item.year != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${item.year}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '@${item.userUsername} on ${item.serverName} (${item.serverType.toUpperCase()})',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),
                  const Divider(height: 1),
                  const SizedBox(height: Insets.md),

                  // 1. Session & Chain History
                  _SectionHeader(
                    title: S.t('sessionCHAINHISTORY'),
                    icon: Icons.history_outlined,
                  ),
                  const SizedBox(height: Insets.sm),
                  _TelemetryRow(
                    label: S.t('status'),
                    value: item.watched
                        ? S.t('completed')
                        : item.percentComplete != null
                            ? '${item.percentComplete!.round()}% Watched'
                            : 'Recorded',
                    badgeColor: item.watched
                        ? const Color(0xFF4CAF50)
                        : colorScheme.primary,
                  ),
                  if (item.durationMs != null && item.durationMs! > 0)
                    _TelemetryRow(
                      label: S.t('watchTime'),
                      value: _formatDuration(item.durationMs),
                    ),
                  if (item.segmentCount != null && item.segmentCount! > 1)
                    _TelemetryRow(
                      label: S.t('resumeChain'),
                      value: '${item.segmentCount} sessions merged',
                      badgeColor: const Color(0xFF9C27B0),
                    ),
                  if (item.startedAt != null)
                    _TelemetryRow(
                      label: S.t('startedAt'),
                      value: _formatDateTime(item.startedAt!),
                    ),
                  if (item.stoppedAt != null)
                    _TelemetryRow(
                      label: S.t('stoppedAt'),
                      value: _formatDateTime(item.stoppedAt!),
                    ),

                  const SizedBox(height: Insets.lg),
                  const Divider(height: 1),
                  const SizedBox(height: Insets.md),

                  // 2. Video Stream & Pipeline Diagnostics
                  _SectionHeader(
                    title: S.t('videoPIPELINETELEMETRY'),
                    icon: Icons.videocam_outlined,
                  ),
                  const SizedBox(height: Insets.sm),
                  _TelemetryRow(
                    label: S.t('decision'),
                    value: videoDecision,
                    highlight: isTranscode,
                  ),
                  if (item.videoCodec != null)
                    _TelemetryRow(
                      label: S.t('videoCodec'),
                      value: item.videoCodec!.toUpperCase(),
                    ),
                  if (item.resolution != null)
                    _TelemetryRow(
                      label: S.t('resolution'),
                      value: item.resolution!,
                    ),
                  if (dimensions != null)
                    _TelemetryRow(
                      label: S.t('dimensions'),
                      value: dimensions,
                    ),
                  if (hasDifferentDr) ...[
                    _TelemetryRow(
                      label: S.t('sourceDynamicRange'),
                      value: sourceDr.toUpperCase(),
                      badgeColor: sourceDr.toUpperCase().contains('HDR') ||
                              sourceDr.toUpperCase().contains('VISION')
                          ? const Color(0xFFFF9800)
                          : null,
                    ),
                    _TelemetryRow(
                      label: S.t('streamDynamicRange'),
                      value: '${streamDr.toUpperCase()} (Tone-Mapped)',
                      badgeColor: const Color(0xFF2196F3),
                    ),
                  ] else if (hasSourceDr || hasStreamDr) ...[
                    _TelemetryRow(
                      label: S.t('dynamicRange'),
                      value: (sourceDr ?? streamDr)!.toUpperCase(),
                      badgeColor: (sourceDr ?? streamDr)!
                                  .toUpperCase()
                                  .contains('HDR') ||
                              (sourceDr ?? streamDr)!
                                  .toUpperCase()
                                  .contains('VISION')
                          ? const Color(0xFFFF9800)
                          : null,
                    ),
                  ],
                  if (containerRemux != null)
                    _TelemetryRow(
                      label: S.t('container'),
                      value: containerRemux,
                    ),
                  if (isHw)
                    _TelemetryRow(
                      label: S.t('hardwareAcceleration'),
                      value:
                          'Active (${item.hwDecoding ?? item.hwEncoding ?? "Hardware"})',
                      badgeColor: const Color(0xFF2196F3),
                    ),
                  if (item.transcodeSpeed != null)
                    _TelemetryRow(
                      label: S.t('transcodeSpeed'),
                      value: '${item.transcodeSpeed!.toStringAsFixed(1)}x',
                    ),
                  if (item.isThrottled != null)
                    _TelemetryRow(
                      label: S.t('throttled'),
                      value: item.isThrottled! ? S.t('yesCPUSaved') : S.t('no'),
                    ),
                  if (item.transcodeReasons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transcode Reasons:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ...item.transcodeReasons.map(
                            (r) => Text(
                              S.t('r1', [r]),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: Insets.lg),
                  const Divider(height: 1),
                  const SizedBox(height: Insets.md),

                  // 3. Audio & Subtitles
                  _SectionHeader(
                    title: S.t('audioSUBTITLES'),
                    icon: Icons.audiotrack_outlined,
                  ),
                  const SizedBox(height: Insets.sm),
                  _TelemetryRow(label: S.t('audioDecision'), value: audioDecision),
                  if (item.audioCodec != null)
                    _TelemetryRow(
                      label: S.t('audioCodec'),
                      value: item.audioCodec!.toUpperCase(),
                    ),
                  if (item.audioChannels != null)
                    _TelemetryRow(
                      label: S.t('audioChannels'),
                      value: item.audioChannels!,
                    ),
                  if (item.subtitleLanguage != null ||
                      item.subtitleCodec != null ||
                      item.subtitleDecision != null) ...[
                    _TelemetryRow(
                      label: S.t('subtitles'),
                      value:
                          '${item.subtitleLanguage ?? "Unknown"} (${item.subtitleCodec?.toUpperCase() ?? "Standard"})',
                    ),
                    if (item.subtitleDecision != null)
                      _TelemetryRow(
                        label: S.t('subtitleMode'),
                        value: item.subtitleDecision!.toUpperCase(),
                        badgeColor:
                            item.subtitleDecision!.toLowerCase() == 'burn'
                                ? colorScheme.error
                                : null,
                      ),
                  ],

                  const SizedBox(height: Insets.lg),
                  const Divider(height: 1),
                  const SizedBox(height: Insets.md),

                  // 4. Client & Network Environment
                  _SectionHeader(
                    title: S.t('clientPLAYBACKENVIRONMENT'),
                    icon: Icons.devices_outlined,
                  ),
                  const SizedBox(height: Insets.sm),
                  if (item.player != null)
                    _TelemetryRow(label: S.t('player'), value: item.player!),
                  if (item.device != null)
                    _TelemetryRow(label: S.t('device'), value: item.device!),
                  if (item.product != null)
                    _TelemetryRow(label: S.t('product'), value: item.product!),
                  if (item.platform != null)
                    _TelemetryRow(label: S.t('platform'), value: item.platform!),
                  if (item.bitrate != null && item.bitrate! > 0)
                    _TelemetryRow(
                      label: S.t('averageBitrate'),
                      value: item.bitrate! >= 1000
                          ? '${(item.bitrate! / 1000).toStringAsFixed(1)} Mbps'
                          : '${item.bitrate} kbps',
                    ),

                  const SizedBox(height: Insets.xl),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: Insets.xs),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  const _TelemetryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.badgeColor,
  });

  final String label;
  final String value;
  final bool highlight;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Insets.md),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: badgeColor ??
                    (highlight
                        ? const Color(0xFFFF9800)
                        : colorScheme.onSurface),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
