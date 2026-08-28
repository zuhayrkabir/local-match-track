import "dart:ffi";

/// Some APIs require non-null pointers, though the actual value is meaningless
final dummyNonNullPointer = Pointer<Void>.fromAddress(0xBAD0);
