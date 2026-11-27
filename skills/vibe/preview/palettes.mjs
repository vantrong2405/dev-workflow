// Radix Colors light/dark scale values from dbdb85470547c7d34b9001f48fddb08ded335979.
const shared = {
  'on-accent': '#ffffff',
  success: '#193b2d',         // green 12
  'success-soft': '#e6f6eb', // green 3
  warning: '#4f3422',         // amber 12
  'warning-soft': '#fff7c2', // amber 3
  error: '#641723',          // red 12
  'error-soft': '#feebec',   // red 3
  'chart-secondary': '#5a7ca6',
};

export const palettes = {
  orange: {
    ...shared,
    panel: '#fefdfc',
    canvas: '#fcf9f6',
    ink: '#21201c',
    muted: '#63635e',
    rule: '#e2e1de',
    rail: '#f6eee7',
    'rail-text': '#3e332e',
    'rail-active': '#ffefd6',
    'rail-indicator': '#cc4e00',
    accent: '#cc4e00',
    'accent-ink': '#582d1d',
    'accent-soft': '#ffefd6',
  },
  blue: {
    ...shared,
    panel: '#fbfdff',
    canvas: '#f4faff',
    ink: '#1c2024',
    muted: '#60646c',
    rule: '#acd8fc',
    rail: '#111927',
    'rail-text': '#c2e6ff',
    'rail-active': '#003362',
    'rail-indicator': '#70b8ff',
    accent: '#0d74ce',
    'accent-ink': '#113264',
    'accent-soft': '#e6f4fe',
  },
  slate: {
    ...shared,
    panel: '#fbfdfc',
    canvas: '#eef1f0',
    ink: '#1a211e',
    muted: '#5f6563',
    rule: '#d7dad9',
    rail: '#272a29',
    'rail-text': '#eceeed',
    'rail-active': '#373b39',
    'rail-indicator': '#adf0d4',
    accent: '#1b5745',
    'accent-ink': '#1d3b31',
    'accent-soft': '#e6f7ed',
  },
  // Tweakcn presets converted to sRGB. Deeper label colors preserve contrast on tinted surfaces.
  tangerine: {
    ...shared,
    panel: '#ffffff',
    canvas: '#e8ebed',
    ink: '#333333',
    muted: '#4b5563',
    rule: '#dcdfe2',
    rail: '#dddfe2',
    'rail-text': '#333333',
    'rail-active': '#d6e4f0',
    'rail-indicator': '#1e3a8a',
    accent: '#e05d38',
    'on-accent': '#12110f',
    'accent-ink': '#1e3a8a',
    'accent-soft': '#d6e4f0',
  },
  'ocean-breeze': {
    ...shared,
    panel: '#ffffff',
    canvas: '#f0f8ff',
    ink: '#374151',
    muted: '#4b5563',
    rule: '#e5e7eb',
    rail: '#e0f2fe',
    'rail-text': '#374151',
    'rail-active': '#d1fae5',
    'rail-indicator': '#047857',
    accent: '#22c55e',
    'on-accent': '#101211',
    'accent-ink': '#065f46',
    'accent-soft': '#d1fae5',
    'chart-secondary': '#047857',
  },
};

export function resolvePalette(theme, colorOverrides) {
  return { ...palettes[theme], ...colorOverrides };
}

const contrastPairs = [
  ['ink', 'canvas'],
  ['ink', 'panel'],
  ['muted', 'canvas'],
  ['muted', 'panel'],
  ['rail-text', 'rail'],
  ['rail-text', 'rail-active'],
  ['on-accent', 'accent'],
  ['accent-ink', 'canvas'],
  ['accent-ink', 'panel'],
  ['accent-ink', 'accent-soft'],
  ['success', 'success-soft'],
  ['success', 'panel'],
  ['warning', 'warning-soft'],
  ['warning', 'panel'],
  ['error', 'panel'],
  ['error', 'error-soft'],
];

function luminance(hex) {
  if (!/^#[0-9a-f]{6}$/i.test(hex)) return undefined;
  const channels = hex.slice(1).match(/../g).map(channel => {
    const srgb = Number.parseInt(channel, 16) / 255;
    return srgb <= 0.04045 ? srgb / 12.92 : ((srgb + 0.055) / 1.055) ** 2.4;
  });
  return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
}

export function contrastFailures(palette) {
  return contrastPairs.flatMap(([foreground, background]) => {
    const first = luminance(palette[foreground]);
    const second = luminance(palette[background]);
    if (first === undefined || second === undefined) return [];
    const ratio = (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05);
    if (ratio >= 4.5) return [];
    return [`${foreground} on ${background} has contrast ${ratio.toFixed(2)}:1. Use at least 4.5:1.`];
  });
}
