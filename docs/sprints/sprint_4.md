# Sprint 4 — Dashboard, Reportes, Educación y Despliegue Final

**Duración:** ~1 semana  
**Estado:** ✅ Completado

## Objetivos

- [x] Backend: generador de PDF con ReportLab
- [x] Backend: generador de Excel con openpyxl
- [x] Backend: endpoint GET /education/dashboard (stats por usuario)
- [x] Backend: endpoint GET /education/export/pdf
- [x] Backend: endpoint GET /education/export/excel
- [x] Backend: endpoint GET /education/tips
- [x] Flutter: DashboardView con gráfico de torta (fl_chart)
- [x] Flutter: TipsView con consejos de seguridad por categoría
- [x] Flutter: integración de exportación PDF/Excel desde el dashboard
- [x] Router final con todas las vistas conectadas
- [x] Tests unitarios de ImageAnalyzer (tiempo < 5s)

## Criterios de Aceptación Sprint 4

| Criterio | Estado |
|----------|--------|
| Dashboard muestra total + distribución por nivel | ✅ |
| Exportación PDF responde con Content-Type application/pdf | ✅ |
| Exportación Excel responde con .xlsx correcto | ✅ |
| Tips de seguridad se filtran por categoría | ✅ |
| Análisis de imagen procesa en < 5s | ✅ |

## Arquitectura Final Desplegada

```
Android App (Flutter)
       │ HTTPS
       ▼
  DigitalOcean Droplet
  ┌─────────────────────────────────┐
  │  Nginx (reverse proxy + SSL)    │
  │  FastAPI (uvicorn, port 8000)   │
  │  ├─ /api/v1/auth                │
  │  ├─ /api/v1/analysis            │
  │  ├─ /api/v1/reports             │
  │  └─ /api/v1/education           │
  └──────────────┬──────────────────┘
                 │
         PostgreSQL 15
         (Docker volume)
```

## Checklist de Despliegue DigitalOcean

- [ ] Crear Droplet Ubuntu 22.04 (2 vCPU / 2GB RAM mínimo)
- [ ] Instalar Docker + Docker Compose
- [ ] Clonar repo y configurar `.env` de producción
- [ ] `docker-compose up -d` (db + api)
- [ ] Instalar Nginx y configurar reverse proxy
- [ ] Obtener certificado SSL (Let's Encrypt / Certbot)
- [ ] Configurar dominio en DNS
- [ ] Actualizar `API_BASE_URL` en Flutter y rebuild APK
