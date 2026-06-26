# ============================================================================
# Reglas R8/ProGuard para el build release.
#
# Estas clases son referenciadas por los plugins pero NO se incluyen en el APK
# porque la app no usa esas variantes opcionales. R8 en modo "full" aborta el
# build si las encuentra ausentes, así que las silenciamos con -dontwarn.
# (Generadas originalmente por R8 en build/app/outputs/mapping/release/missing_rules.txt)
# ============================================================================

# --- ML Kit Text Recognition: reconocedores de idiomas no usados ---
# La app solo usa el reconocedor latino; estos son scripts opcionales.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# --- TensorFlow Lite GPU delegate (no incluido / inferencia por CPU) ---
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# --- Mantener clases de TFLite que se cargan por reflexión/JNI ---
# Evita que R8 las elimine u ofusque y rompa la inferencia en runtime.
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
