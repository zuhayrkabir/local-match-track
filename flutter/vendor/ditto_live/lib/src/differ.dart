import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";
import "package:cbor/simple.dart";

import "analysis/annotations.dart";
import "bridge/bridge.dart" as core;
import "store/execute.dart";
import "store/store.dart";

/// Calculates diffs between arrays of [QueryResultItem]s.
///
/// Use a [Differ] with a [StoreObserver] to get the diff between
/// subsequent query results delivered by the store observer.
@external
final class Differ {
  /// Create a new [Differ] instance.
  Differ() : _ptr = core.dittoFfiDifferNew();

  final core.CPPointer<core.CPDiffer> _ptr;

  /// Calculate the diff of the provided [items] against the last set of items
  /// that were passed to this differ.
  ///
  /// The returned [Diff] identifies changes from the old array of items to the
  /// new array of items using indices into both arrays.
  ///
  /// Initially, the differ has no items, so the first call to this method will
  /// always return a diff showing all items as insertions.
  ///
  /// The identity of items is determined by their `_id` field.
  ///
  /// __Warning:__ This method can not be used with subtypes of [QueryResultItem].
  Diff diff(
    List<QueryResultItem> items,
  ) {
    final resultCbor = core.dittoFfiDifferDiff(
      _ptr,
      items.toPointerList(),
    );
    return Diff.fromCbor(resultCbor);
  }
}

/// Represents a diff between two arrays.
///
/// Create a diff between arrays of [QueryResultItem]s using a [Differ].
@external
final class Diff with EquatableMixin {
  /// The set of indexes in the _new_ array at which items were inserted.
  final Set<int> insertions;

  /// The set of indexes in the _old_ array at which items were deleted.
  final Set<int> deletions;

  /// The set of indexes in the _new_ array at which items have been updated.
  final Set<int> updates;

  /// A set of [DiffMove]s, each representing a move of an item `from` a
  /// particular index in the _old_ array `to` a particular index in the _new_
  /// array.
  final Set<DiffMove> moves;

  Diff({
    required this.insertions,
    required this.deletions,
    required this.updates,
    required this.moves,
  });

  factory Diff.fromCbor(Uint8List cborBytes) {
    final json = Map<String, dynamic>.from(
      cbor.decode(cborBytes.toList())! as Map,
    );
    final insertions = Set<int>.from(
      json["insertions"] as List<dynamic>,
    );
    final deletions = Set<int>.from(
      json["deletions"] as List<dynamic>,
    );
    final updates = Set<int>.from(
      json["updates"] as List<dynamic>,
    );

    final moves = Set<DiffMove>.from(
      (json["moves"] as List<dynamic>).map(
        (entry) => DiffMove(
          from: (entry as List<dynamic>)[0] as int,
          to: entry[1] as int,
        ),
      ),
    );

    return Diff(
      insertions: insertions,
      deletions: deletions,
      updates: updates,
      moves: moves,
    );
  }

  @override
  List<Object?> get props => [insertions, deletions, updates, moves];
}

@external

/// Represents a move of an item [from] one index [to] another.
final class DiffMove with EquatableMixin {
  /// The index in the _old_ array from which the item was moved.
  final int from;

  /// The index in the _new_ array to which the item was moved.
  final int to;

  DiffMove({
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [from, to];
}
