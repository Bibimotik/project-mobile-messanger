import 'dart:ffi';
import 'dart:io';

DynamicLibrary? loadNativeLib() {
  if (Platform.isAndroid) {
    // На Android мы используем JNI (через Kotlin), FFI не нужен
    return null;
  } else if (Platform.isWindows) {
    return DynamicLibrary.open("assets/native/hash.dll");
  } else if (Platform.isLinux) {
    return DynamicLibrary.open("assets/native/libhash.so");
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open("assets/native/libhash.dylib");
  } else {
    throw UnsupportedError("Unsupported platform: ${Platform.operatingSystem}");
  }
}
