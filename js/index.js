import '../style.css';
import { render, h, Component } from 'preact';
import { throttle } from 'throttle-debounce';

const FG_COLOR = '#111';
const COLORS = {
  '#': '#b7ba9d',
  "'": '#77d051',
  '"': '#239725',
  '.': '#535155',
  ':': '#2d9f62',
  'o': '#ed6294',
  '0': '#e5e052',
};

function nrToChar(nr) {
  // all numbers should be ASCII,
  // if they're not, it's an error and I want to see it
  // if (nr > 250 || nr < 10) !!!
  let ch = String.fromCharCode(nr);
  if (!ch.trim()) ch = "'";
  else if (ch === 'B') ch = '🦋';
  else if (ch === 'X') ch = '▣';
  else if (ch === 'x') ch = '▨';
  return ch;
}

let memory = null;
let consoleLogBuffer = '';
const txtDecoder = new TextDecoder();

const importObject = {
  env: {
    gameLog: function (ptr, len) {
      console.log( txtDecoder.decode(new Uint8Array(memory.buffer, ptr, len)) );
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
  console.log(`View size: ${viewWidth}x${viewWidth}`);

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
  for (let i = 0; i < 100; i++) {
    const x = Math.random() * mapWidth - 1;
    const y = Math.random() * mapHeight - 1;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = ':'.charCodeAt(0);
  }
  for (let i = 0; i < 100; i++) {
    const x = Math.random() * mapWidth - 1;
    const y = Math.random() * mapHeight - 1;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = 'o'.charCodeAt(0);
  }
  for (let i = 0; i < 100; i++) {
    const x = Math.random() * mapWidth - 1;
    const y = Math.random() * mapHeight - 1;
    const z = Math.round(x + y * mapWidth);
    areaTiles[z] = '0'.charCodeAt(0);
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

  class GameGrid extends Component {
    state = { turns: 0 };

    onKeyPressed = throttle(
      10,
      (ev) => {
        let ok = false;
        if (ev.key === ' ') {
          // wait 1 turn without moving
          ok = turn(-1);
        } else if (ev.key === 'w') {
          // try to move Nord, up
          ok = turn(0);
        } else if (ev.key === 's') {
          // try to move South, down
          ok = turn(1);
        } else if (ev.key === 'd') {
          ok = turn(2);
        } else if (ev.key === 'a') {
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
      this.removeEventListener('keydown', this.onKeyPressed);
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
        const ch = nrToChar(nr);
        const color = COLORS[ch] ? COLORS[ch] : FG_COLOR;
        return h(
          'td',
          {
            key: `x-${r + 1}-${c + 1}`,
            onMouseOver: this.onMouseOver,
            onMouseLeave: this.onMouseLeave,
            style: { color },
          },
          ch,
        );
      };
      const gridRow = (row, r) =>
        h(
          'tr',
          { key: `"y-${r + 1}` },
          row.map((cell, c) => gridCol(cell, c, r)),
        );
      return h('table', { id: 'gameGrid' }, grid.map(gridRow));
    }
  }

  class App extends Component {
    render() {
      return h('main', { id: 'app', tabIndex: 0 }, h(GameGrid, { props: this.state }));
    }
  }

  render(h(App, null), document.body);
})();
