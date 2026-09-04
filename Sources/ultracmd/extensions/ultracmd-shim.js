// UltraCMD extension shim — provides a React-compatible surface plus the
// @raycast/api and @raycast/utils modules on top of the __native bridge.
// Host elements are rendered to a JSON descriptor tree which Swift renders
// natively with SwiftUI (List / Detail / Form / ActionPanel).
//
// This file is embedded in the Swift binary as a raw string (ShimJS.swift).

globalThis.__ultracmdShim = (function () {
  'use strict';

  // ------------------------------------------------------------------
  // Callback registry: function props become ids crossing the bridge.
  // ------------------------------------------------------------------
  const callbacks = new Map();
  let cbSeq = 0;
  function registerCallback(fn) {
    if (typeof fn !== 'function') return undefined;
    const id = 'cb' + (++cbSeq);
    callbacks.set(id, fn);
    return id;
  }
  function invoke(id) {
    const fn = callbacks.get(id);
    if (!fn) return;
    const args = Array.prototype.slice.call(arguments, 1);
    return fn.apply(null, args);
  }

  // ------------------------------------------------------------------
  // Mini React: createElement + hooks + full re-render reconciliation.
  // Component instances are keyed by tree position; a setState marks the
  // root dirty and schedules one batched render pass.
  // ------------------------------------------------------------------
  const React = (function () {
    const stateMap = new Map(); // compKey -> {cells: [], cursor, effects, alive}
    let current = null; // {key, record}
    let rootComponent = null;
    let rootProps = {};
    let dirty = false;
    let renderHook = null; // called with descriptor after render
    let unmountHook = null;
    let errorHook = null;

    function schedule() {
      if (dirty) return;
      dirty = true;
      Promise.resolve().then(function () {
        dirty = false;
        try {
          render();
        } catch (e) {
          if (errorHook) errorHook(String(e && e.stack || e));
        }
      });
    }

    function render() {
      if (!rootComponent) return;
      const visited = new Set();
      const descriptor = renderElement(
        { type: rootComponent, props: rootProps },
        '0',
        visited
      );
      // Unmount effects for components that disappeared.
      for (const key of Array.from(stateMap.keys())) {
        if (!visited.has(key)) {
          const rec = stateMap.get(key);
          for (const eff of rec.effects) {
            if (typeof eff.cleanup === 'function') {
              try { eff.cleanup(); } catch (e) { /* noop */ }
            }
          }
          stateMap.delete(key);
        }
      }
      if (renderHook) renderHook(descriptor);
      return descriptor;
    }

    function renderElement(el, key, visited) {
      if (el === null || el === undefined || el === false || el === true) return null;
      if (Array.isArray(el)) {
        const out = [];
        let idx = 0;
        for (const child of el) {
          const rendered = renderElement(child, key + '/' + (idx++), visited);
          if (rendered === null) continue;
          if (Array.isArray(rendered)) {
            for (const r of rendered) out.push(r);
          } else out.push(rendered);
        }
        return out.length ? out : null;
      }
      if (typeof el === 'string' || typeof el === 'number') {
        return { type: 'text', text: String(el) };
      }
      if (typeof el.type === 'function') {
        return renderComponent(el, key, visited);
      }
      return renderHost(el, key, visited);
    }

    function renderComponent(el, key, visited) {
      let rec = stateMap.get(key);
      if (!rec) {
        rec = { cells: [], cursor: 0, effects: [], pendingEffects: [] };
        stateMap.set(key, rec);
      }
      rec.cursor = 0;
      rec.pendingEffects = [];
      const prev = current;
      current = { key, record: rec };
      let result;
      try {
        result = el.type(el.props || {});
      } finally {
        current = prev;
      }
      visited.add(key);
      return renderElement(result, key, visited);
    }

    // --- hooks -------------------------------------------------------
    function ensureCurrent(hookName) {
      if (!current) throw new Error(hookName + ' called outside a component render');
      return current;
    }

    function useState(initial) {
      const { key, record } = ensureCurrent('useState');
      const i = record.cursor++;
      if (!(i in record.cells)) {
        const value = typeof initial === 'function' ? initial() : initial;
        record.cells[i] = value;
      }
      const setState = function (next) {
        const cur = stateMap.get(key);
        if (!cur) return;
        const newValue = typeof next === 'function' ? next(cur.cells[i]) : next;
        if (Object.is(newValue, cur.cells[i])) return;
        cur.cells[i] = newValue;
        schedule();
      };
      return [record.cells[i], setState];
    }

    function useRef(initial) {
      const { record } = ensureCurrent('useRef');
      const i = record.cursor++;
      if (!(i in record.cells)) record.cells[i] = { current: initial };
      return record.cells[i];
    }

    function useMemo(fn, deps) {
      const { record } = ensureCurrent('useMemo');
      const i = record.cursor++;
      const prev = record.cells[i];
      if (!prev || !shallowEqual(prev.deps, deps)) {
        record.cells[i] = { value: fn(), deps: deps ? deps.slice() : undefined };
      }
      return record.cells[i].value;
    }

    function useCallback(fn, deps) {
      return useMemo(function () { return fn; }, deps ? deps.concat([fn]) : undefined);
    }

    function useEffect(fn, deps) {
      const { key, record } = ensureCurrent('useEffect');
      const i = record.cursor++;
      const prev = record.cells[i];
      const changed = !prev || !shallowEqual(prev.deps, deps);
      record.cells[i] = { deps: deps ? deps.slice() : undefined, cleanup: prev ? prev.cleanup : undefined };
      if (changed) {
        record.pendingEffects.push({ key, index: i, fn });
      }
    }

    function useLayoutEffect(fn, deps) { useEffect(fn, deps); }

    function shallowEqual(a, b) {
      if (a === undefined && b === undefined) return false; // undefined deps = run every time
      if (!Array.isArray(a) || !Array.isArray(b)) return a === b;
      if (a.length !== b.length) return false;
      for (let i = 0; i < a.length; i++) if (!Object.is(a[i], b[i])) return false;
      return true;
    }

    function createElement(type, props) {
      const children = [];
      for (let i = 2; i < arguments.length; i++) {
        const c = arguments[i];
        if (Array.isArray(c)) {
          for (const cc of c) children.push(cc);
        } else if (c !== null && c !== undefined && c !== false && c !== true) {
          children.push(c);
        }
      }
      const p = Object.assign({}, props || {});
      if (children.length) p.children = children;
      return { type: type, props: p };
    }

    function Fragment(props) { return props.children; }

    // Run pending effects right after the descriptor was handed to native.
    function flushEffects() {
      for (const key of Array.from(stateMap.keys())) {
        const rec = stateMap.get(key);
        for (const eff of rec.pendingEffects || []) {
          try {
            const cleanup = eff.fn();
            const cell = rec.cells[eff.index];
            if (cell) cell.cleanup = typeof cleanup === 'function' ? cleanup : undefined;
          } catch (e) {
            if (errorHook) errorHook(String(e && e.stack || e));
          }
        }
        rec.pendingEffects = [];
      }
    }

    return {
      createElement: createElement,
      Fragment: Fragment,
      useState: useState,
      useRef: useRef,
      useMemo: useMemo,
      useCallback: useCallback,
      useEffect: useEffect,
      useLayoutEffect: useLayoutEffect,
      useContext: function () { return {}; },
      createContext: function (def) {
        return { _current: def, Provider: Fragment, Consumer: Fragment };
      },
      version: '18.0.0-ultracmd',
      __mount: function (component, props) {
        rootComponent = component;
        rootProps = props || {};
        const desc = render();
        return desc;
      },
      __setRenderHook: function (fn) { renderHook = fn; },
      __setErrorHook: function (fn) { errorHook = fn; },
      __flushEffects: flushEffects,
    };
  })();

  // ------------------------------------------------------------------
  // Host element -> native descriptor
  // ------------------------------------------------------------------
  function iconToString(icon) {
    if (!icon) return undefined;
    if (typeof icon === 'string') return icon;
    if (typeof icon === 'object') {
      if (typeof icon.source === 'string') return icon.source;
      if (typeof icon.fileIcon === 'string') return 'file:' + icon.fileIcon;
      if (typeof icon.http === 'object' && icon.http.url) return icon.http.url;
      if (typeof icon.url === 'string') return icon.url;
      if (typeof icon.light === 'string') return icon.light;
    }
    return undefined;
  }

  function normalizeShortcut(shortcut) {
    if (!shortcut) return undefined;
    if (typeof shortcut === 'string') return shortcut;
    if (typeof shortcut === 'object' && shortcut.key) {
      let s = '';
      if (shortcut.modifiers) {
        const mods = Array.isArray(shortcut.modifiers) ? shortcut.modifiers : [shortcut.modifiers];
        for (const m of mods) {
          const lower = String(m).toLowerCase();
          if (lower === 'cmd' || lower === 'command') s += 'cmd+';
          else if (lower === 'ctrl' || lower === 'control') s += 'ctrl+';
          else if (lower === 'opt' || lower === 'option' || lower === 'alt') s += 'opt+';
          else if (lower === 'shift') s += 'shift+';
        }
      }
      return s + shortcut.key;
    }
    return undefined;
  }

  function renderActionNode(node) {
    if (!node || typeof node !== 'object') return null;
    const nodeType = node.type instanceof String ? node.type.valueOf() : node.type;
    if (nodeType === 'action-panel' || nodeType === 'action-panel-section') {
      const actions = [];
      for (const child of node.props.children || []) {
        const a = renderActionNode(child);
        if (a) actions.push(a);
      }
      return actions;
    }
    const actionType = String(nodeType);
    if (typeof nodeType !== 'undefined' && actionType.indexOf('action') === 0) {
      return {
        id: registerCallback(function (input) {
          const props = node.props || {};
          if (typeof props.onPerform === 'function') return props.onPerform(input);
        }),
        title: String(node.props.title || ''),
        shortcut: normalizeShortcut(node.props.shortcut),
        style: actionType === 'action' ? (node.props.style === 'destructive' ? 'destructive' : 'regular') : 'regular',
        submitForm: actionType === 'action-submit-form' || actionType === 'action-submit',
        icon: iconToString(node.props.icon),
      };
    }
    return null;
  }

  function flattenActions(actionPanelNode) {
    if (!actionPanelNode) return [];
    const result = renderActionNode(actionPanelNode);
    if (!result) return [];
    if (Array.isArray(result)) return result;
    return [result];
  }

  function renderHost(el, key, visited) {
    const type = el.type instanceof String ? el.type.valueOf() : el.type;
    const props = el.props || {};

    if (type === 'list' || type === 'grid') {
      const sections = [];
      const orphanItems = [];
      for (const child of props.children || []) {
        if (!child || typeof child !== 'object') continue;
        if (child.type === 'list-section') {
          const items = [];
          for (const item of child.props.children || []) {
            const rendered = renderHostItem(item);
            if (rendered) items.push(rendered);
          }
          sections.push({ title: child.props.title || null, items: items });
        } else if (child.type === 'list-item') {
          const rendered = renderHostItem(child);
          if (rendered) orphanItems.push(rendered);
        }
      }
      if (orphanItems.length) sections.unshift({ title: null, items: orphanItems });
      return {
        view: 'list',
        isLoading: props.isLoading === true,
        placeholder: props.searchBarPlaceholder || 'Search…',
        navigationTitle: props.navigationTitle || undefined,
        sections: sections,
        onSearchTextChange: props.onSearchTextChange ? registerCallback(props.onSearchTextChange) : undefined,
        onSelectionChange: props.onSelectionChange ? registerCallback(props.onSelectionChange) : undefined,
        onQueryUpdated: props.onSearchTextChange ? undefined : undefined,
      };
    }

    if (type === 'detail') {
      let markdown = typeof props.markdown === 'string' ? props.markdown : '';
      if (!markdown) {
        // children may include <Markdown>{'...text...'}</Markdown>
        const parts = [];
        for (const child of props.children || []) {
          if (child && typeof child === 'object' && child.type === 'markdown') {
            for (const frag of child.props.children || []) {
              parts.push(typeof frag === 'string' ? frag : String(frag && frag.text != null ? frag.text : frag));
            }
          }
        }
        markdown = parts.join('');
      }
      return {
        view: 'detail',
        markdown: markdown,
        isLoading: props.isLoading === true,
        navigationTitle: props.navigationTitle || undefined,
        actions: flattenActions(props.actions),
      };
    }

    if (type === 'form') {
      const fields = [];
      for (const child of props.children || []) {
        if (!child || typeof child !== 'object') continue;
        const t = child.type;
        const p = child.props || {};
        if (t === 'form-text-field' || t === 'form-text-area' || t === 'form-password-field' || t === 'form-date-picker' || t === 'form-tag-picker') {
          fields.push({
            id: p.id,
            label: p.title || '',
            type: t === 'form-text-area' ? 'textarea' : t === 'form-password-field' ? 'password' : 'text',
            placeholder: p.placeholder || '',
            defaultValue: p.defaultValue != null ? String(p.defaultValue) : (p.value != null ? String(p.value) : ''),
            info: p.info || '',
          });
        } else if (t === 'form-checkbox') {
          fields.push({ id: p.id, label: p.title || p.label || '', type: 'checkbox', defaultValue: p.defaultValue === true ? 'true' : 'false', info: p.info || '' });
        } else if (t === 'form-dropdown') {
          const options = [];
          for (const opt of p.children || []) {
            if (opt && opt.type === 'form-dropdown-item') {
              options.push({ value: String(opt.props.value), label: String(opt.props.title || opt.props.value) });
            }
          }
          fields.push({ id: p.id, label: p.title || '', type: 'dropdown', placeholder: p.placeholder || '', defaultValue: p.defaultValue != null ? String(p.defaultValue) : (options[0] ? options[0].value : ''), info: p.info || '', options: options });
        } else if (t === 'form-description') {
          fields.push({ id: p.id || 'desc', label: p.title || '', type: 'description', text: p.text || '', info: p.info || '' });
        } else if (t === 'form-separator') {
          fields.push({ id: 'sep' + fields.length, type: 'separator' });
        }
      }
      return {
        view: 'form',
        navigationTitle: props.navigationTitle || undefined,
        isLoading: props.isLoading === true,
        fields: fields,
        actions: flattenActions(props.actions),
      };
    }

    if (type === 'text') return el;

    // Unknown host elements are transparent containers.
    const children = renderElement(props.children || [], key + '/h', visited);
    return Array.isArray(children) ? children[0] || null : children;
  }

  function renderHostItem(item) {
    if (!item || typeof item !== 'object' || item.type !== 'list-item') return null;
    const p = item.props || {};
    const accessories = [];
    for (const acc of p.accessories || []) {
      if (typeof acc === 'string') accessories.push({ text: acc });
      else if (acc && typeof acc === 'object') accessories.push({ text: acc.text || '', icon: iconToString(acc.icon), tooltip: acc.tooltip });
    }
    return {
      id: p.id != null ? String(p.id) : 'item' + accessories.length + String(p.title),
      title: String(p.title || ''),
      subtitle: p.subtitle != null ? String(p.subtitle) : undefined,
      icon: iconToString(p.icon),
      keywords: Array.isArray(p.keywords) ? p.keywords.map(String) : [],
      accessories: accessories,
      actions: flattenActions(p.actions),
      onClick: p.onClick ? registerCallback(p.onClick) : undefined,
    };
  }

  // ------------------------------------------------------------------
  // @raycast/api
  // ------------------------------------------------------------------
  const api = {};
  const utils = {};

  // Components are callable factories: they work both when invoked directly,
  // List({…}, children), and as createElement types (JSX), because invoking
  // the factory simply returns the underlying host element.
  function makeComponent(name, extras) {
    const factory = function () {
      const args = Array.prototype.slice.call(arguments);
      let props = {};
      let startIdx = 0;
      if (args.length && args[0] !== null && typeof args[0] === 'object' && !Array.isArray(args[0])) {
        props = args[0];
        startIdx = 1;
      }
      const children = args.slice(startIdx);
      return React.createElement.apply(null, [name, props].concat(children));
    };
    if (extras) { for (const k of Object.keys(extras)) factory[k] = extras[k]; }
    return factory;
  }
  api.List = makeComponent('list', {
    Item: makeComponent('list-item'),
    Section: makeComponent('list-section'),
    Tag: makeComponent('list-tag'),
  });
  api.Grid = makeComponent('grid', { Item: makeComponent('grid-item') });
  api.Detail = makeComponent('detail');
  api.Markdown = makeComponent('markdown');
  api.EmptyView = makeComponent('empty-view');
  api.ActionPanel = makeComponent('action-panel', {
    Section: makeComponent('action-panel-section'),
  });
  api.Action = makeComponent('action', {
    SubmitForm: makeComponent('action-submit-form'),
    Push: makeComponent('action-push'),
    Open: makeComponent('action-open'),
    OpenInBrowser: makeComponent('action-open-in-browser'),
    CopyToClipboard: makeComponent('action-copy-to-clipboard'),
    Paste: makeComponent('action-paste'),
  });
  api.Form = makeComponent('form', {
    TextField: makeComponent('form-text-field'),
    PasswordField: makeComponent('form-password-field'),
    TextArea: makeComponent('form-text-area'),
    Checkbox: makeComponent('form-checkbox'),
    Dropdown: makeComponent('form-dropdown', { Item: makeComponent('form-dropdown-item') }),
    DatePicker: makeComponent('form-date-picker'),
    TagPicker: makeComponent('form-tag-picker'),
    Description: makeComponent('form-description'),
    Separator: makeComponent('form-separator'),
  });

  api.Icon = new Proxy({}, {
    get: function (target, prop) {
      return String(prop) + '.png';
    },
  });

  const Shortcut = {
    Enter: 'return', Space: 'space', Tab: 'tab', Backspace: 'delete',
    ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right',
    Escape: 'esc', Delete: 'delete',
    A: 'a', B: 'b', C: 'c', D: 'd', E: 'e', F: 'f', G: 'g', H: 'h', I: 'i', J: 'j',
    K: 'k', L: 'l', M: 'm', N: 'n', O: 'o', P: 'p', Q: 'q', R: 'r', S: 's', T: 't',
    U: 'u', V: 'v', W: 'w', X: 'x', Y: 'y', Z: 'z',
  };
  for (const k of Object.keys(Shortcut)) {
    Shortcut['Cmd' + (k === 'Enter' ? 'Return' : k[0].toUpperCase() + k.slice(1))] = 'cmd+' + Shortcut[k];
    Shortcut['Ctrl' + (k === 'Enter' ? 'Return' : k[0].toUpperCase() + k.slice(1))] = 'ctrl+' + Shortcut[k];
    Shortcut['Opt' + (k === 'Enter' ? 'Return' : k[0].toUpperCase() + k.slice(1))] = 'opt+' + Shortcut[k];
  }
  Shortcut['CmdEnter'] = 'cmd+return';
  Shortcut['CmdAndCtrl'] = 'cmd+ctrl';
  api.Keyboard = { Shortcut: Shortcut, KeyEquivalent: Shortcut };

  api.environment = {
    extensionName: 'extension',
    commandName: 'command',
    theme: 'dark',
    appearance: 'dark',
    launchType: 'user-initiated',
    supportsAheadOfTimeCaching: false,
    canAccessClipboard: false,
    isDevelopment: false,
    raycastVersion: '1.0.0-ultracmd',
  };

  api.LaunchType = { UserInitiated: 'user-initiated', Background: 'background' };

  api.open = function (target, options) {
    return __native.open(String(target), options && options.app ? String(options.app) : null);
  };

  api.launchCommand = function (options) {
    __native.launchCommand(options && options.name ? String(options.name) : null,
      options && options.arguments ? JSON.stringify(options.arguments) : '{}');
  };
  api.launchExtension = function () { /* multi-extension launch not needed in v1 */ };
  api.openExtensionPreferences = function () { __native.openExtensionPreferences(); };
  api.openCommandSettings = function () { __native.openExtensionPreferences(); };
  api.closeMainWindow = function () { __native.closeMainWindow(); };
  api.showHUD = function (text) { __native.showHUD(String(text)); };
  api.captureException = function (e) { console.error(String(e)); };

  api.confirmAlert = function (options) {
    options = options || {};
    return __native.confirmAlert(
      String(options.title || 'Are you sure?'),
      String(options.message || ''),
      String(options.primaryAction || options.primaryButtonTitle || 'OK'),
      String(options.dismissAction || options.cancelButtonTitle || 'Cancel')
    );
  };

  // Toasts -------------------------------------------------------------
  function Toast(handle) {
    this.id = handle.id;
    this.close = function () { __native.hideToast(handle.id); };
    this.title = handle.title || '';
    this.message = handle.message || '';
    this.style = handle.style || '';
  }

  api.showToast = function (options) {
    options = options || {};
    return new Promise(function (resolve) {
      const handle = __native.showToast(
        options.style || 'regular',
        String(options.title || ''),
        String(options.message || '')
      );
      resolve(new Toast(handle));
    });
  };
  api.Toast = { Style: { Regular: 'regular', Success: 'success', Failure: 'failure', Animated: 'animated' } };

  // Clipboard -----------------------------------------------------------
  api.Clipboard = {
    read: function () {
      return __native.clipboardRead();
    },
    readBuffer: function () { return Promise.reject(new Error('readBuffer is not supported in UltraCMD v1')); },
    write: function (content) {
      content = content || {};
      __native.clipboardWrite(String(content.text || ''), content.html ? String(content.html) : null,
        content.file ? String(content.file) : null);
      return Promise.resolve();
    },
    clear: function () { __native.clipboardWrite('', null, null); return Promise.resolve(); },
  };

  // LocalStorage ----------------------------------------------------------
  api.LocalStorage = {
    getItem: function (key) {
      const v = __native.storageGet(String(key));
      return v === null || v === undefined ? undefined : JSON.parse(v);
    },
    setItem: function (key, value) { __native.storageSet(String(key), JSON.stringify(value === undefined ? null : value)); },
    removeItem: function (key) { __native.storageRemove(String(key)); },
  };

  // updateAccessibility? Not needed. preferredEditor? Not needed.
  api.updateAccessibility = function () { return Promise.resolve(); };

  // ------------------------------------------------------------------
  // @raycast/utils
  // ------------------------------------------------------------------
  const useResolvedPromise = function (fnRef, argsRef) {
    // inner hook used by usePromise; kept separate so calls stay unconditional
    return React.useState({ isLoading: true, data: undefined, error: undefined, revalidate: null });
  };

  utils.usePromise = function (fn, args, options) {
    options = options || {};
    const stateRef = React.useRef(null);
    if (!stateRef.current) {
      stateRef.current = { isLoading: true, data: undefined, error: undefined, revalidate: null };
    }
    const renderTickState = React.useState(0);
    const force = renderTickState[1];
    const fetchTokenState = React.useState(0);
    const fetchToken = fetchTokenState[0];
    const bumpFetchToken = fetchTokenState[1];
    const argsKey = JSON.stringify(args || []);
    // Keep the latest fn without participating in dep comparison: Raycast
    // extensions pass inline closures whose identity changes every render,
    // and keying on it would refetch forever. Only args/revalidate re-run.
    const fnRef = React.useRef(fn);
    fnRef.current = fn;

    React.useEffect(function () {
      let alive = true;
      stateRef.current.isLoading = true;
      force(function (n) { return n + 1; });
      Promise.resolve()
        .then(function () { return fnRef.current.apply(null, args || []); })
        .then(function (data) {
          if (!alive) return;
          stateRef.current = { isLoading: false, data: data, error: undefined, revalidate: stateRef.current.revalidate };
          force(function (n) { return n + 1; });
        })
        .catch(function (error) {
          if (!alive) return;
          stateRef.current = { isLoading: false, data: undefined, error: error, revalidate: stateRef.current.revalidate };
          force(function (n) { return n + 1; });
        });
      return function () { alive = false; };
    }, [argsKey, fetchToken]);

    if (!stateRef.current.revalidate) {
      // revalidate bumps the effect's tick so the promise genuinely re-runs.
      stateRef.current.revalidate = function () { bumpFetchToken(function (n) { return n + 1; }); };
    }
    return stateRef.current;
  };

  utils.useBash = function (command, options) {
    options = options || {};
    return utils.usePromise(function (cmd) {
      return __native.runShell(cmd, (options.timeout || 10000));
    }, [typeof command === 'string' ? command : '']);
  };

  utils.useExec = utils.useBash;

  utils.useClipboard = function () {
    const [clip, setClip] = React.useState({ text: '', readCount: 0 });
    React.useEffect(function () {
      __native.clipboardRead().then(function (r) { setClip({ text: r.text, readCount: clip.readCount + 1 }); });
    }, []);
    return clip;
  };

  utils.useSelectedText = function () {
    const [text, setText] = React.useState(undefined);
    React.useEffect(function () {
      const t = __native.getSelectedText();
      setText(t == null ? undefined : t);
    }, []);
    return text;
  };

  utils.useFetch = function (url, init) {
    return utils.usePromise(function (u) { return fetch(u, init); }, [url]);
  };

  // ------------------------------------------------------------------
  // fetch / console / timers (bridged)
  // ------------------------------------------------------------------
  globalThis.fetch = function (input, init) {
    init = init || {};
    const url = typeof input === 'string' ? input : String(input && input.url ? input.url : input);
    const method = (init.method || (typeof input === 'object' && input && input.method) || 'GET').toUpperCase();
    let headers = {};
    if (init.headers) {
      if (typeof init.headers.forEach === 'function') {
        init.headers.forEach(function (v, k) { headers[k] = v; });
      } else { headers = init.headers; }
    } else if (typeof input === 'object' && input && input.headers) {
      headers = input.headers;
    }
    let body = init.body;
    if (body && typeof body === 'object' && !(typeof body === 'string')) {
      try { body = JSON.stringify(body); } catch (e) { body = String(body); }
    }
    return __native.fetchAsync(url, method, JSON.stringify(headers), body ? String(body) : null).then(function (res) {
      const response = {
        ok: res.status >= 200 && res.status < 300,
        status: res.status,
        statusText: res.statusText || '',
        url: url,
        headers: res.headers || {},
        text: function () { return Promise.resolve(res.body); },
        json: function () { return Promise.resolve(JSON.parse(res.body)); },
      };
      return response;
    });
  };

  globalThis.console = {
    log: function () { __native.log(Array.prototype.map.call(arguments, String).join(' ')); },
    warn: function () { __native.log('[warn] ' + Array.prototype.map.call(arguments, String).join(' ')); },
    error: function () { __native.log('[error] ' + Array.prototype.map.call(arguments, String).join(' ')); },
    info: function () { __native.log(Array.prototype.map.call(arguments, String).join(' ')); },
  };

  const timerCallbacks = new Map();
  globalThis.setTimeout = function (fn, ms) {
    const id = __native.setTimeout(Number(ms) || 0);
    timerCallbacks.set(id, fn);
    return id;
  };
  globalThis.clearTimeout = function (id) {
    timerCallbacks.delete(id);
    __native.clearTimeout(id);
  };
  globalThis.setInterval = function (fn, ms) {
    const id = __native.setInterval(Number(ms) || 1);
    timerCallbacks.set(id, fn);
    return id;
  };
  globalThis.clearInterval = function (id) {
    timerCallbacks.delete(id);
    __native.clearInterval(id);
  };

  globalThis.queueMicrotask = function (fn) { Promise.resolve().then(fn); };

  // ------------------------------------------------------------------
  // Node-ish modules for require()
  // ------------------------------------------------------------------
  const nodePath = {
    join: function () { return Array.prototype.filter.call(arguments, function (s) { return s != null && s !== ''; }).join('/').replace(/\/+/g, '/'); },
    resolve: function () { return nodePath.join.apply(null, arguments); },
    basename: function (p) { return String(p).split('/').pop(); },
    dirname: function (p) { const parts = String(p).split('/'); parts.pop(); return parts.join('/') || '/'; },
    extname: function (p) { const b = nodePath.basename(p); const i = b.lastIndexOf('.'); return i <= 0 ? '' : b.slice(i); },
    sep: '/',
  };
  const nodeFs = {
    readFileSync: function (p, enc) {
      const data = __native.readFile(String(p));
      if (data === null) {
        const e = new Error("ENOENT: no such file or directory, open '" + p + "'");
        e.code = 'ENOENT';
        throw e;
      }
      return data;
    },
    writeFileSync: function (p, data) {
      const r = __native.writeFile(String(p), String(data));
      if (!r.ok) throw new Error(r.error || 'write failed');
      return undefined;
    },
    existsSync: function (p) { return __native.fileExists(String(p)); },
    mkdirSync: function (p) { __native.mkdir(String(p)); return undefined; },
    promises: {
      readFile: function (p) { return Promise.resolve(nodeFs.readFileSync(p)); },
      writeFile: function (p, d) { nodeFs.writeFileSync(p, d); return Promise.resolve(); },
    },
  };
  const nodeOs = {
    homedir: function () { return __native.homedir(); },
    tmpdir: function () { return __native.tmpdir(); },
    platform: function () { return 'darwin'; },
    EOL: '\n',
  };
  const nodeProcess = {
    env: (function () { try { return JSON.parse(__native.getEnv()); } catch (e) { return {}; } })(),
    platform: 'darwin',
    arch: 'arm64',
    argv: ['ultracmd'],
    cwd: function () { return __native.homedir(); },
    exit: function () { __native.closeMainWindow(); },
  };
  globalThis.process = nodeProcess;

  const modules = {
    'react': React,
    'react-dom': React,
    'react-dom/server': React,
    '@raycast/api': api,
    '@raycast/utils': utils,
    'path': nodePath,
    'node:path': nodePath,
    'fs': nodeFs,
    'node:fs': nodeFs,
    'os': nodeOs,
    'node:os': nodeOs,
    'node:process': nodeProcess,
  };

  globalThis.require = function (name) {
    if (modules[name]) return modules[name];
    throw new Error("Module '" + name + "' is not available in the UltraCMD extension runtime");
  };

  // ------------------------------------------------------------------
  // Event dispatch (native -> shim)
  // ------------------------------------------------------------------
  globalThis.__dispatch = function (event, a, b) {
    try {
      if (event === 'perform') {
        return invoke(a, b);
      }
      if (event === 'query') {
        if (activeDescriptor && activeDescriptor.onSearchTextChange) invoke(activeDescriptor.onSearchTextChange, a);
        return;
      }
      if (event === 'selection') {
        if (activeDescriptor && activeDescriptor.onSelectionChange) invoke(activeDescriptor.onSelectionChange, a);
        return;
      }
      if (event === 'submitForm') {
        const values = JSON.parse(a || '{}');
        const actions = (activeDescriptor && activeDescriptor.actions) || [];
        for (const action of actions) {
          if (action.submitForm) return invoke(action.id, values);
        }
        if (actions.length) return invoke(actions[0].id, values);
        return;
      }
      if (event === 'timer') {
        const fn = timerCallbacks.get(a);
        if (fn) fn();
        return;
      }
    } catch (e) {
      if (errorHookRef) errorHookRef(String(e && e.stack || e));
    }
  };

  let activeDescriptor = null;
  let errorHookRef = null;

  // ------------------------------------------------------------------
  // Boot: called by Swift after the user script has been evaluated.
  // ------------------------------------------------------------------
  function boot(optionsJson) {
    const options = JSON.parse(optionsJson || '{}');
    api.environment.extensionName = options.extensionName || 'extension';
    api.environment.commandName = options.commandName || 'command';
    api.environment.isDevelopment = !!options.isDevelopment;

    const exportsObj = globalThis.__moduleExports || {};
    const component = exportsObj.default;

    React.__setRenderHook(function (descriptor) {
      activeDescriptor = descriptor;
      __native.render(JSON.stringify(descriptor));
      React.__flushEffects();
    });
    React.__setErrorHook(function (message) {
      if (errorHookRef) errorHookRef(message);
      else __native.log('[render error] ' + message);
    });
    errorHookRef = function (message) {
      __native.log('[extension error] ' + message);
      activeDescriptor = {
        view: 'detail',
        markdown: '### Extension error\n\n```\n' + String(message).substring(0, 2000) + '\n```',
        actions: [],
      };
      __native.render(JSON.stringify(activeDescriptor));
    };

    if (typeof component === 'function') {
      React.__mount(component, {});
    } else if (typeof exportsObj.main === 'function') {
      // Background-style command.
      Promise.resolve()
        .then(function () { return exportsObj.main({ arguments: {}, environment: api.environment }); })
        .then(function () { __native.closeMainWindow(); })
        .catch(function (e) { errorHookRef(String(e && e.stack || e)); });
      activeDescriptor = {
        view: 'detail',
        markdown: 'Running…',
        actions: [],
      };
      __native.render(JSON.stringify(activeDescriptor));
    } else {
      errorHookRef('Extension must export default a component or a main() function');
    }
  }

  globalThis.__ultracmdBoot = boot;

  return {
    React: React,
    api: api,
    utils: utils,
    boot: boot,
  };
})();
