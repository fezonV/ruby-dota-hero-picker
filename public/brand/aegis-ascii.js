/* Each cell is one crisp character. Pointer movement rewrites cells along its
   path; it never displaces, blurs, brightens, or tilts the Aegis. */
export function createAegisAscii(canvas, options = {}) {
  const ctx = canvas.getContext('2d');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const pointerSurface = options.pointerSurface || canvas;
  const bands = ['.:,;`', '-=+x*', '#%&@'];
  const replacements = ['.:,;01', '-=+x*/<>01', '#%&@MW{}'];
  const points = [];
  const source = new Image();
  let width = 0, height = 0, columns = 0, rows = 0, cell = 0, left = 0, top = 0;
  let raf = 0, lastFrame = 0, ambientTime = 0, lastAmbientFrame = 0;
  let running = !reduced.matches, visible = true, destroyed = false;
  let previousPointer = null;

  function hash(value) {
    let result = value | 0;
    result = Math.imul(result ^ (result >>> 16), 0x45d9f3b);
    result = Math.imul(result ^ (result >>> 16), 0x45d9f3b);
    return ((result ^ (result >>> 16)) >>> 0) / 4294967296;
  }
  function build() {
    points.length = 0;
    if (!source.complete || !source.naturalWidth || !width || !height) return;
    const fit = Math.min(width * .82 / source.naturalWidth, height * .83 / source.naturalHeight);
    columns = Math.max(12, Math.min(source.naturalWidth, Math.floor(source.naturalWidth * fit / 8)));
    rows = Math.round(columns * source.naturalHeight / source.naturalWidth);
    cell = Math.min(width * .82 / columns, height * .83 / rows);
    left = (width - columns * cell) / 2; top = (height - rows * cell) / 2;
    const sample = document.createElement('canvas'); sample.width = columns; sample.height = rows;
    const sampleCtx = sample.getContext('2d', { willReadFrequently: true });
    sampleCtx.drawImage(source, 0, 0, columns, rows);
    const pixels = sampleCtx.getImageData(0, 0, columns, rows).data;
    for (let y = 0; y < rows; y++) for (let x = 0; x < columns; x++) {
      const offset = (y * columns + x) * 4;
      const light = (pixels[offset] * .2126 + pixels[offset + 1] * .7152 + pixels[offset + 2] * .0722) / 255;
      if (light < .09) continue;
      const tone = Math.pow(Math.max(0, (light - .09) / .91), .5);
      const band = Math.min(2, Math.floor(tone * 3));
      const seed = y * columns + x + 101;
      points.push({ x, y, seed, band, alpha: Math.min(1, tone * 1.25),
        glyph: bands[band][Math.floor(hash(seed) * bands[band].length)], until: 0, revision: 0 });
    }
    canvas.dataset.glyphColumns = String(columns);
    canvas.dataset.glyphRows = String(rows);
    previousPointer = null;
  }
  function draw(now) {
    if (destroyed) return;
    if (lastFrame && now - lastFrame < 32) { raf = requestAnimationFrame(draw); return; }
    lastFrame = now;
    if (running && !document.hidden && visible) ambientTime += lastAmbientFrame ? Math.min(now - lastAmbientFrame, 80) : 0;
    lastAmbientFrame = now;
    ctx.clearRect(0, 0, width, height);
    ctx.font = `400 ${Math.min(14, cell * .96)}px ui-monospace, SFMono-Regular, Menlo, monospace`;
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillStyle = options.color || getComputedStyle(canvas).color;
    let active = 0;
    const ambientStep = Math.floor(ambientTime / 320);
    for (const point of points) {
      let glyph = point.glyph;
      const touched = !reduced.matches && point.until > now;
      if (touched) {
        active++;
        const sequence = replacements[point.band];
        glyph = sequence[Math.floor(hash(point.seed + point.revision * 997 + Math.floor(now / 75) * 31) * sequence.length)];
      } else if (!reduced.matches && hash(point.seed + ambientStep * 431) < .018) {
        const sequence = bands[point.band];
        glyph = sequence[Math.floor(hash(point.seed + ambientStep * 53) * sequence.length)];
      }
      // Coordinates and opacity are identical in resting and interactive states.
      ctx.globalAlpha = point.alpha;
      ctx.fillText(glyph, left + (point.x + .5) * cell, top + (point.y + .5) * cell);
    }
    ctx.globalAlpha = 1;
    canvas.dataset.activeGlyphs = String(active);
    if (visible && !document.hidden && (running || active)) raf = requestAnimationFrame(draw);
  }
  function redraw() { cancelAnimationFrame(raf); lastFrame = 0; lastAmbientFrame = 0; draw(performance.now()); }
  function resize() {
    const rect = canvas.getBoundingClientRect(); width = rect.width; height = rect.height;
    const dpr = Math.min(devicePixelRatio, 2);
    canvas.width = Math.round(width * dpr); canvas.height = Math.round(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0); build(); redraw();
  }
  function stamp(x, y, now) {
    // An irregular short text trail, not a circular brush or a luminous halo.
    for (const point of points) {
      const dx = Math.abs(point.x - x), dy = Math.abs(point.y - y);
      if (dx > 4 || dy > 2) continue;
      if (dx + dy > 1.5 && hash(point.seed + Math.floor(x) * 19 + Math.floor(y) * 7) > .45) continue;
      point.until = now + 360 + hash(point.seed) * 300;
      point.revision++;
    }
  }
  function move(event) {
    if (reduced.matches || event.pointerType === 'touch' || !cell) return;
    const rect = canvas.getBoundingClientRect();
    const position = { x: (event.clientX - rect.left - left) / cell - .5, y: (event.clientY - rect.top - top) / cell - .5 };
    const now = performance.now();
    if (previousPointer) {
      const steps = Math.min(80, Math.max(1, Math.ceil(Math.hypot(position.x - previousPointer.x, position.y - previousPointer.y))));
      for (let step = 1; step <= steps; step++) stamp(previousPointer.x + (position.x - previousPointer.x) * step / steps, previousPointer.y + (position.y - previousPointer.y) * step / steps, now);
    } else stamp(position.x, position.y, now);
    previousPointer = position;
    if (!running) redraw();
  }
  function leave() { previousPointer = null; }
  function motion() {
    running = !reduced.matches;
    if (reduced.matches) { points.forEach(point => { point.until = 0; }); previousPointer = null; }
    redraw();
  }
  function visibility() { previousPointer = null; redraw(); }
  source.onload = () => { if (!destroyed) { build(); redraw(); } };
  source.src = new URL('aegis-valve.png', import.meta.url).href;
  const ro = new ResizeObserver(resize); ro.observe(canvas);
  const io = new IntersectionObserver(entries => { visible = entries[0].isIntersecting; redraw(); }); io.observe(canvas);
  pointerSurface.addEventListener('pointermove', move); pointerSurface.addEventListener('pointerleave', leave);
  reduced.addEventListener('change', motion); document.addEventListener('visibilitychange', visibility);
  return {
    setRunning(value) { running = value && !reduced.matches; redraw(); },
    destroy() {
      destroyed = true; cancelAnimationFrame(raf); ro.disconnect(); io.disconnect();
      pointerSurface.removeEventListener('pointermove', move); pointerSurface.removeEventListener('pointerleave', leave);
      reduced.removeEventListener('change', motion); document.removeEventListener('visibilitychange', visibility);
    }
  };
}
