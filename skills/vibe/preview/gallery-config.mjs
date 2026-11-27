import { readFileSync } from 'node:fs';

const example = JSON.parse(readFileSync(new URL('mockup.example.json', import.meta.url), 'utf8'));
const [list, detail, form] = example.screens;
const listId = 'orders-list';
const formFields = form.data.fields.map((field, index) => index === 0 ? { ...field, value: 'Minh An' } : field);
const daily = [[26, 20], [31, 25], [28, 27], [36, 30], [34, 32], [18, 16], [13, 9]];
const activity = daily.map(([incoming, outgoing], index) => ({
  day: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][index], incoming, outgoing,
}));
const incoming = activity.reduce((total, day) => total + day.incoming, 0);
const outgoing = activity.reduce((total, day) => total + day.outgoing, 0);
const overview = {
  id: 'operations',
  label: 'Vận hành / Tổng quan',
  template: 'dashboard',
  variant: 'overview',
  scene: 'default',
  acceptance: ['AC-01'],
  currentNavigation: 'Tổng quan',
  data: {
    app: list.data.app,
    title: 'Tổng quan vận hành',
    description: 'Đơn hàng trong tuần 23–29/11/2026.',
    actions: { primary: 'Tạo đơn hàng' },
    metrics: [
      { label: 'Đơn mới', value: String(incoming), context: 'Tổng đơn tạo trong tuần', tone: 'accent' },
      { label: 'Đã bàn giao', value: String(outgoing), context: 'Đơn đã chuyển cho bên giao', tone: 'success' },
      { label: 'Chờ xử lý', value: String(incoming - outgoing), context: 'Còn trong hàng đợi', tone: 'warning' },
    ],
    activity: {
      title: 'Đơn hàng theo ngày',
      description: 'So sánh lượng đơn tạo và bàn giao.',
      incomingLabel: 'Đơn mới',
      outgoingLabel: 'Đã bàn giao',
      data: activity,
    },
    queue: {
      title: 'Hàng đợi xử lý',
      description: 'Số đơn còn lại theo công đoạn.',
      groups: [
        { label: 'Chờ lấy hàng', count: 18 },
        { label: 'Chờ đóng gói', count: 6 },
        { label: 'Thiếu thông tin', count: 3 },
      ],
    },
    orders: {
      app: list.data.app,
      title: 'Đơn đang xử lý gần đây',
      columns: list.data.columns,
      rows: list.data.rows.filter(row => row[3] === 'Đang xử lý'),
      rowAction: list.data.rowAction,
      statusColumn: list.data.statusColumn,
      statusTones: list.data.statusTones,
    },
  },
};

const screens = [
  overview,
  { ...list, id: listId },
  { ...list, id: 'orders-compact', label: 'Đơn hàng / Bảng gọn', variant: 'compact' },
  { ...list, id: 'orders-empty', label: 'Đơn hàng / Danh sách trống', scene: 'empty', data: { ...list.data, filters: ['Đã hoàn hàng'], rows: [] } },
  { ...detail, id: 'order-detail', background: listId },
  { ...detail, id: 'order-page', variant: 'page', background: undefined },
  { ...form, id: 'order-form-page', label: 'Đơn hàng / Sửa đơn', variant: 'page', scene: 'default', background: undefined, data: { ...form.data, fields: formFields } },
  { ...form, id: 'order-form', background: listId },
];

const comparison = process.argv.includes('--comparison');
const gallery = comparison
  ? { ...example, theme: 'ocean-breeze', screens: [{ ...overview, id: 'operations-ocean' }] }
  : { ...example, theme: 'tangerine', screens };
process.stdout.write(`${JSON.stringify(gallery, null, 2)}\n`);
