import { createRoot } from 'react-dom/client';
import { ArrowUpRight, ChevronDown, Search, X } from 'lucide-react';
import '@fontsource/be-vietnam-pro/400.css';
import '@fontsource/be-vietnam-pro/500.css';
import '@fontsource/be-vietnam-pro/600.css';
import '@fontsource/be-vietnam-pro/700.css';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ChartContainer, ChartLegend, ChartLegendContent, ChartTooltip, ChartTooltipContent } from '@/components/ui/chart';
import { Dialog, DialogClose, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field';
import { Input } from '@/components/ui/input';
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select';
import { Progress } from '@/components/ui/progress';
import { Sheet, SheetClose, SheetContent, SheetDescription, SheetFooter, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import {
  Sidebar, SidebarContent, SidebarHeader, SidebarInset, SidebarMenu, SidebarMenuButton,
  SidebarMenuItem, SidebarProvider, SidebarTrigger,
} from '@/components/ui/sidebar';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Textarea } from '@/components/ui/textarea';
import { Bar, BarChart, CartesianGrid, XAxis, YAxis } from 'recharts';
import './styles.css';

function Actions({ actions }) {
  return actions && (
    <div className="flex flex-wrap gap-2">
      {actions.secondary && <Button variant="outline">{actions.secondary}</Button>}
      {actions.primary && <Button>{actions.primary}</Button>}
    </div>
  );
}

function Heading({ data, actions = false, section = false }) {
  const Title = section ? 'h2' : 'h1';
  return (
    <header className="screen-heading">
      <div>
        <Title>{data.title}</Title>
        {data.description && <p>{data.description}</p>}
      </div>
      {actions && <Actions actions={data.actions} />}
    </header>
  );
}

function Status({ value, tone = 'neutral' }) {
  return <Badge variant="secondary" className="status" data-tone={tone}>{value}</Badge>;
}

function Summary({ items }) {
  return items && (
    <Card className="summary-card gap-0 py-0 shadow-none">
      <dl className="summary-strip">
        {items.map(({ label, value, tone = 'neutral' }, index) => (
          <div key={index} data-tone={tone}><dt>{label}</dt><dd>{value}</dd></div>
        ))}
      </dl>
    </Card>
  );
}

function List({ data, variant, scene, section = false }) {
  return (
    <>
      <Heading data={data} section={section} />
      <Summary items={scene === 'empty' ? undefined : data.summary} />
      <Card className="record-list gap-0 py-0 shadow-none">
        {(data.search || data.filters?.length > 0 || data.actions) && (
          <div className="record-toolbar">
            <div className="record-filters">
              {data.search && (
                <div className="record-search">
                  <Search aria-hidden="true" />
                  <Input type="search" readOnly aria-label={data.search} placeholder={data.search} />
                </div>
              )}
              {data.filters?.map((filter, index) => (
                <Button key={index} variant="outline">{filter}<ChevronDown aria-hidden="true" /></Button>
              ))}
            </div>
            <Actions actions={data.actions} />
          </div>
        )}
        <Table className="record-table" data-density={variant}>
          <TableHeader>
            <TableRow>
              {data.columns.map((column, index) => <TableHead key={index} scope="col">{column}</TableHead>)}
              {data.rowAction && <TableHead scope="col" aria-label={data.rowAction} />}
            </TableRow>
          </TableHeader>
          <TableBody>
            {scene === 'empty' || data.rows.length === 0 ? (
              <TableRow><TableCell colSpan={data.columns.length + Number(Boolean(data.rowAction))} className="empty-state">{data.emptyMessage}</TableCell></TableRow>
            ) : data.rows.map((row, index) => (
              <TableRow key={index}>
                {row.map((value, cellIndex) => {
                  const tone = data.statusTones && Object.hasOwn(data.statusTones, value) ? data.statusTones[value] : undefined;
                  return <TableCell key={cellIndex}>{cellIndex === data.statusColumn ? <Status value={value} tone={tone} /> : value}</TableCell>;
                })}
                {data.rowAction && <TableCell className="record-action"><Button variant="ghost" size="sm">{data.rowAction}<ArrowUpRight aria-hidden="true" /></Button></TableCell>}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>
    </>
  );
}

function Dashboard({ data }) {
  const { activity, queue } = data;
  const chartConfig = {
    incoming: { label: activity.incomingLabel, color: 'var(--accent)' },
    outgoing: { label: activity.outgoingLabel, color: 'var(--chart-secondary)' },
  };
  const queuedTotal = queue.groups.reduce((total, group) => total + group.count, 0);
  return (
    <div className="operations-dashboard">
      <Heading data={data} actions />
      <div className="dashboard-metrics">
        {data.metrics.map(({ label, value, context, tone = 'neutral' }) => (
          <Card key={label} className="dashboard-metric gap-2 py-4 shadow-none" data-tone={tone}>
            <CardHeader className="gap-1 px-4">
              <CardDescription>{label}</CardDescription>
              <CardTitle>{value}</CardTitle>
            </CardHeader>
            <CardContent className="px-4 text-xs text-muted-foreground">{context}</CardContent>
          </Card>
        ))}
      </div>
      <div className="dashboard-analysis">
        <Card className="gap-3 py-4 shadow-none">
          <CardHeader className="px-4"><CardTitle>{activity.title}</CardTitle><CardDescription>{activity.description}</CardDescription></CardHeader>
          <CardContent className="px-4">
            <ChartContainer config={chartConfig} className="dashboard-chart">
              <BarChart data={activity.data} accessibilityLayer margin={{ left: -20, right: 5 }}>
                <CartesianGrid vertical={false} />
                <XAxis dataKey="day" tickLine={false} axisLine={false} tickMargin={6} />
                <YAxis tickLine={false} axisLine={false} allowDecimals={false} />
                <ChartTooltip content={<ChartTooltipContent />} />
                <ChartLegend content={<ChartLegendContent />} />
                <Bar dataKey="incoming" radius={[4, 4, 0, 0]} fill="var(--color-incoming)" isAnimationActive={false} />
                <Bar dataKey="outgoing" radius={[4, 4, 0, 0]} fill="var(--color-outgoing)" isAnimationActive={false} />
              </BarChart>
            </ChartContainer>
          </CardContent>
        </Card>
        <Card className="gap-4 py-4 shadow-none">
          <CardHeader className="px-4"><CardTitle>{queue.title}</CardTitle><CardDescription>{queue.description}</CardDescription></CardHeader>
          <CardContent className="dashboard-queue px-4">
            {queue.groups.map(({ label, count }) => (
              <div key={label}>
                <p><span>{label}</span><Badge variant="secondary">{count}</Badge></p>
                <Progress value={queuedTotal ? (count / queuedTotal) * 100 : 0} aria-label={label} />
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
      <List data={data.orders} variant="compact" scene="default" section />
    </div>
  );
}

const overlays = {
  side: { Root: Sheet, Content: SheetContent, Header: SheetHeader, Title: SheetTitle, Description: SheetDescription, Footer: SheetFooter, Close: SheetClose },
  center: { Root: Dialog, Content: DialogContent, Header: DialogHeader, Title: DialogTitle, Description: DialogDescription, Footer: DialogFooter, Close: DialogClose },
};

function Overlay({ data, label, placement, children }) {
  const { Root, Content, Header, Title, Description, Footer, Close } = overlays[placement];
  return (
    <Root defaultOpen>
      <Content className="preview-overlay" data-placement={placement} showCloseButton={!data.dismissLabel} onOpenAutoFocus={event => event.preventDefault()} {...(!data.description && { 'aria-describedby': undefined })}>
        <Header className="overlay-header">
          {label && <p className="scene-label">{label}</p>}
          <Title className="display-title">{data.title}</Title>
          {data.description && <Description>{data.description}</Description>}
        </Header>
        {data.dismissLabel && (
          <Close asChild>
            <Button variant="ghost" size="icon" className="overlay-dismiss" aria-label={data.dismissLabel}><X aria-hidden="true" /></Button>
          </Close>
        )}
        <div className="overlay-body">{children}</div>
        {data.actions && <Footer className="preview-actions"><Actions actions={data.actions} /></Footer>}
      </Content>
    </Root>
  );
}

function DetailFields({ data }) {
  return (
    <>
      {data.status && <Status value={data.status} tone={data.statusTone} />}
      <dl className="detail-fields">
        {data.fields.map(({ label, value }, index) => (
          <div key={index}><dt>{label}</dt><dd>{value}</dd></div>
        ))}
      </dl>
    </>
  );
}

function Detail({ data, variant, label }) {
  if (variant === 'panel') {
    return <Overlay data={data} label={label} placement="side"><DetailFields data={data} /></Overlay>;
  }
  return <article className="max-w-3xl"><Heading data={data} actions /><Card className="page-card gap-0 shadow-none"><DetailFields data={data} /></Card></article>;
}

function FormFields({ data, invalid }) {
  return (
    <FieldGroup className="gap-4">
      {data.fields.map(({ label, kind, value, options, error }, index) => {
        const id = `field-${index}`;
        const message = invalid ? error : undefined;
        const props = { id, defaultValue: value, 'aria-invalid': Boolean(message), 'aria-describedby': message ? `${id}-error` : undefined };
        return (
          <Field key={id} data-invalid={Boolean(message)} className="gap-1.5">
            <FieldLabel htmlFor={id}>{label}</FieldLabel>
            {kind === 'textarea' && <Textarea {...props} rows={3} />}
            {kind === 'input' && <Input {...props} />}
            {kind === 'select' && <NativeSelect {...props} className="w-full">{options.map(option => <NativeSelectOption key={option}>{option}</NativeSelectOption>)}</NativeSelect>}
            {message && <FieldError id={`${id}-error`}>{message}</FieldError>}
          </Field>
        );
      })}
    </FieldGroup>
  );
}

function Form({ data, variant, scene, label }) {
  const fields = <FormFields data={data} invalid={scene === 'invalid'} />;
  if (variant === 'dialog') {
    return <Overlay data={data} label={label} placement="center">{fields}</Overlay>;
  }
  return (
    <article className="max-w-2xl">
      <Heading data={data} />
      <Card className="page-card shadow-none">
        {fields}
        {data.actions && <footer className="page-actions"><Actions actions={data.actions} /></footer>}
      </Card>
    </article>
  );
}

function Brand({ app, mark }) {
  return <div className="workspace-brand"><Badge className="brand-mark" aria-hidden="true">{mark ?? [...app][0]}</Badge><span>{app}</span></div>;
}

function Workspace({ app, label, workspace, currentNavigation, children }) {
  if (!workspace) {
    return (
      <div className="workspace">
        <header className="workspace-bar"><Brand app={app} /><span className="scene-label">{label}</span></header>
        <main className="workspace-main">{children}</main>
      </div>
    );
  }
  return (
    <SidebarProvider className="workspace" style={{ '--sidebar-width': '13rem' }}>
      <Sidebar>
        <SidebarHeader className="sidebar-heading"><Brand app={app} mark={workspace.mark} /></SidebarHeader>
        <SidebarContent className="sidebar-links">
          <SidebarMenu>
            {workspace.navigation.map(({ label, current }, index) => {
              const active = currentNavigation ? label === currentNavigation : current;
              return (
                <SidebarMenuItem key={index}>
                  <SidebarMenuButton isActive={active} aria-current={active ? 'page' : undefined}>{label}</SidebarMenuButton>
                </SidebarMenuItem>
              );
            })}
          </SidebarMenu>
        </SidebarContent>
      </Sidebar>
      <SidebarInset className="min-w-0 bg-canvas">
        <header className="workspace-bar workspace-mobile-bar"><SidebarTrigger /><Brand app={app} mark={workspace.mark} /></header>
        <div className="workspace-main"><p className="scene-label">{label}</p>{children}</div>
      </SidebarInset>
    </SidebarProvider>
  );
}

const templates = { list: List, detail: Detail, form: Form, dashboard: Dashboard };
const { screen, locale, palette, workspace, background } = window.vibePreview;
const Template = templates[screen.template];
const isOverlay = ['panel', 'dialog'].includes(screen.variant);
document.documentElement.lang = locale;
for (const [role, color] of Object.entries(palette)) {
  document.documentElement.style.setProperty(`--${role}`, color);
}

createRoot(document.getElementById('root')).render(
  <div data-vibe-ready={screen.id}>
    <Workspace app={screen.data.app} label={background?.label ?? screen.label} workspace={workspace} currentNavigation={screen.currentNavigation}>
      {background && <List {...background} />}
      {!isOverlay && <Template {...screen} />}
    </Workspace>
    {isOverlay && <Template {...screen} />}
  </div>,
);
