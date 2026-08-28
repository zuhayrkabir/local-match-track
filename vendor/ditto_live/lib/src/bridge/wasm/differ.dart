// ignore_for_file: ditto_missing_visibility

part of "wasm.dart";

CPPointer<CPDiffer> dittoFfiDifferNew() => _WasmPointer(
      _dittoCore.dittoffiDifferNew(),
    );

Uint8List dittoFfiDifferDiff(
  CPPointer<CPDiffer> differ,
  List<CPPointer<CPQueryResultItem>> items,
) {
  final jsItems = items.map((item) => item.asWasm()).toList().toJS;
  return _dittoCore.dittoffiDifferDiff(differ.asWasm(), jsItems).toDart;
}
