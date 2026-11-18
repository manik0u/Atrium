import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lidarr_api.dart';
import '../../lidarr_providers.dart';
import 'views/backups_view.dart';
import 'views/disk_space_view.dart';
import 'views/log_files_view.dart';
import 'views/logs_view.dart';
import 'views/status_view.dart';
import 'views/tasks_view.dart';
import 'views/updates_view.dart';

/// System tab coordinating the 7 Lidarr runtime and diagnostics views.
class SystemTab extends ConsumerStatefulWidget {
  const SystemTab({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends ConsumerState<SystemTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _confirmRestart() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(S.t('restartLidarr')),
        content: const Text(
          'This will restart the Lidarr service. It will be temporarily unavailable.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t('restart')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final LidarrApi api =
            await ref.read(lidarrApiProvider(widget.instance).future);
        await api.system.postSystemRestart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.t('restartSignalSent'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.t('failedToRestartE1', [e]))),
          );
        }
      }
    }
  }

  Future<void> _confirmShutdown() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(S.t('shutdownLidarr')),
        content: const Text(
          'This will shut down the Lidarr service. You will need to restart it manually.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t('shutdown')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final LidarrApi api =
            await ref.read(lidarrApiProvider(widget.instance).future);
        await api.system.postSystemShutdown();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.t('shutdownSignalSent'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.t('failedToShutdownE1', [e]))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(S.t('system')),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'restart') {
                _confirmRestart();
              } else if (value == 'shutdown') {
                _confirmShutdown();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'restart',
                child: ListTile(
                  leading: Icon(Icons.restart_alt),
                  title: Text(S.t('restart')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'shutdown',
                child: ListTile(
                  leading: Icon(Icons.power_settings_new),
                  title: Text(S.t('shutdown')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _subTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: S.t('status')),
            Tab(text: S.t('diskSpace')),
            Tab(text: S.t('tasks')),
            Tab(text: S.t('backups')),
            Tab(text: S.t('updates')),
            Tab(text: S.t('logs')),
            Tab(text: S.t('logFiles')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _subTabController,
        children: [
          StatusAndHealthView(instance: widget.instance),
          DiskSpaceView(instance: widget.instance),
          TasksAndMaintenanceView(instance: widget.instance),
          BackupsView(instance: widget.instance),
          UpdatesView(instance: widget.instance),
          LogsView(instance: widget.instance),
          LogFilesView(instance: widget.instance),
        ],
      ),
    );
  }
}
