import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sonarr_providers.dart';
import 'widgets/confirm_delete.dart';

class MediaManagementSettingsScreen extends ConsumerStatefulWidget {
  const MediaManagementSettingsScreen({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<MediaManagementSettingsScreen> createState() =>
      _MediaManagementSettingsScreenState();
}

class _MediaManagementSettingsScreenState
    extends ConsumerState<MediaManagementSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Naming controller state
  late final TextEditingController _standardEpisodeController;
  late final TextEditingController _dailyEpisodeController;
  late final TextEditingController _animeEpisodeController;
  late final TextEditingController _seriesFolderController;
  late final TextEditingController _seasonFolderController;
  late final TextEditingController _specialsFolderController;

  // Naming config options
  bool _renameEpisodes = false;
  bool _replaceIllegalCharacters = false;
  int _colonReplacementFormat = 4;

  // Media management config state
  bool _createEmptySeriesFolders = false;
  bool _deleteEmptyFolders = false;
  bool _copyUsingHardlinks = false;
  bool _importExtraFiles = false;
  late final TextEditingController _extraFileExtensionsController;
  bool _enableMediaInfo = false;
  late final TextEditingController _minimumFreeSpaceController;
  bool _autoUnmonitorPreviouslyDownloadedEpisodes = false;
  bool _skipFreeSpaceCheckWhenImporting = false;
  bool _setPermissionsLinux = false;

  late final TextEditingController _recycleBinController;
  late final TextEditingController _recycleBinCleanupDaysController;
  late final TextEditingController _chmodFolderController;
  late final TextEditingController _chownGroupController;

  String _downloadPropersAndRepacks = 'preferAndUpgrade';
  String _fileDate = 'none';
  String _rescanAfterRefresh = 'always';
  String _episodeTitleRequired = 'always';

  bool _saving = false;
  bool _initialized = false;

  // Raw configs for PUT payloads
  Map<String, dynamic>? _rawNamingConfig;
  Map<String, dynamic>? _rawMediaManagementConfig;

  @override
  void initState() {
    super.initState();
    _standardEpisodeController = TextEditingController();
    _dailyEpisodeController = TextEditingController();
    _animeEpisodeController = TextEditingController();
    _seriesFolderController = TextEditingController();
    _seasonFolderController = TextEditingController();
    _specialsFolderController = TextEditingController();
    _extraFileExtensionsController = TextEditingController();
    _minimumFreeSpaceController = TextEditingController();
    _recycleBinController = TextEditingController();
    _recycleBinCleanupDaysController = TextEditingController();
    _chmodFolderController = TextEditingController();
    _chownGroupController = TextEditingController();
  }

  @override
  void dispose() {
    _standardEpisodeController.dispose();
    _dailyEpisodeController.dispose();
    _animeEpisodeController.dispose();
    _seriesFolderController.dispose();
    _seasonFolderController.dispose();
    _specialsFolderController.dispose();
    _extraFileExtensionsController.dispose();
    _minimumFreeSpaceController.dispose();
    _recycleBinController.dispose();
    _recycleBinCleanupDaysController.dispose();
    _chmodFolderController.dispose();
    _chownGroupController.dispose();
    super.dispose();
  }

  void _initializeValues(
    Map<String, dynamic> naming,
    Map<String, dynamic> mediaMgmt,
  ) {
    if (_initialized) return;
    _initialized = true;

    _rawNamingConfig = naming;
    _rawMediaManagementConfig = mediaMgmt;

    _renameEpisodes = naming['renameEpisodes'] as bool? ?? false;
    _replaceIllegalCharacters =
        naming['replaceIllegalCharacters'] as bool? ?? false;
    _colonReplacementFormat = naming['colonReplacementFormat'] as int? ?? 4;

    _standardEpisodeController.text =
        (naming['standardEpisodeFormat'] as String?) ?? '';
    _dailyEpisodeController.text =
        (naming['dailyEpisodeFormat'] as String?) ?? '';
    _animeEpisodeController.text =
        (naming['animeEpisodeFormat'] as String?) ?? '';
    _seriesFolderController.text =
        (naming['seriesFolderFormat'] as String?) ?? '';
    _seasonFolderController.text =
        (naming['seasonFolderFormat'] as String?) ?? '';
    _specialsFolderController.text =
        (naming['specialsFolderFormat'] as String?) ?? '';

    _createEmptySeriesFolders =
        mediaMgmt['createEmptySeriesFolders'] as bool? ?? false;
    _deleteEmptyFolders = mediaMgmt['deleteEmptyFolders'] as bool? ?? false;
    _copyUsingHardlinks = mediaMgmt['copyUsingHardlinks'] as bool? ?? false;
    _importExtraFiles = mediaMgmt['importExtraFiles'] as bool? ?? false;
    _extraFileExtensionsController.text =
        (mediaMgmt['extraFileExtensions'] as String?) ?? '';
    _enableMediaInfo = mediaMgmt['enableMediaInfo'] as bool? ?? false;
    _minimumFreeSpaceController.text =
        (mediaMgmt['minimumFreeSpaceWhenImporting'] as int? ?? 0).toString();

    _autoUnmonitorPreviouslyDownloadedEpisodes =
        mediaMgmt['autoUnmonitorPreviouslyDownloadedEpisodes'] as bool? ??
            false;
    _skipFreeSpaceCheckWhenImporting =
        mediaMgmt['skipFreeSpaceCheckWhenImporting'] as bool? ?? false;
    _setPermissionsLinux = mediaMgmt['setPermissionsLinux'] as bool? ?? false;

    _recycleBinController.text = (mediaMgmt['recycleBin'] as String?) ?? '';
    _recycleBinCleanupDaysController.text =
        (mediaMgmt['recycleBinCleanupDays'] as int? ?? 7).toString();
    _chmodFolderController.text = (mediaMgmt['chmodFolder'] as String?) ?? '';
    _chownGroupController.text = (mediaMgmt['chownGroup'] as String?) ?? '';

    _downloadPropersAndRepacks =
        (mediaMgmt['downloadPropersAndRepacks'] as String?) ??
            'preferAndUpgrade';
    _fileDate = (mediaMgmt['fileDate'] as String?) ?? 'none';
    _rescanAfterRefresh =
        (mediaMgmt['rescanAfterRefresh'] as String?) ?? 'always';
    _episodeTitleRequired =
        (mediaMgmt['episodeTitleRequired'] as String?) ?? 'always';
  }

  /// Builds dropdown items from known [options] (value to label) and appends
  /// the current server [value] as a raw extra item when it is not among the
  /// known ones, so the dropdown never hits the missing-value assert.
  static List<DropdownMenuItem<String>> _dropdownItems(
    Map<String, String> options,
    String value,
  ) {
    return [
      for (final entry in options.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      if (!options.containsKey(value))
        DropdownMenuItem(value: value, child: Text(value)),
    ];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rawNamingConfig == null || _rawMediaManagementConfig == null) return;

    setState(() => _saving = true);

    try {
      final api = await ref.read(sonarrApiProvider(widget.instance).future);

      // 1. Prepare naming update payload
      final Map<String, dynamic> namingPayload =
          Map<String, dynamic>.from(_rawNamingConfig!);
      namingPayload['renameEpisodes'] = _renameEpisodes;
      namingPayload['replaceIllegalCharacters'] = _replaceIllegalCharacters;
      namingPayload['colonReplacementFormat'] = _colonReplacementFormat;
      namingPayload['standardEpisodeFormat'] =
          _standardEpisodeController.text.trim();
      namingPayload['dailyEpisodeFormat'] = _dailyEpisodeController.text.trim();
      namingPayload['animeEpisodeFormat'] = _animeEpisodeController.text.trim();
      namingPayload['seriesFolderFormat'] = _seriesFolderController.text.trim();
      namingPayload['seasonFolderFormat'] = _seasonFolderController.text.trim();
      namingPayload['specialsFolderFormat'] =
          _specialsFolderController.text.trim();

      // 2. Prepare media management update payload
      final Map<String, dynamic> mediaMgmtPayload =
          Map<String, dynamic>.from(_rawMediaManagementConfig!);
      mediaMgmtPayload['createEmptySeriesFolders'] = _createEmptySeriesFolders;
      mediaMgmtPayload['deleteEmptyFolders'] = _deleteEmptyFolders;
      mediaMgmtPayload['copyUsingHardlinks'] = _copyUsingHardlinks;
      mediaMgmtPayload['importExtraFiles'] = _importExtraFiles;
      mediaMgmtPayload['extraFileExtensions'] =
          _extraFileExtensionsController.text.trim();
      mediaMgmtPayload['enableMediaInfo'] = _enableMediaInfo;
      mediaMgmtPayload['minimumFreeSpaceWhenImporting'] =
          int.tryParse(_minimumFreeSpaceController.text.trim()) ?? 0;

      mediaMgmtPayload['autoUnmonitorPreviouslyDownloadedEpisodes'] =
          _autoUnmonitorPreviouslyDownloadedEpisodes;
      mediaMgmtPayload['skipFreeSpaceCheckWhenImporting'] =
          _skipFreeSpaceCheckWhenImporting;
      mediaMgmtPayload['setPermissionsLinux'] = _setPermissionsLinux;

      mediaMgmtPayload['recycleBin'] = _recycleBinController.text.trim();
      mediaMgmtPayload['recycleBinCleanupDays'] =
          int.tryParse(_recycleBinCleanupDaysController.text.trim()) ?? 7;
      mediaMgmtPayload['chmodFolder'] = _chmodFolderController.text.trim();
      mediaMgmtPayload['chownGroup'] = _chownGroupController.text.trim();

      mediaMgmtPayload['downloadPropersAndRepacks'] =
          _downloadPropersAndRepacks;
      mediaMgmtPayload['fileDate'] = _fileDate;
      mediaMgmtPayload['rescanAfterRefresh'] = _rescanAfterRefresh;
      mediaMgmtPayload['episodeTitleRequired'] = _episodeTitleRequired;

      // 3. Dispatch calls
      await api.updateNamingConfig(namingPayload);
      await api.updateMediaManagementConfig(mediaMgmtPayload);

      // Invalidate providers
      ref.invalidate(sonarrNamingConfigProvider(widget.instance));
      ref.invalidate(sonarrMediaManagementConfigProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('mediaManagementSettingsSaved'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('failedToSaveSettingsE1', [e]))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatFreeSpace(dynamic bytes) {
    if (bytes == null) return S.t('unknown');
    final int b = bytes is int ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (b <= 0) return '0 B';
    final double gib = b / (1024 * 1024 * 1024);
    if (gib >= 1024) {
      return '${(gib / 1024).toStringAsFixed(1)} TiB';
    }
    return '${gib.toStringAsFixed(1)} GiB';
  }

  Future<void> _showAddRootFolderDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.t('addRootFolder')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: S.t('path'),
              hintText: S.t('eGDataMediaTv'),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final path = controller.text.trim();
                if (path.isEmpty) return;
                try {
                  final api =
                      await ref.read(sonarrApiProvider(widget.instance).future);
                  await api.createRootFolder(<String, dynamic>{'path': path});
                  ref.invalidate(sonarrRootFoldersProvider(widget.instance));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.t('rootFolderAdded'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.t('failedToAddRootFolderE1', [e]))),
                    );
                  }
                }
              },
              child: Text(S.t('save')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRootFolder(int id, String path) async {
    final confirmed = await confirmDelete(context, 'Root Folder "$path"');
    if (!confirmed) return;
    try {
      final api = await ref.read(sonarrApiProvider(widget.instance).future);
      await api.deleteRootFolder(id);
      ref.invalidate(sonarrRootFoldersProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('rootFolderDeleted'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('failedToDeleteRootFolderE1', [e]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final namingAsync = ref.watch(sonarrNamingConfigProvider(widget.instance));
    final mediaMgmtAsync =
        ref.watch(sonarrMediaManagementConfigProvider(widget.instance));
    final rootFoldersAsync =
        ref.watch(sonarrRootFoldersProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('mediaManagement')),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: ExpressiveProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: namingAsync.when(
        loading: () => const Center(child: ExpressiveProgressIndicator()),
        error: (err, stack) => Center(child: Text(S.t('errorErr1', [err]))),
        data: (naming) {
          return mediaMgmtAsync.when(
            loading: () => const Center(child: ExpressiveProgressIndicator()),
            error: (err, stack) => Center(child: Text(S.t('errorErr1', [err]))),
            data: (mediaMgmt) {
              _initializeValues(naming, mediaMgmt);

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(Insets.md),
                  children: [
                    // --- Naming Section ---
                    Card(
                      margin: const EdgeInsets.only(bottom: Insets.md),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: Radii.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.t('episodeNaming'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(S.t('renameEpisodes')),
                              subtitle: const Text(
                                'Change episode file names based on naming format',
                              ),
                              value: _renameEpisodes,
                              onChanged: (val) =>
                                  setState(() => _renameEpisodes = val),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(S.t('replaceIllegalCharacters')),
                              subtitle: const Text(
                                'Sanitize standard OS invalid filename characters',
                              ),
                              value: _replaceIllegalCharacters,
                              onChanged: (val) => setState(
                                () => _replaceIllegalCharacters = val,
                              ),
                            ),
                            const SizedBox(height: Insets.sm),
                            DropdownButtonFormField<int>(
                              initialValue: _colonReplacementFormat,
                              decoration: InputDecoration(
                                labelText: S.t('colonReplacementFormat'),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text(S.t('delete')),
                                ),
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text(S.t('replaceWithSpace')),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text(S.t('replaceWithDash')),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text(S.t('replaceWithSpaceDashSpace')),
                                ),
                                DropdownMenuItem(
                                  value: 4,
                                  child: Text(S.t('smartReplace_2')),
                                ),
                                if (_colonReplacementFormat < 0 ||
                                    _colonReplacementFormat > 4)
                                  DropdownMenuItem(
                                    value: _colonReplacementFormat,
                                    child: Text('$_colonReplacementFormat'),
                                  ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _colonReplacementFormat = val);
                                }
                              },
                            ),
                            if (_renameEpisodes) ...[
                              const SizedBox(height: Insets.md),
                              TextFormField(
                                controller: _standardEpisodeController,
                                decoration: InputDecoration(
                                  labelText: S.t('standardEpisodeFormat'),
                                  border: OutlineInputBorder(),
                                  helperText:
                                      S.t('eGSeriesTitleSSeason00EEpisode00EpisodeTitle'),
                                ),
                              ),
                              const SizedBox(height: Insets.md),
                              TextFormField(
                                controller: _dailyEpisodeController,
                                decoration: InputDecoration(
                                  labelText: S.t('dailyEpisodeFormat'),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: Insets.md),
                              TextFormField(
                                controller: _animeEpisodeController,
                                decoration: InputDecoration(
                                  labelText: S.t('animeEpisodeFormat'),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                            const SizedBox(height: Insets.md),
                            TextFormField(
                              controller: _seriesFolderController,
                              decoration: InputDecoration(
                                labelText: S.t('seriesFolderFormat'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            TextFormField(
                              controller: _seasonFolderController,
                              decoration: InputDecoration(
                                labelText: S.t('seasonFolderFormat'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            TextFormField(
                              controller: _specialsFolderController,
                              decoration: InputDecoration(
                                labelText: S.t('specialsFolderFormat'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Root Folders Section ---
                    Card(
                      margin: const EdgeInsets.only(bottom: Insets.md),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: Radii.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.t('rootFolders'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            rootFoldersAsync.when(
                              loading: () => const Center(
                                child: ExpressiveProgressIndicator(),
                              ),
                              error: (err, stack) => Text(S.t('errorLoadingRootFoldersErr1', [err])),
                              data: (folders) {
                                if (folders.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: Insets.md),
                                    child: Text(S.t('noRootFoldersConfigured')),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: folders.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, idx) {
                                    final folder = folders[idx];
                                    final id = folder['id'] as int;
                                    final path = folder['path'] as String? ?? S.t('unknown');
                                    final freeSpace = folder['freeSpace'];
                                    final unmapped = (folder['unmappedFolders'] as List?)?.length ?? 0;

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        path,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Free Space: ${_formatFreeSpace(freeSpace)} • Unmapped Folders: $unmapped',
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: theme.colorScheme.error,
                                        ),
                                        onPressed: () => _deleteRootFolder(id, path),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: Insets.md),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showAddRootFolderDialog,
                                icon: const Icon(Icons.add),
                                label: Text(S.t('addRootFolder')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Folders & Importing Section ---
                    Card(
                      margin: const EdgeInsets.only(bottom: Insets.md),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: Radii.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.t('foldersImporting'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(S.t('createEmptySeriesFolders')),
                              subtitle: const Text(
                                'Create directories automatically on disk scanner activity',
                              ),
                              value: _createEmptySeriesFolders,
                              onChanged: (val) => setState(
                                () => _createEmptySeriesFolders = val,
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(S.t('deleteEmptyFolders')),
                              subtitle: Text(
                                S.t('removeFoldersThatHaveNoMediaAssetsRemaining'),
                              ),
                              value: _deleteEmptyFolders,
                              onChanged: (val) =>
                                  setState(() => _deleteEmptyFolders = val),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title:
                                  Text(S.t('useHardlinksInsteadOfCopy')),
                              subtitle: Text(
                                S.t('highlyRecommendedForSamePoolStorageSeedingSetups'),
                              ),
                              value: _copyUsingHardlinks,
                              onChanged: (val) =>
                                  setState(() => _copyUsingHardlinks = val),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                S.t('autoUnmonitorPreviouslyDownloaded'),
                              ),
                              subtitle: Text(
                                S.t('unmonitorEpisodesOnceTheyHaveBeenDeletedFromDisk'),
                              ),
                              value: _autoUnmonitorPreviouslyDownloadedEpisodes,
                              onChanged: (val) => setState(
                                () =>
                                    _autoUnmonitorPreviouslyDownloadedEpisodes =
                                        val,
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                S.t('skipFreeSpaceCheckWhenImporting'),
                              ),
                              value: _skipFreeSpaceCheckWhenImporting,
                              onChanged: (val) => setState(
                                () => _skipFreeSpaceCheckWhenImporting = val,
                              ),
                            ),
                            const SizedBox(height: Insets.sm),
                            TextFormField(
                              controller: _minimumFreeSpaceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: S.t('minimumFreeSpaceMB'),
                                border: OutlineInputBorder(),
                                helperText:
                                    'Prevent imports if free space drops below threshold',
                              ),
                              validator: (val) {
                                if (val != null &&
                                    int.tryParse(val.trim()) == null) {
                                  return S.t('mustBeAValidInteger');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: Insets.md),
                            DropdownButtonFormField<String>(
                              initialValue: _downloadPropersAndRepacks,
                              decoration: InputDecoration(
                                labelText: S.t('propersAndRepacks'),
                                border: OutlineInputBorder(),
                              ),
                              items: _dropdownItems(
                                {
                                  'preferAndUpgrade': S.t('preferAndUpgrade'),
                                  'doNotUpgrade':
                                      S.t('doNotUpgradeAutomatically'),
                                  'doNotPrefer': S.t('doNotPrefer'),
                                },
                                _downloadPropersAndRepacks,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(
                                    () => _downloadPropersAndRepacks = val,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: Insets.md),
                            DropdownButtonFormField<String>(
                              initialValue: _episodeTitleRequired,
                              decoration: InputDecoration(
                                labelText: S.t('episodeTitleRequired'),
                                border: OutlineInputBorder(),
                              ),
                              items: _dropdownItems(
                                {
                                  'always': S.t('always'),
                                  'bulkSeasonReleases':
                                      S.t('onlyForBulkSeasonReleases'),
                                  'never': S.t('never'),
                                },
                                _episodeTitleRequired,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _episodeTitleRequired = val);
                                }
                              },
                            ),
                            const SizedBox(height: Insets.md),
                            DropdownButtonFormField<String>(
                              initialValue: _fileDate,
                              decoration: InputDecoration(
                                labelText: S.t('fileDate'),
                                border: OutlineInputBorder(),
                              ),
                              items: _dropdownItems(
                                {
                                  'none': 'None',
                                  'localAirDate': S.t('localAirDate'),
                                  'utcAirDate': S.t('utcAirDate'),
                                },
                                _fileDate,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _fileDate = val);
                                }
                              },
                            ),
                            const SizedBox(height: Insets.md),
                            DropdownButtonFormField<String>(
                              initialValue: _rescanAfterRefresh,
                              decoration: InputDecoration(
                                labelText: S.t('rescanAfterRefresh'),
                                border: OutlineInputBorder(),
                              ),
                              items: _dropdownItems(
                                {
                                  'always': S.t('always'),
                                  'afterManual': S.t('afterManualRefresh'),
                                  'never': S.t('never'),
                                },
                                _rescanAfterRefresh,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _rescanAfterRefresh = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Extra Files Section ---
                    Card(
                      margin: const EdgeInsets.only(bottom: Insets.md),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: Radii.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.t('extraFiles'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(S.t('importExtraFiles')),
                              subtitle: Text(
                                S.t('moveSubtitlesNFOOrMetadataWithVideoFiles'),
                              ),
                              value: _importExtraFiles,
                              onChanged: (val) =>
                                  setState(() => _importExtraFiles = val),
                            ),
                            if (_importExtraFiles) ...[
                              const SizedBox(height: Insets.md),
                              TextFormField(
                                controller: _extraFileExtensionsController,
                                decoration: InputDecoration(
                                  labelText: S.t('extraFileExtensions'),
                                  border: OutlineInputBorder(),
                                  helperText:
                                      S.t('commaSeparatedListEGSrtNfoTxt'),
                                ),
                              ),
                            ],
                            const SizedBox(height: Insets.md),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(S.t('enableMediaInfo')),
                              subtitle: Text(
                                S.t('extractAudioChannelsVideoCodecAndSubtitleInfo'),
                              ),
                              value: _enableMediaInfo,
                              onChanged: (val) =>
                                  setState(() => _enableMediaInfo = val),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Recycle Bin Section ---
                    Card(
                      margin: const EdgeInsets.only(bottom: Insets.md),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: Radii.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.t('recycleBin'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            TextFormField(
                              controller: _recycleBinController,
                              decoration: InputDecoration(
                                labelText: S.t('recycleBinPath'),
                                border: OutlineInputBorder(),
                                helperText:
                                    S.t('deletedFilesWillBeMovedHereInsteadOfPermanentlyDeleted'),
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            TextFormField(
                              controller: _recycleBinCleanupDaysController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: S.t('recycleBinCleanupDays'),
                                border: OutlineInputBorder(),
                                helperText:
                                    S.t('numberOfDaysBeforeFilesArePurgedUse0ToDisable'),
                              ),
                              validator: (val) {
                                if (val != null &&
                                    int.tryParse(val.trim()) == null) {
                                  return S.t('mustBeAValidInteger');
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Linux Permissions Section ---
                    Card(
                      margin: const EdgeInsets.only(bottom: Insets.md),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: Radii.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.t('permissions'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: Insets.md),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(S.t('setPermissionsLinux_2')),
                              value: _setPermissionsLinux,
                              onChanged: (val) =>
                                  setState(() => _setPermissionsLinux = val),
                            ),
                            if (_setPermissionsLinux) ...[
                              const SizedBox(height: Insets.md),
                              TextFormField(
                                controller: _chmodFolderController,
                                decoration: InputDecoration(
                                  labelText: S.t('folderCHMODMode'),
                                  border: OutlineInputBorder(),
                                  helperText: S.t('octalFormatEG755'),
                                ),
                              ),
                              const SizedBox(height: Insets.md),
                              TextFormField(
                                controller: _chownGroupController,
                                decoration: InputDecoration(
                                  labelText: S.t('groupCHOWNGroup'),
                                  border: OutlineInputBorder(),
                                  helperText: S.t('groupNameOrID'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
