"""Compuerta de calidad del modelo de detección (métrica de producto ML).

Falla si la calidad del clasificador cae por debajo de las metas del Plan SQA.
Es la verificación de "Adecuación funcional" (ISO/IEC 25010) para un sistema de IA:
no basta con que el endpoint responda, la *predicción* debe ser correcta.

Metas (línea base medida: F1=0.943, recall=0.962, precisión=0.926):
  - F1-score    >= 0.85
  - Recall      >= 0.85  (minimizar estafas no detectadas — falsos negativos)
  - Precisión   >= 0.80  (controlar falsas alarmas)
"""
from tests.quality.detector_eval import evaluate

F1_MIN = 0.85
RECALL_MIN = 0.85
PRECISION_MIN = 0.80


def test_detector_meets_quality_targets():
    metrics, _ = evaluate()
    assert metrics.f1 >= F1_MIN, f"F1={metrics.f1} < meta {F1_MIN}"
    assert metrics.recall >= RECALL_MIN, f"recall={metrics.recall} < meta {RECALL_MIN}"
    assert metrics.precision >= PRECISION_MIN, f"precision={metrics.precision} < meta {PRECISION_MIN}"


def test_dataset_is_balanced_and_nontrivial():
    from tests.quality.detector_eval import NEGATIVE, POSITIVE, load_samples

    samples = load_samples()
    assert len(samples) >= 50, "dataset demasiado pequeño para ser representativo"
    labels = {POSITIVE, NEGATIVE}
    assert {s["label"] for s in samples} == labels, "etiquetas inesperadas"
    n_scam = sum(1 for s in samples if s["label"] == POSITIVE)
    n_safe = len(samples) - n_scam
    # Balance razonable: ninguna clase domina (evita métricas engañosas).
    assert 0.4 <= n_scam / len(samples) <= 0.6, f"dataset desbalanceado: {n_scam} scam / {n_safe} safe"


def test_recall_prioritized_over_precision():
    # En detección de estafas, dejar pasar una estafa (FN) es más costoso que una
    # falsa alarma (FP): el sistema debe priorizar el recall.
    metrics, _ = evaluate()
    assert metrics.fn <= metrics.fp + 2, "demasiados falsos negativos (estafas no detectadas)"
