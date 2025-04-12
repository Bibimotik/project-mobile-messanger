import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Загрузка динамической библиотеки
final DynamicLibrary nativeLib = DynamicLibrary.open('hash.dll');

// Определение сигнатуры C-функции
typedef CalculateHashNative = Uint32 Function(Pointer<Utf8>);
typedef CalculateHash = int Function(Pointer<Utf8>);

// Получение функции из библиотеки
final CalculateHash calculateHash = nativeLib
    .lookup<NativeFunction<CalculateHashNative>>('calculate_hash')
    .asFunction();

// Обертка для удобного использования из Dart
int hashString(String input) {
  final pointer = input.toNativeUtf8();
  try {
    return calculateHash(pointer);
  } finally {
    malloc.free(pointer);
  }
} 