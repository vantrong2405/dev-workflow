const tabs = [...document.querySelectorAll('[role="tab"]')];

function activateTab(selected) {
  for (const tab of tabs) {
    const active = tab === selected;
    tab.setAttribute('aria-selected', String(active));
    tab.tabIndex = active ? 0 : -1;
    document.getElementById(tab.getAttribute('aria-controls')).hidden = !active;
  }
}

for (const [index, tab] of tabs.entries()) {
  tab.addEventListener('click', () => activateTab(tab));
  tab.addEventListener('keydown', (event) => {
    let target;
    if (event.key === 'ArrowLeft') target = tabs[(index - 1 + tabs.length) % tabs.length];
    if (event.key === 'ArrowRight') target = tabs[(index + 1) % tabs.length];
    if (event.key === 'Home') target = tabs[0];
    if (event.key === 'End') target = tabs[tabs.length - 1];
    if (!target) return;
    event.preventDefault();
    activateTab(target);
    target.focus();
  });
}

function setupSkillPopup() {
  const dialog = document.getElementById('skill-dialog');
  if (typeof dialog?.showModal !== 'function') return;

  const title = document.getElementById('skill-dialog-title');
  const command = document.getElementById('skill-dialog-command');
  const body = document.getElementById('skill-dialog-body');
  const back = document.getElementById('skill-dialog-back');
  const close = dialog.querySelector('.skill-dialog-close');
  let trigger;
  const previousViews = [];

  function showSkill(skill) {
    const summary = skill.querySelector('summary');
    title.textContent = summary.querySelector('span').textContent;
    command.textContent = summary.querySelector('code')?.textContent ?? '';
    command.hidden = !command.textContent;
    body.replaceChildren(skill.querySelector('.skill-body').cloneNode(true));
  }

  function showGroup(group) {
    title.textContent = group.querySelector('h3').textContent;
    command.hidden = true;
    const intro = group.querySelector(':scope > p').cloneNode(true);
    intro.className = 'skill-dialog-intro';
    const list = document.createElement('div');
    list.className = 'skill-dialog-list';
    for (const skill of group.querySelectorAll(':scope > .skill')) {
      const button = document.createElement('button');
      button.type = 'button';
      button.dataset.skillTarget = skill.id;
      const summary = skill.querySelector('summary');
      button.append(summary.querySelector('code').cloneNode(true), summary.querySelector('span').cloneNode(true));
      list.append(button);
    }
    body.replaceChildren(intro, list);
  }

  function showTarget(target) {
    if (target.matches('.skill-group')) showGroup(target);
    else showSkill(target);
    back.hidden = previousViews.length === 0;
    dialog.scrollTop = 0;
  }

  function openTarget(target, from) {
    if (!target?.matches('.skill, .skill-group')) return false;
    trigger = from;
    showTarget(target);
    dialog.showModal();
    close.focus({ preventScroll: true });
    return true;
  }

  function openLinkedTarget(event) {
    if (event.button !== 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
    const link = event.target.closest?.('a[href]');
    if (!link) return;
    const url = new URL(link.getAttribute('href'), link.ownerDocument.baseURI);
    const target = document.getElementById(link.dataset.skillTarget || url.hash.slice(1));
    if (openTarget(target, link)) event.preventDefault();
  }

  body.addEventListener('click', (event) => {
    if (event.button !== 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
    const control = event.target.closest('[data-skill-target], a[href^="#skill-"]');
    if (!control) return;
    const id = control.dataset.skillTarget || control.hash.slice(1);
    const target = document.getElementById(id);
    if (!target?.matches('.skill')) return;
    event.preventDefault();
    previousViews.push({
      nodes: [...body.childNodes],
      title: title.textContent,
      command: command.textContent,
      commandHidden: command.hidden,
      scrollTop: dialog.scrollTop,
      control,
    });
    showTarget(target);
    title.focus({ preventScroll: true });
  });

  for (const section of document.querySelectorAll('#workflow, [data-skill-links]')) {
    section.addEventListener('click', openLinkedTarget);
    for (const link of section.querySelectorAll('a[href^="#skill-"]')) {
      link.setAttribute('aria-haspopup', 'dialog');
    }
  }
  const diagram = document.querySelector('.flow-figure iframe');
  function bindDiagram() {
    // Local file previews may give the frame an opaque origin. The links still work there.
    const frameDocument = diagram.contentDocument;
    const svg = frameDocument?.querySelector('.workflow-diagram');
    if (!svg) return;
    svg.setAttribute('role', 'group');
    for (const link of svg.querySelectorAll('a')) link.setAttribute('aria-haspopup', 'dialog');
    frameDocument.addEventListener('click', openLinkedTarget);
  }
  if (diagram) {
    diagram.addEventListener('load', bindDiagram);
    bindDiagram();
  }

  for (const skill of document.querySelectorAll('details.skill')) {
    skill.open = false;
    const summary = skill.querySelector('summary');
    summary.setAttribute('aria-haspopup', 'dialog');
    summary.addEventListener('click', (event) => {
      if (openTarget(skill, summary)) event.preventDefault();
    });
  }

  back.addEventListener('click', () => {
    const previous = previousViews.pop();
    if (!previous) return;
    title.textContent = previous.title;
    command.textContent = previous.command;
    command.hidden = previous.commandHidden;
    body.replaceChildren(...previous.nodes);
    back.hidden = previousViews.length === 0;
    dialog.scrollTop = previous.scrollTop;
    previous.control.focus({ preventScroll: true });
  });
  dialog.addEventListener('click', (event) => {
    if (event.target !== dialog) return;
    const bounds = dialog.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right ||
      event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
  });
  dialog.addEventListener('close', () => {
    previousViews.length = 0;
    trigger?.focus({ preventScroll: true });
    trigger = undefined;
  });

  if (location.hash.startsWith('#skill-')) {
    const skill = document.getElementById(location.hash.slice(1));
    openTarget(skill, skill?.querySelector('summary'));
  }
}

setupSkillPopup();

function setupWorkflowPlayback() {
  const player = document.getElementById('workflow-player');
  if (!player) return;
  const slides = [...player.querySelectorAll('.flow-slide')];
  const frame = player.querySelector('iframe');
  const controls = player.querySelector('.flow-controls');
  const count = player.querySelector('[data-flow-count]');
  const progress = player.querySelector('[data-flow-progress]');
  const status = player.querySelector('[data-flow-status]');
  const previous = player.querySelector('[data-flow-prev]');
  const next = player.querySelector('[data-flow-next]');
  const play = player.querySelector('[data-flow-play]');
  const replay = player.querySelector('[data-flow-replay]');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const hold = 4200;
  const travel = 600;
  const lastIndex = slides.length - 1;
  let diagram;
  let activeNode;
  let connection;
  let index = 0;
  let elapsed = 0;
  let frameId;
  let lastTime;
  let playing = false;
  let started = false;

  function updateControls() {
    previous.disabled = index === 0;
    next.disabled = index === lastIndex;
    play.disabled = index === lastIndex;
    play.hidden = reducedMotion.matches;
    play.textContent = playing ? 'Tạm dừng' : 'Phát';
  }

  function highlightNode() {
    activeNode?.removeAttribute('data-active');
    activeNode?.removeAttribute('aria-current');
    activeNode = diagram?.document.querySelector(`[data-node="${slides[index].dataset.node}"]`);
    activeNode?.setAttribute('data-active', '');
    activeNode?.setAttribute('aria-current', 'step');
  }

  function showSlide(nextIndex, announce = false) {
    index = nextIndex;
    elapsed = 0;
    connection = undefined;
    for (const [position, slide] of slides.entries()) slide.hidden = position !== index;
    progress.value = index + 1;
    count.textContent = `Bước ${index + 1} / ${slides.length}`;
    diagram?.overlay.setAttribute('visibility', 'hidden');
    highlightNode();
    updateControls();
    if (announce) status.textContent = `${count.textContent}. ${slides[index].querySelector('h4').textContent}`;
  }

  function drawArrow(ratio) {
    if (!diagram) return;
    if (!connection) {
      const path = diagram.document.getElementById(slides[index + 1].dataset.edge);
      if (!path) return;
      connection = { path, length: path.getTotalLength() };
      diagram.line.setAttribute('d', path.getAttribute('d'));
      diagram.line.setAttribute('stroke-dasharray', connection.length);
      diagram.overlay.setAttribute('visibility', 'visible');
    }
    const { path, length } = connection;
    const distance = length * ratio;
    const tip = path.getPointAtLength(distance);
    const before = path.getPointAtLength(Math.max(0, distance - 1));
    const after = path.getPointAtLength(Math.min(length, distance + 1));
    const angle = Math.atan2(after.y - before.y, after.x - before.x) * 180 / Math.PI;
    diagram.line.setAttribute('stroke-dashoffset', length - distance);
    diagram.arrow.setAttribute('transform', `translate(${tip.x} ${tip.y}) rotate(${angle})`);
  }

  function pause() {
    cancelAnimationFrame(frameId);
    playing = false;
    lastTime = undefined;
    updateControls();
  }

  function tick(now) {
    if (lastTime !== undefined) elapsed += now - lastTime;
    lastTime = now;
    if (elapsed >= hold + travel) {
      showSlide(index + 1);
      if (index === lastIndex) {
        pause();
        return;
      }
    } else if (elapsed >= hold) {
      drawArrow((elapsed - hold) / travel);
    }
    frameId = requestAnimationFrame(tick);
  }

  function start() {
    if (playing || reducedMotion.matches || index === lastIndex) return;
    playing = true;
    started = true;
    updateControls();
    frameId = requestAnimationFrame(tick);
  }

  function seek(nextIndex) {
    if (nextIndex < 0 || nextIndex > lastIndex) return;
    started = true;
    pause();
    showSlide(nextIndex, true);
  }

  function selectDiagramNode(event) {
    if (event.button !== 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
    const node = event.target.closest('a[data-node]')?.dataset.node;
    if (!node) return;
    // Repeated nodes refer to the most recent pass through that step.
    for (let position = index; position >= 0; position--) {
      if (slides[position].dataset.node === node) {
        seek(position);
        return;
      }
    }
    seek(slides.findIndex(slide => slide.dataset.node === node));
  }

  function connectDiagram() {
    const frameDocument = frame.contentDocument;
    const overlay = frameDocument?.getElementById('flow-travel');
    if (!overlay) return;
    diagram = {
      document: frameDocument,
      overlay,
      line: overlay.querySelector('.travel-line'),
      arrow: overlay.querySelector('.travel-arrow'),
    };
    connection = undefined;
    highlightNode();
    frameDocument.addEventListener('click', selectDiagramNode, { capture: true });
  }

  frame.addEventListener('load', connectDiagram);
  connectDiagram();
  previous.addEventListener('click', () => seek(index - 1));
  next.addEventListener('click', () => seek(index + 1));
  play.addEventListener('click', () => playing ? pause() : start());
  replay.addEventListener('click', () => {
    seek(0);
    start();
  });
  player.addEventListener('click', (event) => {
    if (event.target.closest('a')) pause();
  });
  player.querySelector('.flow-slides').addEventListener('focusin', pause);
  player.addEventListener('keydown', (event) => {
    if (event.target.closest('a') || event.ctrlKey || event.altKey || event.metaKey) return;
    const destination = { ArrowLeft: index - 1, ArrowRight: index + 1, Home: 0, End: lastIndex }[event.key];
    if (typeof destination !== 'number') return;
    event.preventDefault();
    seek(destination);
  });
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) pause();
  });
  reducedMotion.addEventListener('change', () => {
    if (reducedMotion.matches) {
      pause();
      showSlide(index);
    }
    updateControls();
  });
  progress.max = slides.length;
  showSlide(0);
  controls.hidden = false;
  count.hidden = false;
  const observer = new IntersectionObserver(([entry]) => {
    if (entry.intersectionRatio < .3) pause();
    else if (!started && !document.querySelector('.skill-dialog[open]')) start();
  }, { threshold: .3 });
  observer.observe(player);
}

setupWorkflowPlayback();

function setupInstall() {
  const hostNotes = {
    codex: 'Mở task mới trong repo sản phẩm, chọn skill start của ak và gửi việc cần làm.',
    claude: 'Tải lại plugin, mở repo sản phẩm rồi gọi /ak với việc cần làm.',
    cursor: 'Tải lại Cursor, mở repo sản phẩm rồi gọi /ak với việc cần làm.',
    agy: 'Cần có agy trên PATH. Sau khi cài, tải lại Antigravity và chọn skill start của ak.',
  };

  const command = document.getElementById('install-command');
  const note = document.getElementById('host-note');
  const status = document.getElementById('copy-status');
  const copy = document.getElementById('copy-command');
  if (!command || !copy) return;
  const setup = command.textContent.split('\n').slice(0, -1).join('\n');

  for (const input of document.querySelectorAll('input[name="host"]')) {
    input.addEventListener('change', () => {
      if (!input.checked) return;
      command.textContent = `${setup}\nbash install.sh --${input.value}`;
      note.textContent = hostNotes[input.value];
      status.textContent = '';
    });
  }

  copy.addEventListener('click', async () => {
    const selectedCommand = command.textContent;
    try {
      await navigator.clipboard.writeText(selectedCommand);
      if (command.textContent === selectedCommand) status.textContent = 'Đã sao chép lệnh cài đặt.';
    } catch {
      if (command.textContent !== selectedCommand) return;
      const range = document.createRange();
      range.selectNodeContents(command);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      status.textContent = 'Lệnh đã được chọn. Dùng phím tắt sao chép.';
    }
  });
}

setupInstall();
