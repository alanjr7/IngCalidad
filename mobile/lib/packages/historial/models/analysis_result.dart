import '../../../core/constants/risk_level.dart';

class AnalysisResult {
  final String? id;
  final String type;       // 'text' | 'image'
  final RiskLevel riskLevel;
  final double riskScore;
  final List<String> patternsFound;
  final String? contentPreview;
  final int? processingMs;
  final DateTime createdAt;

  const AnalysisResult({
    this.id,
    required this.type,
    required this.riskLevel,
    required this.riskScore,
    required this.patternsFound,
    this.contentPreview,
    this.processingMs,
    required this.createdAt,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'] as String?,
        type: json['analysis_type'] as String,
        riskLevel: RiskLevel.fromString(json['risk_level'] as String),
        riskScore: (json['risk_score'] as num).toDouble(),
        patternsFound: List<String>.from(json['patterns_found'] as List),
        processingMs: json['processing_ms'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
