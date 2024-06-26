import '../style.css';
import { bus } from './event';
import { render, h, Component } from '../node_modules/preact/src/index.js';
import { GameScore, GameLogs, GameHelp } from './components';
import { nrToCell, nrToStat, nrToLog } from './convert';
import { throttle } from 'throttle-debounce';

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

function titleCase(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

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

  //-// DEBUG
  // window.wasmMemory = exports.memory;
  // window.wasmGetViewOffset = exports.getViewOffset;
  // window.wasmInspectAt = exports.inspectAt;

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
  for (let i = 0; i < 75; i++) {
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

  // X,Y offset of the view, relative to the map
  const viewOffset = new Int16Array(memory.buffer, exports.getViewOffset(), 2);
  // The result of the inspect function [id,nr]
  const inspectArr = new Uint16Array(memory.buffer, exports.inspectAt(0), 2);

  let wasmMemorySz = memory.buffer.byteLength / (1024 * 1024);
  console.log('WASM memory MB:', wasmMemorySz);

  function ModalWrap(props) {
    let inner = null;
    let className = null;
    if (props.stage === 'intro') {
      inner = [
        h('b', {}, 'Chasing Butterflies'),
        h('br'),
        h('br'),
        'Press [Enter] or [Space] to start!',
        h('br'),
        h('br'),
        `It's your sister's birthday and you want to find the perfect gift`,
        h('br'),
        h('br'),
        `It's not that easy...`,
        h('br'),
        h('br'),
        `You think long and hard and...`,
        h('br'),
        `decide to catch all the butterflies in the garden`,
        h('br'),
        h('br'),
        `You hope she'll appreciate the gift`,
      ];
      className = 'open';
    } else if (props.stage === 'won') {
      const time1 = props.foundNet
        ? Math.round((props.foundNet.getTime() - props.startTime.getTime()) / 60000)
        : false;
      const time2 = Math.round((new Date().getTime() - props.startTime.getTime()) / 60000);
      inner = [
        'You caught all the butterflies!',
        h('br'),
        h('br'),
        time1 ? `You found the butterfly net in ${time1} minutes` : '',
        h('br'),
        h('br'),
        `You finished the game in ${props.turns} turns and ${time2} minutes`,
        h('br'),
        h('br'),
        'A Chasing Butterflies Game - made by Cristi Constantin',
      ];
      className = 'open';
    }
    return h('div', { id: 'modalWrap', className }, inner);
  }

  class GameGrid extends Component {
    onMouseOver(ev) {
      const tgt = ev.target;
      tgt.classList.add('selected');
      const x = viewOffset[0] + parseInt(tgt.dataset.x);
      const y = viewOffset[1] + parseInt(tgt.dataset.y);
      if (tgt.innerText === '@') {
        tgt.title = `Player @ ${x}x${y}`;
        return;
      }
      exports.inspectAt(x + y * mapWidth);
      const [id, nr] = inspectArr;
      let { cls } = nrToCell(nr);
      cls = titleCase(cls);
      if (id) tgt.title = `${cls} #${id} @ ${x}x${y}`;
      else tgt.title = `${cls} @ ${x}x${y}`;
    }

    onMouseLeave(ev) {
      ev.target.classList.remove('selected');
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
            title: titleCase(cell.cls),
            onmouseover: this.onMouseOver,
            onmouseleave: this.onMouseLeave,
            'data-x': c,
            'data-y': r,
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
    state = { stage: 'intro', turns: 0, startTime: new Date(), foundNet: null, auto: false };

    onKeyPressed = throttle(
      50,
      (ev) => {
        // large switch to handle user input
        let ok = false;
        if (this.state.stage === 'won') {
          return;
        }
        if (this.state.stage === 'intro') {
          if (ev.key === 'Escape' || ev.key === 'Enter' || ev.key === ' ') {
            this.setState({ stage: null });
          }
          return;
        }
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

    checkStatus = (k) => {
      if (k === 'foundNet') {
        this.state.foundNet = new Date();
      } else if (k === 'gameWon') {
        this.setState({ stage: 'won' });
      }
    };

    componentDidMount() {
      document.addEventListener('keydown', this.onKeyPressed);
      bus.on('stat:event', this.checkStatus);
    }
    componentWillUnmount() {
      document.removeEventListener('keydown', this.onKeyPressed);
      bus.off('stat:event', this.checkStatus);
    }

    render() {
      return [ModalWrap(this.state), h(GameGrid), h(GameScore), h(GameLogs), h(GameHelp)];
    }
  }

  render(h(App), document.body);
})();
