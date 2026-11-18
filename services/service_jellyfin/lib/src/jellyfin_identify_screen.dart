import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jellyfin_providers.dart';
import 'models/jellyfin_item.dart';
import 'models/jellyfin_remote_search.dart';

class JellyfinIdentifyScreen extends ConsumerStatefulWidget {
  const JellyfinIdentifyScreen({
    required this.instance,
    required this.item,
    super.key,
  });

  final Instance instance;
  final JellyfinItem item;

  @override
  ConsumerState<JellyfinIdentifyScreen> createState() =>
      _JellyfinIdentifyScreenState();
}

class _JellyfinIdentifyScreenState
    extends ConsumerState<JellyfinIdentifyScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  late final TextEditingController _imdbController;
  late final TextEditingController _tmdbController;

  bool _isSearching = false;
  List<JellyfinRemoteSearchResult>? _results;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _yearController = TextEditingController(
      text: widget.item.productionYear?.toString() ?? '',
    );
    _imdbController = TextEditingController(text: '');
    _tmdbController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _imdbController.dispose();
    _tmdbController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final client = ref.read(jellyfinClientProvider(widget.instance)).value;
    if (client == null) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _results = null;
    });

    try {
      final yearText = _yearController.text.trim();
      final year = yearText.isNotEmpty ? int.tryParse(yearText) : null;

      final providerIds = <String, String>{};
      if (_imdbController.text.trim().isNotEmpty) {
        providerIds[S.t('imdb')] = _imdbController.text.trim();
      }
      if (_tmdbController.text.trim().isNotEmpty) {
        providerIds[S.t('tmdb')] = _tmdbController.text.trim();
      }

      final info = JellyfinRemoteSearchInfo(
        name: _nameController.text.trim(),
        year: year,
        providerIds: providerIds.isNotEmpty ? providerIds : null,
      );

      final results = await client.remoteSearch(
        widget.item.id,
        widget.item.type,
        info,
      );

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _apply(JellyfinRemoteSearchResult result) async {
    final client = ref.read(jellyfinClientProvider(widget.instance)).value;
    if (client == null) return;

    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t('replaceExistingImages')),
        content: Text(
          S.t('wouldYouLikeToReplaceAllExistingImagesWithTheOnesFromTheSelectedMetadataProvider'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.t('yes')),
          ),
        ],
      ),
    );

    if (replace == null || !mounted) return;

    try {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        ),
      );

      await client.applyRemoteSearch(
        widget.item.id,
        result,
        replaceAllImages: replace,
      );

      if (mounted) {
        Navigator.pop(context); // close loading
        Navigator.pop(context, true); // close identify screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('failedToApplyE1', [e]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t('identifyItem'))),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: Insets.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: S.t('name'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: S.t('year'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _imdbController,
                          decoration: InputDecoration(
                            labelText: S.t('imdbID'),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: TextField(
                          controller: _tmdbController,
                          decoration: InputDecoration(
                            labelText: S.t('tmdbID'),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),
                  FilledButton(
                    onPressed: _isSearching ? null : _search,
                    child: _isSearching
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(S.t('search')),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Insets.md),
                    Text(
                      _error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_results != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final res = _results![index];
                  return ListTile(
                    leading: res.imageUrl != null
                        ? Image.network(
                            res.imageUrl!,
                            headers: ArtworkHeaders.forUrl(res.imageUrl!),
                            width: 40,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image),
                          )
                        : const Icon(Icons.movie),
                    title: Text(res.name ?? S.t('unknown')),
                    subtitle: Text(
                      '${res.productionYear ?? ''} • ${res.searchProviderName ?? ''}',
                    ),
                    onTap: () => _apply(res),
                  );
                },
                childCount: _results!.length,
              ),
            ),
        ],
      ),
    );
  }
}
