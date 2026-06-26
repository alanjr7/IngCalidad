import 'package:flutter_test/flutter_test.dart';
import 'package:scam_detection/packages/analisis/models/analysis_request.dart';

void main() {
  test('TextAnalysisRequest.toJson serializa el texto', () {
    const req = TextAnalysisRequest('ingrese su contraseña');
    expect(req.toJson(), {'text': 'ingrese su contraseña'});
  });

  test('conserva el texto tal cual (incluido vacío)', () {
    expect(const TextAnalysisRequest('').toJson(), {'text': ''});
  });
}
