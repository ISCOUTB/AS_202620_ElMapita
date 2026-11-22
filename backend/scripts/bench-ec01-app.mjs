// EC-01 (ruta real de la app): mide la carga inicial sin cache local, tal como la
// hace el cliente Flutter: capas (tabla mapa_capas) + descarga del .glb del campus,
// ambos directo de Supabase (solo lectura, clave publishable ya publica en el cliente).
// NO incluye render 3D en el dispositivo ni la red movil de un telefono de gama media.
// Uso: node backend/scripts/bench-ec01-app.mjs [n=30]
const SUPABASE = 'https://smgbmfbgxfjkspvtyvfb.supabase.co';
const KEY = 'sb_publishable_GLfxnLoXZyfzBrdc5f9gqQ_t8nOhhA1';
const n = Number(process.argv[2] ?? 30);

const samples = [];
const statuses = new Set();
let glbBytes = 0;
for (let i = 0; i < n; i++) {
  const t0 = performance.now();
  const layers = await fetch(`${SUPABASE}/rest/v1/mapa_capas?select=*`, {
    headers: { apikey: KEY },
  });
  await layers.arrayBuffer();
  const glb = await fetch(
    `${SUPABASE}/storage/v1/object/public/mapa-campus/utb_campus.glb`,
    { cache: 'no-store' },
  );
  glbBytes = (await glb.arrayBuffer()).byteLength;
  samples.push(performance.now() - t0);
  statuses.add(`${layers.status}/${glb.status}`);
}
samples.sort((a, b) => a - b);
const p = (q) => samples[Math.min(n - 1, Math.ceil(q * n) - 1)];
const ok = [...statuses].every((s) => s === '200/200');
console.log(
  JSON.stringify(
    {
      fecha: new Date().toISOString(),
      ruta: 'mapa_capas + utb_campus.glb (Supabase directo, sin cache)',
      n,
      glbBytes,
      status: [...statuses],
      minMs: Math.round(samples[0]),
      p50Ms: Math.round(p(0.5)),
      p95Ms: Math.round(p(0.95)),
      maxMs: Math.round(samples[n - 1]),
      umbralP95Ms: 5000,
      exitosas: ok,
      cumple: ok && p(0.95) < 5000,
    },
    null,
    2,
  ),
);
