// ignore_for_file: ditto_missing_visibility
part of "native.dart";

final _differFinalizer = NativeFinalizer(
  bindings.addresses.dittoffi_differ_free.cast(),
);

CPPointer<CPDiffer> dittoFfiDifferNew() {
  final pointer = bindings.dittoffi_differ_new();
  final cpPointer = pointer.toCP<CPDiffer>();

  _differFinalizer.attach(cpPointer, pointer.cast());
  return cpPointer;
}

Uint8List dittoFfiDifferDiff(
  CPPointer<CPDiffer> differ,
  List<CPPointer<CPQueryResultItem>> items,
) {
  final differPtr = differ.asFfi();

  final itemPointers = items.map((item) => item.asFfi()).toList();
  final itemSlice = _queryResultItemsToSlice(itemPointers);

  final cborRaw = bindings.dittoffi_differ_diff(
    differPtr.inner.cast(),
    itemSlice.ref,
  );

  malloc
    ..free(itemSlice.ref.ptr)
    ..free(itemSlice);

  return bytesFromNative(cborRaw, free: true);
}

Pointer<slice_ref_dittoffi_query_result_item_ptr> _queryResultItemsToSlice(
  List<_FfiPtr<CPQueryResultItem>> itemPointers,
) {
  final ptr = malloc<Pointer<dittoffi_query_result_item_t>>(
    itemPointers.length,
  );
  for (var i = 0; i < itemPointers.length; i++) {
    ptr[i] = itemPointers[i].inner.cast();
  }

  final slice = malloc<slice_ref_dittoffi_query_result_item_ptr>();
  slice.ref.ptr = ptr;
  slice.ref.len = itemPointers.length;
  return slice;
}
