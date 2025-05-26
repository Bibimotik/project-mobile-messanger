import 'dart:ffi';
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeLib = DynamicLibrary.open('hash.dll');

typedef CalculateHashNative = Uint32 Function(Pointer<Utf8>);
typedef CalculateHash = int Function(Pointer<Utf8>);

final CalculateHash calculateHash = nativeLib
    .lookup<NativeFunction<CalculateHashNative>>('calculate_hash')
    .asFunction();

int hashString(String input) {
  final pointer = input.toNativeUtf8();
  try {
    return calculateHash(pointer);
  } finally {
    malloc.free(pointer);
  }
} 