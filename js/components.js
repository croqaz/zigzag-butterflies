import { bus } from './event';
import { h, Component } from '../node_modules/preact/src/index.js';

export class GameScore extends Component {
  state = {
    foundNet: false,
    foundTime: null,
    butterflies: { gray: 0, blue: 0, green: 0, red: 0, elusive: 0 },
  };

  onUpdate = (k) => {
    const s = this.state;
    if (k === 'foundNet') {
      s.foundNet = true;
      s.foundTime = new Date();
    } else s.butterflies[k] += 1;
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
    const { butterflies } = this.state;
    const renderedButterflies = [h('h3', {}, 'Butterflies')];
    for (const k of Object.keys(butterflies)) {
      if (butterflies[k]) {
        renderedButterflies.push(h('p', {}, `${k}: ${butterflies[k]}`));
      }
    }
    if (renderedButterflies.length === 1) {
      renderedButterflies.push(h('p', {}, 'None'));
    }
    score.push(renderedButterflies);
    return h('div', { id: 'score' }, score);
  }
}

export class GameLogs extends Component {
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

export class GameHelp extends Component {
  render() {
    return h('div', { id: 'help' }, [
      h('h3', null, 'A Chasing Butterflies Game'),
      h('br'),
      h('strong', null, 'Movement'),
      h('ul', null, [h('li', null, 'w,a,s,d keys'), h('li', null, 'arrow keys')]),
      h('strong', null, 'Waiting'),
      h('ul', null, [h('li', null, 'space key')]),
      h('footer', { id: 'copyright' }, '(C) Cristi Constantin 2020-2023'),
    ]);
  }
}
