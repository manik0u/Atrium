import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adguard_home_providers.dart';
import '../models/adguard_home_status.dart';
import '../screens/adguard_home_access_screen.dart';
import '../screens/adguard_home_dns_cache_screen.dart';
import '../screens/adguard_home_dns_server_screen.dart';
import '../screens/adguard_home_dns_upstreams_screen.dart';
import '../screens/adguard_home_general_settings_screen.dart';
import '../screens/adguard_home_retention_screen.dart';
import '../screens/adguard_home_server_info_screens.dart';
import '../widgets/adguard_home_fields.dart';

/// The server's settings, a section to a screen, as on its web UI.
///
/// The tab reads nothing of its own: the two lines that say something
/// come from reads already made for the other tabs, and each screen reads
/// its part when it opens.
class AdguardHomeSettingsTab extends ConsumerWidget {
  const AdguardHomeSettingsTab({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool? filtering =
        ref.watch(adguardHomeFilteringProvider(instance)).value?.enabled;
    final AdguardHomeStatus? status =
        ref.watch(adguardHomeStatusProvider(instance)).value;
    void open(Widget screen) => pushScreen<void>(context, screen);
    return ListView(
      padding: const EdgeInsets.only(bottom: Insets.xl),
      children: <Widget>[
        _Heading(S.t('protection')),
        _Section(
          icon: Icons.tune,
          title: S.t('general'),
          summary: switch (filtering) {
            true => S.t('filteringOnSafeBrowsingParentalControlSafeSearch'),
            false => S.t('filteringOff'),
            null => S.t('filteringSafeBrowsingParentalControlSafeSearch'),
          },
          onTap: () =>
              open(AdguardHomeGeneralSettingsScreen(instance: instance)),
        ),
        _Heading(S.t('logs')),
        _Section(
          icon: Icons.receipt_long_outlined,
          title: S.t('queryLog'),
          summary: S.t('howLongQueriesAreKeptAndWhichAreLeftOut'),
          onTap: () => open(
            AdguardHomeRetentionScreen(
              instance: instance,
              kind: AdguardHomeRetentionKind.queryLog,
            ),
          ),
        ),
        _Section(
          icon: Icons.insights_outlined,
          title: S.t('statistics'),
          summary: S.t('howLongTheyAreKeptAndResetStatistics'),
          onTap: () => open(
            AdguardHomeRetentionScreen(
              instance: instance,
              kind: AdguardHomeRetentionKind.statistics,
            ),
          ),
        ),
        const _Heading('DNS'),
        _Section(
          icon: Icons.dns_outlined,
          title: S.t('upstreams'),
          summary: S.t('upstreamFallbackAndBootstrapServersTestUpstreams'),
          onTap: () => open(AdguardHomeDnsUpstreamsScreen(instance: instance)),
        ),
        _Section(
          icon: Icons.settings_ethernet,
          title: S.t('dnsServer'),
          summary: 'Rate limit, EDNS, DNSSEC, IPv6, blocking mode',
          onTap: () => open(AdguardHomeDnsServerScreen(instance: instance)),
        ),
        _Section(
          icon: Icons.cached,
          title: S.t('dnsCache'),
          summary: 'Size, TTL overrides, optimistic caching, Clear cache',
          onTap: () => open(AdguardHomeDnsCacheScreen(instance: instance)),
        ),
        _Section(
          icon: Icons.admin_panel_settings_outlined,
          title: S.t('access'),
          summary: S.t('allowedAndDisallowedClientsDisallowedDomains'),
          onTap: () => open(AdguardHomeAccessScreen(instance: instance)),
        ),
        _Heading(S.t('server')),
        _Section(
          icon: Icons.lock_outline,
          title: S.t('encryption'),
          summary: 'Whether DNS over HTTPS, TLS and QUIC are set up',
          onTap: () => open(AdguardHomeEncryptionScreen(instance: instance)),
        ),
        _Section(
          icon: Icons.router_outlined,
          title: 'DHCP',
          summary: S.t('whetherItHandsOutAddressesAndToWhom'),
          onTap: () => open(AdguardHomeDhcpScreen(instance: instance)),
        ),
        _Section(
          icon: Icons.info_outline,
          title: S.t('about'),
          summary: status == null || status.version.isEmpty
              ? 'Version, DNS addresses, updates'
              : 'Version ${status.version}',
          onTap: () => open(AdguardHomeAboutScreen(instance: instance)),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        child: AdguardHomeHeading(text),
      );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(summary),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
