# Escaneo de secretos en el historial completo

> Fecha: 2026-11-02. Criterio: "sin credenciales en el repositorio ni en el historial". Complementa el job `secrets` del CI (`.github/workflows/ci.yml`) y [`cadena-suministro.md`](./cadena-suministro.md). Los hallazgos se describen sin reproducir ningún valor.

## Método

| Elemento | Detalle |
|----------|---------|
| Herramienta | `gitleaks` 8.18.4 (el CI usa `gitleaks:latest` por Docker), reglas por defecto, salida con `--redact` |
| Alcance | 55 commits de todas las ramas locales (`main`, `feat/s11-seguridad`, `s9/*`, `s10/*`), cada uno escaneado por separado |
| Sin allowlist | El escaneo se hizo en un clon desechable sin `.gitleaksignore`, para ver todos los hallazgos reales y compararlos después con la allowlist |
| Binarios | Los 4 `.docx` del historial se descomprimieron y su texto se escaneó aparte |

## Resultado

**5 hallazgos, todos ya documentados en `.gitleaksignore` con su motivo. 0 hallazgos nuevos.**

| Commit | Archivo:línea | Regla | Qué es | Estado |
|--------|---------------|-------|--------|--------|
| `aa16382` | `backend/README.md:5` | `generic-api-key` | Badge de CircleCI de la plantilla `nest new`, con un token de ejemplo ficticio que apunta al repositorio oficial de NestJS | En allowlist; la línea ya se eliminó |
| `beb105c` | `docs/adr/0004-despliegue-render-docker.md:69` | `generic-api-key` | El ADR citaba el valor del hallazgo anterior al explicarlo | En allowlist; el texto ya se corrigió |
| `166ce9e` | `docs/ia.md:361` | `generic-api-key` | Mismo caso: `ia.md` citaba el token de ejemplo al narrarlo | En allowlist; ya reescrito |
| `0d7da07` | `sonar-project.properties:2` | `generic-api-key` | `projectKey` de SonarCloud: identificador público, no un secreto | En allowlist |
| `0d7da07` | `docs/ia.md:402` | `generic-api-key` | Cita de ese mismo identificador público | En allowlist |

Ninguno es una credencial activa. Los 5 son falsos positivos explicados.

Los documentos `.docx` (4 versiones en el historial): 0 hallazgos.

## Límites de esta verificación

1. **4 commits no se pudieron leer completos con gitleaks:** `afae3be`, `c5ae26f`, `b28e068` y `4806374`. Contienen archivos temporales de Word (`docs/~$blaModulos_ElMapitaUTB.docx`, `docs/~$rteVertical_ElMapitaUTB.docx`) y `.docx` que gitleaks no sabe leer, así que abortó esos commits. Los `.docx` se escanearon por texto aparte; el resto de archivos de esos commits quedó cubierto solo por el escaneo conjunto del paso anterior (sin errores en los demás 51 commits).
2. **Las ramas `dependabot/*` del remoto (16 commits de actualizaciones de dependencias) no se escanearon.** El job `secrets` del CI sí recorre el historial con `fetch-depth: 0`.
3. **Higiene del historial:** los archivos `~$*.docx` se subieron por error. Ya no están en el árbol actual; solo existen en commits antiguos. Contienen el nombre del usuario de Word que los creó. Reescribir el historial para quitarlos no se recomienda (rompe los hashes citados en ADR y evidencias).
4. **Esto no certifica ausencia absoluta:** gitleaks detecta patrones conocidos. Una credencial con formato atípico podría pasar. El control continuo es el job `secrets` en cada push.

## Reproducir

```bash
git clone --no-hardlinks --no-checkout . /ruta/temporal/clon && cd /ruta/temporal/clon
git checkout main && rm -f .gitleaksignore          # ver todos los hallazgos sin allowlist
for c in $(git rev-list --all); do
  gitleaks detect --source . --redact --log-opts="-1 $c" --report-format json --report-path salida.json
done
```
