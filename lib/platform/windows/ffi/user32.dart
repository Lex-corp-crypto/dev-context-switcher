import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _EnumWindowsProc = Int32 Function(
  IntPtr hwnd, IntPtr lParam,
);

final user32 = DynamicLibrary.open('user32.dll');

final enumWindows = user32.lookupFunction<
    Int32 Function(Pointer<NativeFunction<_EnumWindowsProc>>, IntPtr),
    int Function(Pointer<NativeFunction<_EnumWindowsProc>>, int)>('EnumWindows');

final getWindowTextW = user32.lookupFunction<
    Int32 Function(IntPtr, Pointer<Utf16>, Int32),
    int Function(int, Pointer<Utf16>, int)>('GetWindowTextW');

final getWindowRect = user32.lookupFunction<
    Int32 Function(IntPtr, Pointer<RECT>),
    int Function(int, Pointer<RECT>)>('GetWindowRect');

final setWindowPos = user32.lookupFunction<
    Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32),
    int Function(int, int, int, int, int, int, int)>('SetWindowPos');

final setForegroundWindow = user32.lookupFunction<
    Int32 Function(IntPtr),
    int Function(int)>('SetForegroundWindow');

final isWindowVisible = user32.lookupFunction<
    Int32 Function(IntPtr),
    int Function(int)>('IsWindowVisible');

final postMessageW = user32.lookupFunction<
    Int32 Function(IntPtr, Uint32, IntPtr, IntPtr),
    int Function(int, int, int, int)>('PostMessageW');

final class RECT extends Struct {
  @Int32() external int left;
  @Int32() external int top;
  @Int32() external int right;
  @Int32() external int bottom;
}

const wmClose = 0x0010;
