import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'loadNativeLib.dart';

typedef CalculateHashNative = Uint32 Function(Pointer<Utf8>);
typedef CalculateHash = int Function(Pointer<Utf8>);

final DynamicLibrary? _nativeLib = loadNativeLib();
final CalculateHash? _ffiCalculateHash = _nativeLib != null
    ? _nativeLib!
    .lookup<NativeFunction<CalculateHashNative>>('calculate_hash')
    .asFunction()
    : null;

Future<int> calculateHashDart(String input) async {
  if (Platform.isAndroid) {
    const platform = MethodChannel('com.example.mobile_messanger/hash');
    final result = await platform.invokeMethod<int>('calculateHash', input);
    return result ?? 0;
  } else {
    final ptr = input.toNativeUtf8();
    final result = _ffiCalculateHash!(ptr);
    calloc.free(ptr);
    return result;
  }
}
