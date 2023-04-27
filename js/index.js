import '../style.css';
import { render, h, Component } from 'preact';

(async function main() {

  class GameGrid extends Component {
    state = { turns: 0 };

    onKeyPressed = throttle(
      10,
      (ev) => {
        let ok = true;
        if (ev.key === 'w') {
          // try to move Nord, up
          // ok = turn(0);
        } else if (ev.key === 's') {
          // try to move South, down
          // ok = turn(1);
        } else if (ev.key === 'd') {
          // ok = turn(2);
        } else if (ev.key === 'a') {
          // ok = turn(3);
        } else {
          ok = false;
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
      const gridCol = (nr, c, r) => {
        let ch = '.';
        return h(
          'td',
          {
            key: `x-${r + 1}${c + 1}`,
            onMouseOver: this.onMouseOver,
            onMouseLeave: this.onMouseLeave,
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
