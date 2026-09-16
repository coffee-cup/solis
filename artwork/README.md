# Solis icon reconstruction

`solis-icon.svg` recreates the published icon with two linear gradients, a path containing 18 cubic Bézier segments, and a Gaussian shadow. It contains no embedded bitmap or external resources.

`reference.png` contains the published artwork from Apple's image server for [Solis, app ID 1129119591](https://apps.apple.com/us/app/solis/id1129119591). The original sky gradient colors also appear in the [Solis website's background SVG](https://github.com/coffee-cup/solis-website/blob/321c7c9d51840f39af551cb590f375c4c08258f8/public/background.svg).

## Files

- `solis-icon.svg`: editable vector artwork.
- `reference.png`: published artwork used for comparison.
- `solis-icon.png`: native 1024 × 1024 SVG render.
- `comparison.png`: reference, recreation, and amplified difference overview.
- `difference-16x.png`: full-resolution absolute RGB difference multiplied by 16.
- `comparison.json`: exact metrics, source hashes, and renderer versions.
- `render-icon.cjs`: regenerates the app icon, comparisons, and metrics.

The app's 1024 × 1024 App Store icon uses the SVG render. Regenerating the artwork also updates `Icon-1024.png` in the app's asset catalog.

## Pixel comparison

The comparison uses all 1,048,576 pixels at matching coordinates in 8-bit sRGB. It measures the full-resolution images without resizing, alignment, or smoothing. A pixel is within a threshold only when all three RGB channels satisfy it. The overview scales the images down for viewing.

With sharp 0.35.4 and librsvg 2.62.91:

- Mean absolute channel error: 0.2444 out of 255.
- Root mean square channel error: 0.5233 out of 255.
- Exact RGB matches: 48.76% of pixels.
- Within 1 level on every channel: 99.28% of pixels.
- Within 2 levels on every channel: 99.87% of pixels.
- Largest single-channel difference: 19, at the curve boundary.

The reconstruction is not pixel-identical. The amplified difference exposes small gradient, shadow, and antialiasing differences. Other SVG renderers may produce slightly different pixels.

## Regenerate

Use Node.js with `sharp` available in its module path:

```sh
NODE_PATH=/path/to/node_modules node artwork/render-icon.cjs
```

`sharp` is an artwork tool only; it is not a dependency of the iOS app.
