"""Evaluación de la CALIDAD del detector de estafas (métrica de producto ML).

A diferencia de las pruebas funcionales ("¿el endpoint responde?"), esto mide la
*calidad de la predicción* del clasificador sobre un dataset etiquetado:
matriz de confusión, exactitud, precisión, recall y F1. Es el equivalente, para
un sistema de IA, de la "Adecuación funcional" de ISO/IEC 25010.

Decisión binaria: se considera 'scam' (positivo) si el score de riesgo alcanza el
umbral de nivel medio (`confidence_threshold_low`, por defecto 0.4); de lo
contrario 'safe'.

Uso como CLI (genera reporte en consola y JSON):
    python -m tests.quality.detector_eval
"""
from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path

from app.core.config import get_settings
from app.services.ml.text_analyzer import TextAnalyzer

DATASET_PATH = Path(__file__).parent / "scam_dataset.json"
POSITIVE = "scam"
NEGATIVE = "safe"


@dataclass
class Metrics:
    total: int
    tp: int
    fp: int
    tn: int
    fn: int
    accuracy: float
    precision: float
    recall: float
    f1: float
    specificity: float


def load_samples(path: Path = DATASET_PATH) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return data["samples"]


def predict(analyzer: TextAnalyzer, text: str, threshold: float) -> str:
    """Etiqueta binaria a partir del score continuo del analizador."""
    result = analyzer.analyze(text)
    return POSITIVE if result.risk_score >= threshold else NEGATIVE


def evaluate(samples: list[dict] | None = None) -> tuple[Metrics, list[dict]]:
    """Corre el detector sobre el dataset y devuelve (métricas, predicciones)."""
    samples = samples if samples is not None else load_samples()
    threshold = get_settings().confidence_threshold_low
    analyzer = TextAnalyzer()

    tp = fp = tn = fn = 0
    rows: list[dict] = []
    for s in samples:
        predicted = predict(analyzer, s["text"], threshold)
        actual = s["label"]
        correct = predicted == actual
        if actual == POSITIVE and predicted == POSITIVE:
            tp += 1
        elif actual == NEGATIVE and predicted == POSITIVE:
            fp += 1
        elif actual == NEGATIVE and predicted == NEGATIVE:
            tn += 1
        else:
            fn += 1
        rows.append({"id": s["id"], "actual": actual, "predicted": predicted, "correct": correct})

    total = len(samples)
    accuracy = (tp + tn) / total if total else 0.0
    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) else 0.0
    specificity = tn / (tn + fp) if (tn + fp) else 0.0

    return (
        Metrics(total, tp, fp, tn, fn, round(accuracy, 4), round(precision, 4),
                round(recall, 4), round(f1, 4), round(specificity, 4)),
        rows,
    )


def _render(metrics: Metrics, rows: list[dict]) -> str:
    lines = [
        "=" * 56,
        "  CALIDAD DEL DETECTOR DE ESTAFAS — Reporte de evaluación",
        "=" * 56,
        f"  Muestras evaluadas: {metrics.total}",
        "",
        "  Matriz de confusión",
        "                    Predicho",
        "                 scam     safe",
        f"  Real  scam  |  {metrics.tp:>4}     {metrics.fn:>4}   (TP / FN)",
        f"        safe  |  {metrics.fp:>4}     {metrics.tn:>4}   (FP / TN)",
        "",
        f"  Exactitud (accuracy) : {metrics.accuracy:.1%}",
        f"  Precisión (precision): {metrics.precision:.1%}",
        f"  Sensibilidad (recall): {metrics.recall:.1%}",
        f"  Especificidad        : {metrics.specificity:.1%}",
        f"  F1-score             : {metrics.f1:.3f}",
        "",
    ]
    errores = [r for r in rows if not r["correct"]]
    if errores:
        lines.append("  Errores de clasificación:")
        for r in errores:
            tipo = "Falso positivo" if r["actual"] == NEGATIVE else "Falso negativo"
            lines.append(f"    - {r['id']}: {tipo} (real={r['actual']}, predicho={r['predicted']})")
    else:
        lines.append("  Sin errores de clasificación.")
    lines.append("=" * 56)
    return "\n".join(lines)


def main() -> None:
    metrics, rows = evaluate()
    print(_render(metrics, rows))
    out = Path(__file__).parent / "detector_metrics.json"
    out.write_text(
        json.dumps({"metrics": asdict(metrics), "predictions": rows}, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"\nReporte JSON escrito en: {out}")


if __name__ == "__main__":
    main()
