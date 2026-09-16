const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');

async function main() {
  const svgPath = path.join(__dirname, 'solis-icon.svg');
  const referencePath = path.join(__dirname, 'reference.png');
  const appIconPath = path.join(__dirname, '../SunriseSunset/Assets.xcassets/AppIcon.appiconset/Icon-1024.png');
  const [svg, referenceFile] = await Promise.all([fs.readFile(svgPath), fs.readFile(referencePath)]);
  const [reference, rendered] = await Promise.all([
    sharp(referenceFile).toColourspace('srgb').removeAlpha().raw().toBuffer({ resolveWithObject: true }),
    sharp(svg).toColourspace('srgb').removeAlpha().raw().toBuffer({ resolveWithObject: true }),
  ]);
  const { width, height, channels } = reference.info;
  if (
    width !== rendered.info.width || height !== rendered.info.height ||
    channels !== 3 || rendered.info.channels !== 3
  ) {
    throw new Error('Both images must have identical dimensions and three RGB channels.');
  }

  const difference = Buffer.alloc(reference.data.length);
  const histogram = new Array(256).fill(0);
  let absoluteError = 0;
  let squaredError = 0;
  for (let pixel = 0; pixel < width * height; pixel++) {
    let largest = 0;
    for (let channel = 0; channel < 3; channel++) {
      const i = pixel * 3 + channel;
      const error = Math.abs(reference.data[i] - rendered.data[i]);
      absoluteError += error;
      squaredError += error * error;
      largest = Math.max(largest, error);
      difference[i] = Math.min(255, error * 16);
    }
    histogram[largest]++;
  }
  const pixels = width * height;
  const within = threshold => histogram.slice(0, threshold + 1).reduce((a, b) => a + b, 0) / pixels * 100;
  const percentile = fraction => {
    let count = 0;
    for (let i = 0; i < histogram.length; i++) {
      count += histogram[i];
      if (count >= fraction * pixels) return i;
    }
  };
  const hash = buffer => crypto.createHash('sha256').update(buffer).digest('hex');
  const metrics = {
    width, height,
    comparison: 'Direct, unaligned 8-bit sRGB comparison at native resolution; no resizing or smoothing.',
    pixel_tolerance: 'A pixel passes only when every RGB channel is within the threshold.',
    reference_sha256: hash(referenceFile),
    svg_sha256: hash(svg),
    renderer: { sharp: sharp.versions.sharp, librsvg: sharp.versions.rsvg },
    mean_absolute_channel_error: absoluteError / reference.data.length,
    root_mean_square_channel_error: Math.sqrt(squaredError / reference.data.length),
    max_channel_error: histogram.findLastIndex(count => count > 0),
    exact_pixel_percent: within(0),
    pixels_within_1_percent: within(1),
    pixels_within_2_percent: within(2),
    pixels_within_5_percent: within(5),
    p95_max_channel_error: percentile(0.95),
    p99_max_channel_error: percentile(0.99),
  };
  const raw = { width, height, channels: 3 };
  await sharp(rendered.data, { raw }).png().toFile(path.join(__dirname, 'solis-icon.png'));
  await fs.copyFile(path.join(__dirname, 'solis-icon.png'), appIconPath);
  await sharp(difference, { raw }).png().toFile(path.join(__dirname, 'difference-16x.png'));
  await fs.writeFile(path.join(__dirname, 'comparison.json'), JSON.stringify(metrics, null, 2) + '\n');

  // The overview is scaled for viewing; metrics above always use all native pixels.
  const panels = await Promise.all([reference.data, rendered.data, difference].map(data =>
    sharp(data, { raw }).resize(384, 384).png().toBuffer()
  ));
  const labels = Buffer.from(`<svg width="1200" height="478" xmlns="http://www.w3.org/2000/svg">
    <rect width="1200" height="478" fill="#151619"/>
    <g fill="#f4f4f5" font-family="Helvetica, Arial, sans-serif" font-size="17">
      <text x="16" y="30">Reference</text>
      <text x="408" y="30">Recreated SVG</text>
      <text x="800" y="30">Absolute difference ×16</text>
    </g>
    <text x="16" y="459" fill="#b7b9c0" font-family="Helvetica, Arial, sans-serif" font-size="14">1024 × 1024 comparison · Mean channel error ${metrics.mean_absolute_channel_error.toFixed(3)} / 255 · ${metrics.pixels_within_2_percent.toFixed(2)}% of pixels within 2 levels on every channel</text>
  </svg>`);
  await sharp(labels).composite(panels.map((input, i) => ({ input, left: 16 + i * 392, top: 46 })))
    .png().toFile(path.join(__dirname, 'comparison.png'));
  console.log(JSON.stringify(metrics, null, 2));
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
