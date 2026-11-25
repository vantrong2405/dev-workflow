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
  if (typeof dialog.showModal !== 'function') return;

  const title = document.getElementById('skill-dialog-title');
  const command = document.getElementById('skill-dialog-command');
  const body = document.getElementById('skill-dialog-body');
  const back = document.getElementById('skill-dialog-back');
  const close = dialog.querySelector('.skill-dialog-close');
  let trigger;
  let currentGroup;

  function showSkill(skill) {
    const summary = skill.querySelector('summary');
    title.textContent = summary.querySelector('span').textContent;
    command.textContent = summary.querySelector('code').textContent;
    command.hidden = false;
    back.hidden = !currentGroup;
    body.replaceChildren(skill.querySelector('.skill-body').cloneNode(true));
    dialog.scrollTop = 0;
  }

  function showGroup(group) {
    title.textContent = group.querySelector('h3').textContent;
    command.hidden = true;
    back.hidden = true;
    const intro = group.querySelector(':scope > p').cloneNode(true);
    intro.className = 'skill-dialog-intro';
    const list = document.createElement('div');
    list.className = 'skill-dialog-list';
    for (const skill of group.querySelectorAll(':scope > .skill')) {
      const button = document.createElement('button');
      button.type = 'button';
      const summary = skill.querySelector('summary');
      button.append(summary.querySelector('code').cloneNode(true), summary.querySelector('span').cloneNode(true));
      button.addEventListener('click', () => {
        showSkill(skill);
        title.focus({ preventScroll: true });
      });
      list.append(button);
    }
    body.replaceChildren(intro, list);
    dialog.scrollTop = 0;
  }

  function openTarget(target, from) {
    if (!target?.matches('.skill, .skill-group')) return false;
    trigger = from;
    currentGroup = target.matches('.skill-group') ? target : null;
    if (currentGroup) showGroup(currentGroup);
    else showSkill(target);
    dialog.showModal();
    close.focus({ preventScroll: true });
    return true;
  }

  function openLinkedTarget(event) {
    if (event.button !== 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
    const link = event.target.closest?.('a[href]');
    if (!link) return;
    const url = new URL(link.getAttribute('href'), link.ownerDocument.baseURI);
    const target = document.getElementById(url.hash.slice(1));
    if (openTarget(target, link)) event.preventDefault();
  }

  const workflow = document.getElementById('workflow');
  workflow.addEventListener('click', openLinkedTarget);
  for (const link of workflow.querySelectorAll('a[href^="#skill-"]')) {
    link.setAttribute('aria-haspopup', 'dialog');
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
  diagram.addEventListener('load', bindDiagram);
  bindDiagram();

  for (const skill of document.querySelectorAll('details.skill')) {
    skill.open = false;
    const summary = skill.querySelector('summary');
    summary.setAttribute('aria-haspopup', 'dialog');
    summary.addEventListener('click', (event) => {
      if (openTarget(skill, summary)) event.preventDefault();
    });
  }

  back.addEventListener('click', () => {
    showGroup(currentGroup);
    title.focus({ preventScroll: true });
  });
  dialog.addEventListener('click', (event) => {
    if (event.target !== dialog) return;
    const bounds = dialog.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right ||
      event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
  });
  dialog.addEventListener('close', () => {
    trigger?.focus({ preventScroll: true });
    trigger = undefined;
  });

  if (location.hash.startsWith('#skill-')) {
    const skill = document.getElementById(location.hash.slice(1));
    openTarget(skill, skill?.querySelector('summary'));
  }
}

setupSkillPopup();

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
