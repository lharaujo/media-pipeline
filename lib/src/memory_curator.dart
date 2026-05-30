class MemoryPreviewAsset {
  const MemoryPreviewAsset({
    required this.id,
    required this.takenAt,
    this.isFavorite = false,
    this.albumNames = const [],
    this.peopleNames = const [],
    this.city,
    this.isScreenshot = false,
    this.isReceipt = false,
    this.isBlurry = false,
    this.isNearDuplicate = false,
  });

  final String id;
  final DateTime takenAt;
  final bool isFavorite;
  final List<String> albumNames;
  final List<String> peopleNames;
  final String? city;
  final bool isScreenshot;
  final bool isReceipt;
  final bool isBlurry;
  final bool isNearDuplicate;
}

class MemoryPreviewCandidate {
  const MemoryPreviewCandidate({
    required this.title,
    required this.assetIds,
    required this.score,
    required this.reasons,
  });

  final String title;
  final List<String> assetIds;
  final int score;
  final List<String> reasons;
}

enum MemoryPreviewExclusionReason { screenshot, receipt, blurry, nearDuplicate }

class MemoryPreviewExclusion {
  const MemoryPreviewExclusion({required this.assetId, required this.reason});

  final String assetId;
  final MemoryPreviewExclusionReason reason;
}

class MemoryPreviewResult {
  const MemoryPreviewResult({
    required this.candidates,
    required this.exclusions,
  });

  final List<MemoryPreviewCandidate> candidates;
  final List<MemoryPreviewExclusion> exclusions;
}

List<MemoryPreviewAsset> buildMemoryPreviewSampleAssets() {
  return [
    MemoryPreviewAsset(
      id: 'lisbon-1',
      takenAt: DateTime(2024, 5, 27),
      isFavorite: true,
      albumNames: ['Lisbon Week'],
      peopleNames: ['Leo'],
      city: 'Lisbon',
    ),
    MemoryPreviewAsset(
      id: 'lisbon-2',
      takenAt: DateTime(2024, 5, 29),
      albumNames: ['Lisbon Week'],
      peopleNames: ['Ana'],
      city: 'Lisbon',
    ),
    MemoryPreviewAsset(
      id: 'lisbon-3',
      takenAt: DateTime(2024, 5, 30),
      albumNames: ['Lisbon Week'],
      city: 'Lisbon',
    ),
    MemoryPreviewAsset(
      id: 'receipt-1',
      takenAt: DateTime(2024, 5, 29),
      isReceipt: true,
    ),
  ];
}

MemoryPreviewResult buildMemoryPreviewCandidates({
  required List<MemoryPreviewAsset> assets,
  required DateTime referenceDate,
}) {
  final usableAssets = <MemoryPreviewAsset>[];
  final exclusions = <MemoryPreviewExclusion>[];

  for (final asset in assets) {
    final reason = _exclusionReason(asset);
    if (reason == null) {
      usableAssets.add(asset);
    } else {
      exclusions.add(MemoryPreviewExclusion(assetId: asset.id, reason: reason));
    }
  }

  final candidates =
      [
        ..._buildPriorYearCandidates(usableAssets, referenceDate),
        ..._buildAlbumCandidates(usableAssets),
        ..._buildLocationCandidates(usableAssets),
      ]..sort((a, b) {
        final scoreOrder = b.score.compareTo(a.score);
        if (scoreOrder != 0) {
          return scoreOrder;
        }
        return a.title.compareTo(b.title);
      });

  return MemoryPreviewResult(candidates: candidates, exclusions: exclusions);
}

MemoryPreviewExclusionReason? _exclusionReason(MemoryPreviewAsset asset) {
  if (asset.isScreenshot) {
    return MemoryPreviewExclusionReason.screenshot;
  }
  if (asset.isReceipt) {
    return MemoryPreviewExclusionReason.receipt;
  }
  if (asset.isBlurry) {
    return MemoryPreviewExclusionReason.blurry;
  }
  if (asset.isNearDuplicate) {
    return MemoryPreviewExclusionReason.nearDuplicate;
  }
  return null;
}

List<MemoryPreviewCandidate> _buildPriorYearCandidates(
  List<MemoryPreviewAsset> assets,
  DateTime referenceDate,
) {
  final groupedByYear = <int, List<MemoryPreviewAsset>>{};
  for (final asset in assets) {
    if (asset.takenAt.year >= referenceDate.year) {
      continue;
    }
    if (_dayDistance(asset.takenAt, referenceDate) > 3) {
      continue;
    }
    groupedByYear.putIfAbsent(asset.takenAt.year, () => []).add(asset);
  }

  return [
    for (final entry in groupedByYear.entries)
      if (entry.value.length >= 2)
        _candidate(
          title: 'This week in ${entry.key}',
          assets: entry.value,
          baseScore: 40,
          reasons: [
            'Matches this week in a prior year',
            '${entry.value.length} assets found',
          ],
        ),
  ];
}

List<MemoryPreviewCandidate> _buildAlbumCandidates(
  List<MemoryPreviewAsset> assets,
) {
  final groupedByAlbum = <String, List<MemoryPreviewAsset>>{};
  for (final asset in assets) {
    for (final album in asset.albumNames.map((value) => value.trim())) {
      if (album.isEmpty) {
        continue;
      }
      groupedByAlbum.putIfAbsent(album, () => []).add(asset);
    }
  }

  return [
    for (final entry in groupedByAlbum.entries)
      if (entry.value.length >= 3)
        _candidate(
          title: 'Album: ${entry.key}',
          assets: entry.value,
          baseScore: 30,
          reasons: [
            'Album membership suggests an event',
            '${entry.value.length} assets found',
          ],
        ),
  ];
}

List<MemoryPreviewCandidate> _buildLocationCandidates(
  List<MemoryPreviewAsset> assets,
) {
  final groupedByCity = <String, List<MemoryPreviewAsset>>{};
  for (final asset in assets) {
    final city = asset.city?.trim();
    if (city == null || city.isEmpty) {
      continue;
    }
    groupedByCity.putIfAbsent(city, () => []).add(asset);
  }

  return [
    for (final entry in groupedByCity.entries)
      if (entry.value.length >= 3)
        _candidate(
          title: 'Place: ${entry.key}',
          assets: entry.value,
          baseScore: 25,
          reasons: ['Location cluster', '${entry.value.length} assets found'],
        ),
  ];
}

MemoryPreviewCandidate _candidate({
  required String title,
  required List<MemoryPreviewAsset> assets,
  required int baseScore,
  required List<String> reasons,
}) {
  final sortedAssets = [...assets]
    ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
  final favoriteCount = sortedAssets.where((asset) => asset.isFavorite).length;
  final peopleCount = sortedAssets
      .expand((asset) => asset.peopleNames)
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .length;
  final score =
      baseScore + sortedAssets.length + favoriteCount * 5 + peopleCount * 2;

  return MemoryPreviewCandidate(
    title: title,
    assetIds: [for (final asset in sortedAssets) asset.id],
    score: score,
    reasons: [
      ...reasons,
      if (favoriteCount > 0) '$favoriteCount favorite assets',
      if (peopleCount > 0) '$peopleCount people detected',
    ],
  );
}

int _dayDistance(DateTime left, DateTime right) {
  final normalizedLeft = DateTime(2000, left.month, left.day);
  final normalizedRight = DateTime(2000, right.month, right.day);
  final directDistance = normalizedLeft
      .difference(normalizedRight)
      .inDays
      .abs();
  return directDistance > 183 ? 366 - directDistance : directDistance;
}
