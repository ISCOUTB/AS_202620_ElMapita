// EC-01: mide la secuencia de red de la carga inicial (edificio + modelo de piso)
// contra la API desplegada. NO incluye descarga del .glb ni render en dispositivo.
// Uso: node backend/scripts/bench-ec01.mjs [baseUrl] [n=30]
const base = process.argv[2] ?? 'https://elmapita-utb-api.onrender.com';
const n = Number(process.argv[3] ?? 30);

const get = async (path) => {
  const t0 = performance.now();
  const res = await fetch(base + path);
  const body = await res.json().catch(() => null);
  return { status: res.status, body, ms: performance.now() - t0 };
};

const list = await get('/api/v1/map/buildings');
const building = list.body?.buildings?.[0];
if (!building) throw new Error('Sin edificios en ' + base);
const floorId = building.pisos[0];

const samples = [];
const statuses = new Set();
for (let i = 0; i < n; i++) {
  const t0 = performance.now();
  const b = await get(`/api/v1/map/buildings/${building.id}`);
  const f = await get(`/api/v1/map/floors/${floorId}/model`);
  samples.push(performance.now() - t0);
  statuses.add(`${b.status}/${f.status}`);
}
samples.sort((a, b) => a - b);
const p = (q) => samples[Math.min(n - 1, Math.ceil(q * n) - 1)];
console.log(
  JSON.stringify(
    {
      fecha: new Date().toISOString(),
      base,
      n,
      statusBuildingFloor: [...statuses],
      minMs: Math.round(samples[0]),
      p50Ms: Math.round(p(0.5)),
      p95Ms: Math.round(p(0.95)),
      maxMs: Math.round(samples[n - 1]),
      umbralP95Ms: 5000,
      exitosas: [...statuses].every((s) => s === "200/200"),
      cumple: [...statuses].every((s) => s === "200/200") && p(0.95) < 5000,
    },
    null,
    2,
  ),
);
