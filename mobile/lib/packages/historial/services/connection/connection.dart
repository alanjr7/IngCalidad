// Selector de conexión drift según plataforma.
// - Móvil/desktop (dart:io) → NativeDatabase (SQLite nativo).
// - Web (js_interop)        → WasmDatabase (SQLite compilado a WebAssembly).
export 'unsupported.dart'
    if (dart.library.io) 'native.dart'
    if (dart.library.js_interop) 'web.dart';
