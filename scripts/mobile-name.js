// Campo HTML real sobre el LineEdit. El toque abre el teclado directamente,
// sin llamadas asincronas a focus ni depender del teclado experimental de Godot.
(() => {
  if (window.GroovaNameInput) return;
  const input = document.createElement('input');
  input.type = 'text';
  input.id = 'groova-player-name';
  input.maxLength = 12;
  input.placeholder = 'JUGADOR';
  input.autocomplete = 'off';
  input.autocapitalize = 'characters';
  input.spellcheck = false;
  input.setAttribute('autocorrect', 'off');
  input.setAttribute('enterkeyhint', 'done');
  input.setAttribute('aria-label', 'Tu nombre para el ranking, maximo 12 caracteres');
  Object.assign(input.style, {
    display: 'none', position: 'fixed', zIndex: '2147483646', boxSizing: 'border-box',
    margin: '0', border: '2px solid #5ceaff', borderRadius: '3px', padding: '8px',
    background: '#090a20', color: '#5ceaff', caretColor: '#ffffff', textAlign: 'center',
    fontFamily: 'GroovaArcade, monospace', fontSize: '16px', outline: 'none',
    touchAction: 'manipulation', userSelect: 'text', webkitUserSelect: 'text'
  });
  const style = document.createElement('style');
  style.textContent = '@font-face{font-family:GroovaArcade;src:url("arcade-name.ttf") format("truetype");font-display:swap}';
  document.head.appendChild(style);
  document.body.appendChild(input);
  let session = null;
  let submitted = false;
  let visible = false;
  let autofocusSession = null;
  let hitbox = null;
  function focusName(fromGesture = false) {
    if (!visible) return;
    // Safari puede dejar el input enfocado sin abrir el teclado. Un nuevo
    // enfoque dentro del toque permite volver a solicitarlo al sistema.
    if (fromGesture && document.activeElement === input) input.blur();
    input.focus({ preventScroll: true });
  }
  function focusFromGesture(event) {
    if (!visible || !hitbox) return;
    const point = event.changedTouches?.[0] || event;
    const inside = point.clientX >= hitbox.left && point.clientX <= hitbox.right && point.clientY >= hitbox.top && point.clientY <= hitbox.bottom;
    if (event.target !== input && !inside) return;
    // Capturar antes del canvas evita que Godot recupere el foco del input.
    if (event.target !== input) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
    focusName(true);
  }
  document.addEventListener('pointerdown', focusFromGesture, { capture: true, passive: false });
  document.addEventListener('touchend', focusFromGesture, { capture: true, passive: false });
  input.addEventListener('click', () => focusName(true));
  input.addEventListener('pointerdown', (event) => event.stopPropagation());
  input.addEventListener('keydown', (event) => {
    event.stopPropagation();
    if (event.key === 'Enter' && !event.isComposing) {
      event.preventDefault();
      submitted = true;
      input.blur();
    }
  });
  input.addEventListener('keyup', (event) => event.stopPropagation());
  function hide() {
    if (document.activeElement === input) input.blur();
    input.style.display = 'none';
    visible = false;
  }
  window.GroovaNameInput = {
    hide,
    getValue: () => session === null ? null : input.value,
    update(state) {
      if (state.session !== session) {
        session = state.session;
        input.value = state.value || '';
        submitted = false;
      }
      const canvas = document.getElementById('canvas');
      if (!state.visible || !canvas) { hide(); return null; }
      if (!visible && document.fullscreenElement) {
        // Un canvas en pantalla completa no permite mostrar controles HTML encima.
        document.exitFullscreen?.().then(() => focusName()).catch(() => {});
      }
      const bounds = canvas.getBoundingClientRect();
      const scaleX = Math.min(bounds.width / state.width, bounds.height / state.height);
      const scaleY = scaleX;
      const contentLeft = bounds.left + (bounds.width - state.width * scaleX) / 2;
      const contentTop = bounds.top + (bounds.height - state.height * scaleY) / 2;
      hitbox = {
        left: contentLeft + state.x * scaleX, top: contentTop + state.y * scaleY,
        right: contentLeft + (state.x + state.w) * scaleX, bottom: contentTop + (state.y + state.h) * scaleY
      };
      Object.assign(input.style, {
        display: 'block', left: `${contentLeft + state.x * scaleX}px`,
        top: `${contentTop + state.y * scaleY}px`, width: `${state.w * scaleX}px`,
        height: `${state.h * scaleY}px`, fontSize: `${Math.max(16, 16 * scaleX)}px`
      });
      visible = true;
      if (autofocusSession !== session) {
        autofocusSession = session;
        // Intentar una sola vez por partida; no robar el foco al cerrar teclado.
        focusName();
      }
      const result = { value: input.value, submitted };
      submitted = false;
      return result;
    }
  };
})();
