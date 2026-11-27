import { z } from 'zod';
import { contrastFailures, palettes, resolvePalette } from './palettes.mjs';

const text = z.string().trim().min(1);
const tone = z.enum(['neutral', 'accent', 'success', 'warning']);
const metric = z.strictObject({ label: text, value: text, tone: tone.optional() });
const workspace = z.strictObject({
  mark: z.string().trim().min(1).max(4).optional(),
  navigation: z.array(z.strictObject({ label: text, current: z.boolean().optional() })).min(1),
});
const localizedActions = z.strictObject({ primary: text.optional(), secondary: text.optional() });
const frame = z.strictObject({
  app: text,
  title: text,
  description: text.optional(),
  actions: localizedActions.optional(),
});
const common = {
  id: z.string().regex(/^[a-z0-9][a-z0-9-]*$/),
  label: text,
  acceptance: z.array(z.string().regex(/^AC-\d+$/)).min(1),
  currentNavigation: text.optional(),
};
const listData = frame.extend({
  columns: z.array(text).min(1),
  rows: z.array(z.array(text)),
  filters: z.array(text).optional(),
  search: text.optional(),
  rowAction: text.optional(),
  emptyMessage: text.optional(),
  summary: z.array(metric).min(1).max(4).optional(),
  statusColumn: z.number().int().min(0).optional(),
  statusTones: z.record(text, tone).optional(),
}).superRefine(({ columns, rows, statusColumn, emptyMessage }, ctx) => {
  if (statusColumn !== undefined && statusColumn >= columns.length) {
    ctx.addIssue({ code: 'custom', path: ['statusColumn'], message: 'Choose a column in the table' });
  }
  if (rows.length === 0 && !emptyMessage) {
    ctx.addIssue({ code: 'custom', path: ['emptyMessage'], message: 'Supply localized empty-state text' });
  }
  rows.forEach((row, index) => {
    if (row.length !== columns.length) {
      ctx.addIssue({ code: 'custom', path: ['rows', index], message: 'Expected one cell per column' });
    }
  });
});
const detailData = frame.extend({
  fields: z.array(z.strictObject({ label: text, value: text })).min(1),
  status: text.optional(),
  statusTone: tone.optional(),
  dismissLabel: text.optional(),
});
const field = z.strictObject({
  label: text,
  kind: z.enum(['input', 'textarea', 'select']),
  value: z.string().optional(),
  options: z.array(text).min(1).optional(),
  error: text.optional(),
}).superRefine(({ kind, options, value }, ctx) => {
  if (kind === 'select' && (!options || (value !== undefined && !options.includes(value)))) {
    ctx.addIssue({ code: 'custom', path: ['options'], message: 'Supply choices including the selected value' });
  }
});
const formData = frame.extend({ fields: z.array(field).min(1), dismissLabel: text.optional() });
const count = z.number().int().min(0);
const dashboardData = frame.extend({
  metrics: z.array(metric.extend({ context: text })).min(1).max(4),
  activity: z.strictObject({
    title: text,
    description: text,
    incomingLabel: text,
    outgoingLabel: text,
    data: z.array(z.strictObject({ day: text, incoming: count, outgoing: count })).min(2).max(14),
  }),
  queue: z.strictObject({
    title: text,
    description: text,
    groups: z.array(z.strictObject({ label: text, count })).min(1).max(5),
  }),
  orders: listData,
});
const screen = z.discriminatedUnion('template', [
  z.strictObject({ ...common, template: z.literal('list'), variant: z.enum(['comfortable', 'compact']), scene: z.enum(['default', 'empty']), data: listData }),
  z.strictObject({ ...common, template: z.literal('detail'), variant: z.enum(['panel', 'page']), scene: z.literal('default'), background: common.id.optional(), data: detailData }),
  z.strictObject({ ...common, template: z.literal('form'), variant: z.enum(['dialog', 'page']), scene: z.enum(['default', 'invalid']), background: common.id.optional(), data: formData }),
  z.strictObject({ ...common, template: z.literal('dashboard'), variant: z.literal('overview'), scene: z.literal('default'), data: dashboardData }),
]);

export const mockupSchema = z.strictObject({
  version: z.literal(1),
  locale: z.string().regex(/^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$/),
  theme: z.enum(Object.keys(palettes)),
  palette: z.strictObject(Object.fromEntries(
    Object.keys(palettes.orange).map(role => [role, z.string().regex(/^#[0-9a-f]{6}$/i).optional()]),
  )).optional(),
  workspace: workspace.optional(),
  viewport: z.strictObject({ width: z.number().int().min(320).max(2560), height: z.number().int().min(480).max(2160) }),
  screens: z.array(screen).min(1),
}).superRefine(({ theme, palette, workspace, screens }, ctx) => {
  for (const message of contrastFailures(resolvePalette(theme, palette))) {
    ctx.addIssue({ code: 'custom', path: ['palette'], message });
  }
  const ids = new Set();
  screens.forEach(({ id, template, variant, scene, data, background, currentNavigation }, index) => {
    if (ids.has(id)) ctx.addIssue({ code: 'custom', path: ['screens', index, 'id'], message: 'Duplicate screen ID' });
    ids.add(id);
    if (currentNavigation && !workspace?.navigation.some(item => item.label === currentNavigation)) {
      ctx.addIssue({ code: 'custom', path: ['screens', index, 'currentNavigation'], message: 'Choose a label from the workspace navigation' });
    }
    if (background && (!['panel', 'dialog'].includes(variant) || !screens.some(screen => screen.id === background && screen.template === 'list'))) {
      ctx.addIssue({ code: 'custom', path: ['screens', index, 'background'], message: 'Reference a list screen from a panel or dialog' });
    }
    if (template === 'form' && scene === 'invalid' && !data.fields.some(field => field.error)) {
      ctx.addIssue({ code: 'custom', path: ['screens', index, 'data', 'fields'], message: 'Supply at least one field error for the invalid scene' });
    }
    if (template === 'list' && scene === 'empty' && data.rows.length > 0 && !data.emptyMessage) {
      ctx.addIssue({ code: 'custom', path: ['screens', index, 'data', 'emptyMessage'], message: 'Supply localized empty-state text' });
    }
  });
});
