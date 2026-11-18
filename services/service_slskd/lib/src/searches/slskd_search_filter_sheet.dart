import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import 'slskd_search_models_ui.dart';

/// Modal bottom sheet for filtering and sorting P2P Soulseek search results.
class SlskdSearchFilterSheet extends StatefulWidget {
  const SlskdSearchFilterSheet({
    required this.selectedFormat,
    required this.selectedSort,
    required this.freeSlotOnly,
    required this.hideLocked,
    required this.onApply,
    super.key,
  });

  final SlskdSearchFormatFilter selectedFormat;
  final SlskdSearchSort selectedSort;
  final bool freeSlotOnly;
  final bool hideLocked;
  final void Function({
    required SlskdSearchFormatFilter format,
    required SlskdSearchSort sort,
    required bool freeSlotOnly,
    required bool hideLocked,
  }) onApply;

  @override
  State<SlskdSearchFilterSheet> createState() => _SlskdSearchFilterSheetState();
}

class _SlskdSearchFilterSheetState extends State<SlskdSearchFilterSheet> {
  late SlskdSearchFormatFilter _format;
  late SlskdSearchSort _sort;
  late bool _freeSlotOnly;
  late bool _hideLocked;

  @override
  void initState() {
    super.initState();
    _format = widget.selectedFormat;
    _sort = widget.selectedSort;
    _freeSlotOnly = widget.freeSlotOnly;
    _hideLocked = widget.hideLocked;
  }

  void _reset() {
    setState(() {
      _format = SlskdSearchFormatFilter.all;
      _sort = SlskdSearchSort.fastestSpeed;
      _freeSlotOnly = false;
      _hideLocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Insets.md, Insets.xs, Insets.md, Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header Row: Title & Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  S.t('sortFilterResults'),
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(S.t('resetAll')),
                ),
              ],
            ),
            const Divider(height: Insets.sm),

            // 1. Audio Format Filter
            Text(
              'Audio Format',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: Insets.xs),
            Wrap(
              spacing: Insets.xs,
              children: SlskdSearchFormatFilter.values.map((f) {
                final bool isSelected = _format == f;
                return FilterChip(
                  label: Text(f.label),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _format = f);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: Insets.md),

            // 2. Peer Availability & Locks
            Text(
              'Availability & Access',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: Insets.xs),
            Wrap(
              spacing: Insets.xs,
              children: <Widget>[
                FilterChip(
                  avatar: Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: _freeSlotOnly ? colorScheme.onSecondaryContainer : colorScheme.outline,
                  ),
                  label: Text(S.t('freeSlotOnlyInstant')),
                  selected: _freeSlotOnly,
                  onSelected: (val) => setState(() => _freeSlotOnly = val),
                ),
                FilterChip(
                  avatar: Icon(
                    Icons.lock_open_rounded,
                    size: 16,
                    color: _hideLocked ? colorScheme.onSecondaryContainer : colorScheme.outline,
                  ),
                  label: Text(S.t('hideLockedFiles')),
                  selected: _hideLocked,
                  onSelected: (val) => setState(() => _hideLocked = val),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),

            // 3. Sort By
            Text(
              S.t('sortBy'),
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: Insets.xs),
            Wrap(
              spacing: Insets.xs,
              runSpacing: Insets.xs,
              children: SlskdSearchSort.values.map((s) {
                final bool isSelected = _sort == s;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _sort = s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: Insets.lg),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(
                    format: _format,
                    sort: _sort,
                    freeSlotOnly: _freeSlotOnly,
                    hideLocked: _hideLocked,
                  );
                  Navigator.of(context).pop();
                },
                child: Text(S.t('done')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
