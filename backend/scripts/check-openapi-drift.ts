import { readFileSync } from 'fs';
import { resolve } from 'path';
import { parse } from 'yaml';

/**
 * Compara el conjunto de operaciones (MÉTODO + ruta) del contrato versionado
 * (docs/api/openapi.v1.yaml) contra el documento generado en tiempo de
 * ejecución desde los decoradores de NestJS (backend/.openapi-generated.json,
 * producido por generate-openapi.ts).
 *
 * No falla el build (ver ci.yml: continue-on-error mientras RSK-04 esté
 * abierto) pero deja constancia exacta de la deriva entre lo documentado
 * y lo que el servidor realmente expone.
 */

interface OpenApiDoc {
  paths: Record<string, Record<string, unknown>>;
}

const HTTP_METHODS = ['get', 'post', 'put', 'patch', 'delete', 'options', 'head'];

function extractOperations(doc: OpenApiDoc): Set<string> {
  const ops = new Set<string>();
  for (const [path, methods] of Object.entries(doc.paths ?? {})) {
    for (const method of Object.keys(methods)) {
      if (HTTP_METHODS.includes(method.toLowerCase())) {
        ops.add(`${method.toUpperCase()} ${path}`);
      }
    }
  }
  return ops;
}

function main() {
  const contractPath = resolve(__dirname, '../../docs/api/openapi.v1.yaml');
  const generatedPath = resolve(__dirname, '../.openapi-generated.json');

  const contractDoc = parse(readFileSync(contractPath, 'utf-8')) as OpenApiDoc;
  const generatedDoc = JSON.parse(readFileSync(generatedPath, 'utf-8')) as OpenApiDoc;

  const contractOps = extractOperations(contractDoc);
  const generatedOps = extractOperations(generatedDoc);

  const onlyInContract = [...contractOps].filter((op) => !generatedOps.has(op)).sort();
  const onlyInCode = [...generatedOps].filter((op) => !contractOps.has(op)).sort();
  const matching = [...contractOps].filter((op) => generatedOps.has(op)).sort();

  console.log(`Operaciones coincidentes: ${matching.length}`);
  matching.forEach((op) => console.log(`  = ${op}`));

  console.log(`\nEn el contrato pero ausentes del código real (404 esperado): ${onlyInContract.length}`);
  onlyInContract.forEach((op) => console.log(`  - ${op}`));

  console.log(`\nEn el código real pero no documentadas en el contrato: ${onlyInCode.length}`);
  onlyInCode.forEach((op) => console.log(`  + ${op}`));

  if (onlyInContract.length > 0 || onlyInCode.length > 0) {
    console.log('\nDERIVA DETECTADA entre docs/api/openapi.v1.yaml y el backend real.');
    console.log('Ver docs/adr/0003-contrato-openapi-versionado.md y RSK-04 (arc42) para el estado de esta deuda.');
    process.exitCode = 1;
    return;
  }

  console.log('\nSin deriva: el contrato coincide exactamente con las rutas expuestas por NestJS.');
}

main();
