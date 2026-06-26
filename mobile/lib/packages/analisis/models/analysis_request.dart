class TextAnalysisRequest {
  final String text;
  const TextAnalysisRequest(this.text);
  Map<String, dynamic> toJson() => {'text': text};
}
