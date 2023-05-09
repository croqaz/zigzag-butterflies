import '../style.css';
import { nrToCell, nrToStat, nrToLog } from './convert';
import { render, h, Component } from 'preact';
import { throttle } from 'throttle-debounce';
import Nanobus from 'nanobus';
const bus = Nanobus();

const FG_COLOR = '#111';
const COLORS = {
  '#': '#575a3f',
  '.': '#535155',
  "'": '#77d051',
  '"': '#239725',
  ':': '#2d9f62',
  'o': '#ed6294',
  'O': '#90c1f9',
  '0': '#f3e744',
};

let memory = null;
let consoleLogBuffer = '';
const txtDecoder = new TextDecoder();

const importObject = {
  env: {
    gameEvent: function (ev) {
      let x = nrToLog(ev);
      if (x) bus.emit('log:event', x);
      x = nrToStat(ev);
      if (x) bus.emit('stat:event', x);
    },
    consoleLog: function (ptr, len) {
      consoleLogBuffer += txtDecoder.decode(new Uint8Array(memory.buffer, ptr, len));
    },
    consoleFlush: function () {
      console.log(consoleLogBuffer);
      consoleLogBuffer = '';
    },
  },
};

(async function main() {
  const module = await WebAssembly.compileStreaming(fetch('main.wasm'));
  const { exports } = await WebAssembly.instantiate(module, importObject);
  const { turn } = exports;
  memory = exports.memory;

  const mapWidth = new Uint8Array(memory.buffer, exports.mapWidth.value, 1)[0];
  const mapHeight = new Uint8Array(memory.buffer, exports.mapHeight.value, 1)[0];
  console.log(`Map size: ${mapWidth}x${mapHeight}`);

  const viewWidth = new Uint8Array(memory.buffer, exports.viewWidth.value, 1)[0];
  const viewHeight = new Uint8Array(memory.buffer, exports.viewHeight.value, 1)[0];
  console.log(`View size: ${viewWidth}x${viewHeight}`);

  // game map grid
  // hopefully this doesn't push the pointer in memory after the game is initialized
  let bufferOffset = exports.getMapPointer();
  const areaTiles = new Uint16Array(memory.buffer, bufferOffset, mapWidth * mapHeight);

  for (let i = 0; i < 100; i++) {
    const x = Math.random() * mapWidth - 1;
    const y = Math.random() * mapHeight - 1;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = '.'.charCodeAt(0);
  }
  for (let i = 0; i < 200; i++) {
    const x = Math.random() * mapWidth - 1;
    const y = Math.random() * mapHeight - 1;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = '"'.charCodeAt(0);
  }
  for (let i = 0; i < 100; i++) {
    const x = Math.random() * mapWidth - 1;
    const y = Math.random() * mapHeight - 1;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = ':'.charCodeAt(0);
  }
  for (let i = 0; i < 150; i++) {
    const x = Math.random() * mapWidth - 1;
    const y = Math.random() * mapHeight - 1;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = 'o'.charCodeAt(0);
  }
  for (let i = 0; i < 50; i++) {
    const x = 10 + Math.random() * mapWidth - 20;
    const y = 20 + Math.random() * mapHeight - 20;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = 'O'.charCodeAt(0);
  }
  for (let i = 0; i < 50; i++) {
    const x = 10 + Math.random() * mapWidth - 20;
    const y = 20 + Math.random() * mapHeight - 20;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = '0'.charCodeAt(0);
  }
  for (let i = 0; i < 50; i++) {
    const x = 10 + Math.random() * mapWidth - 20;
    const y = 20 + Math.random() * mapHeight - 20;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = '#'.charCodeAt(0);
  }

  // seed for random maps and creatures (U32)
  const seed = Math.round((new Date() * Math.random()) / 1000);
  console.log('Random seed:', seed);
  // important! init the game!
  exports.init(seed);

  // flat rendered grid
  // this can only be called after the game was initialized
  bufferOffset = exports.getViewPointer();
  const flatTiles = new Uint16Array(memory.buffer, bufferOffset, viewWidth * viewHeight);
  bufferOffset = null;

  let wasmMemorySz = memory.buffer.byteLength / (1024 * 1024);
  console.log('WASM memory MB:', wasmMemorySz);

  class GameScore extends Component {
    state = { foundNet: 0, gray: 0, blue: 0, green: 0, red: 0, elusive: 0 };

    onUpdate = (k) => {
      console.log('State:', k);
      const s = this.state;
      s[k]++;
      this.setState(s);
    };

    componentDidMount() {
      bus.on('stat:event', this.onUpdate);
    }

    componentWillUnmount() {
      bus.off('stat:event', this.onUpdate);
    }

    render() {
      const score = [];
      if (this.state.foundNet) {
        score.push(h('h3', {}, 'You are holding'));
        score.push(h('p', {}, 'a butterfly net'));
      }
      const butterflies = [h('h3', {}, 'Butterflies')];
      for (const k of Object.keys(this.state)) {
        if (k === 'foundNet') continue;
        if (this.state[k]) {
          butterflies.push(h('p', {}, `${k}: ${this.state[k]}`));
        }
      } if (butterflies.length === 1) {
        butterflies.push(h('p', {}, 'None'));
      }
      score.push(butterflies);
      return h('div', { id: 'score' }, score);
    }
  }

  class GameLogs extends Component {
    state = { logs: ['Catch all the butterflies!'] };

    onLogMsg = (msg) => {
      const logs = this.state.logs.concat(msg);
      // trim old log messages
      while (logs.length > 99) logs.shift();
      this.setState({ logs });
    };

    componentDidMount() {
      bus.on('log:event', this.onLogMsg);
    }

    componentWillUnmount() {
      bus.off('log:event', this.onLogMsg);
    }

    componentDidUpdate() {
      // Jump scroll
      const container = document.getElementById('logs');
      container.scrollTop = container.scrollHeight;
    }

    render() {
      const logMsg = (msg) => h('p', {}, msg);
      return h('div', { id: 'logs' }, [h('span', {}, this.state.logs.map(logMsg))]);
    }
  }

  class GameGrid extends Component {
    state = { turns: 0, auto: false };

    onKeyPressed = throttle(
      50,
      (ev) => {
        // large switch to handle user input
        let ok = false;
        if (ev.shiftKey && ev.key === ' ') {
          // wait until stopped
          if (this.state.auto) {
            clearInterval(this.state.auto);
            this.setState({ auto: false });
          } else {
            const i = setInterval(() => {
              ok = turn(-1);
              if (ok) this.setState({ turns: this.state.turns + 1 });
            }, 100);
            this.setState({ auto: i });
          }
          return;
        } else if (ev.key === ' ') {
          if (this.state.auto) {
            clearInterval(this.state.auto);
            this.setState({ auto: false });
          }
          // wait 1 turn without moving
          ok = turn(-1);
        } else if (ev.key === 'ArrowUp' || ev.key === 'w' || ev.key === 'W') {
          // try to move Nord, up
          ok = turn(0);
        } else if (ev.key === 'ArrowDown' || ev.key === 's' || ev.key === 'S') {
          // try to move South, down
          ok = turn(1);
        } else if (ev.key === 'ArrowRight' || ev.key === 'd' || ev.key === 'D') {
          ok = turn(2);
        } else if (ev.key === 'ArrowLeft' || ev.key === 'a' || ev.key === 'A') {
          ok = turn(3);
        }
        if (ok) this.setState({ turns: this.state.turns + 1 });
      },
      { noTrailing: true },
    );

    onMouseOver = (ev) => {
      ev.target.classList.add('selected');
    };

    onMouseLeave = (ev) => {
      ev.target.classList.remove('selected');
    };

    componentDidMount() {
      document.addEventListener('keydown', this.onKeyPressed);
    }

    componentWillUnmount() {
      document.removeEventListener('keydown', this.onKeyPressed);
    }

    render() {
      const grid = [];
      // convert the flat grid to a 2D array
      for (let r = 0; r < viewHeight; r++) {
        const row = [];
        for (let c = 0; c < viewWidth; c++) {
          const i = c + r * viewWidth;
          row.push(flatTiles[i]);
        }
        grid.push(row);
      }

      const gridCol = (nr, c, r) => {
        const cell = nrToCell(nr);
        return h(
          'td',
          {
            key: `x-${r + 1}-${c + 1}`,
            onMouseOver: this.onMouseOver,
            onMouseLeave: this.onMouseLeave,
            classList: cell.cls,
          },
          cell.ch,
        );
      };
      const gridRow = (row, r) =>
        h(
          'tr',
          { key: `"y-${r + 1}` },
          row.map((cell, c) => gridCol(cell, c, r)),
        );
      return h('table', { id: 'game', tabIndex: 0 }, grid.map(gridRow));
    }
  }

  class App extends Component {
    render() {
      return [h(GameGrid), h(GameScore), h(GameLogs)];
    }
  }

  render(h(App, null), document.body);
})();
