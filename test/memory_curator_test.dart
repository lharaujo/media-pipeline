import 'package:flutter_test/flutter_test.dart';
import 'package:media_pipeline_app/src/memory_curator.dart';

void main() {
  test('builds the sample memory preview assets', () {
    final assets = buildMemoryPreviewSampleAssets();

    expect(assets, hasLength(4));
    expect(assets.map((asset) => asset.id), [
      'lisbon-1',
      'lisbon-2',
      'lisbon-3',
      'receipt-1',
    ]);
  });

  test('builds prior-year memory candidates without writing to Immich', () {
    final result = buildMemoryPreviewCandidates(
      referenceDate: DateTime(2026, 5, 29),
      assets: [
        MemoryPreviewAsset(
          id: 'a1',
          takenAt: DateTime(2024, 5, 27),
          isFavorite: true,
          peopleNames: const ['Leo'],
        ),
        MemoryPreviewAsset(
          id: 'a2',
          takenAt: DateTime(2024, 5, 30),
          peopleNames: const ['Ana'],
        ),
        MemoryPreviewAsset(id: 'current', takenAt: DateTime(2026, 5, 29)),
      ],
    );

    expect(result.exclusions, isEmpty);
    expect(result.candidates, hasLength(1));
    expect(result.candidates.single.title, 'This week in 2024');
    expect(result.candidates.single.assetIds, ['a1', 'a2']);
    expect(
      result.candidates.single.reasons,
      contains('Matches this week in a prior year'),
    );
    expect(result.candidates.single.score, greaterThan(40));
  });

  test('excludes low-value assets from preview candidates', () {
    final result = buildMemoryPreviewCandidates(
      referenceDate: DateTime(2026, 5, 29),
      assets: [
        MemoryPreviewAsset(id: 'photo', takenAt: DateTime(2024, 5, 29)),
        MemoryPreviewAsset(
          id: 'screenshot',
          takenAt: DateTime(2024, 5, 29),
          isScreenshot: true,
        ),
        MemoryPreviewAsset(
          id: 'receipt',
          takenAt: DateTime(2024, 5, 29),
          isReceipt: true,
        ),
        MemoryPreviewAsset(
          id: 'blurry',
          takenAt: DateTime(2024, 5, 29),
          isBlurry: true,
        ),
        MemoryPreviewAsset(
          id: 'near-duplicate',
          takenAt: DateTime(2024, 5, 29),
          isNearDuplicate: true,
        ),
      ],
    );

    expect(result.candidates, isEmpty);
    expect(result.exclusions.map((exclusion) => exclusion.assetId), [
      'screenshot',
      'receipt',
      'blurry',
      'near-duplicate',
    ]);
  });

  test('builds album and location candidates with explainable reasons', () {
    final assets = [
      MemoryPreviewAsset(
        id: 'trip-1',
        takenAt: DateTime(2025, 2, 1),
        albumNames: const ['Winter Trip'],
        city: 'Lisbon',
      ),
      MemoryPreviewAsset(
        id: 'trip-2',
        takenAt: DateTime(2025, 2, 2),
        albumNames: const ['Winter Trip'],
        city: 'Lisbon',
      ),
      MemoryPreviewAsset(
        id: 'trip-3',
        takenAt: DateTime(2025, 2, 3),
        albumNames: const ['Winter Trip'],
        city: 'Lisbon',
      ),
    ];

    final result = buildMemoryPreviewCandidates(
      referenceDate: DateTime(2026, 5, 29),
      assets: assets,
    );

    expect(
      result.candidates.map((candidate) => candidate.title),
      containsAll(['Album: Winter Trip', 'Place: Lisbon']),
    );
    expect(
      result.candidates
          .singleWhere((candidate) => candidate.title == 'Album: Winter Trip')
          .reasons,
      contains('Album membership suggests an event'),
    );
    expect(
      result.candidates
          .singleWhere((candidate) => candidate.title == 'Place: Lisbon')
          .reasons,
      contains('Location cluster'),
    );
  });
}
