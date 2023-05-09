export function nrToCell(nr) {
  let ch = String.fromCharCode(nr);
  // all numbers should be ASCII,
  // if they're not, it's an error and I want to see it
  if (nr > 250 || nr < 10) {
    console.error(`Received invalid CH: ${nr} = ${ch}!`);
  }
  let cls = '';
  switch (ch) {
    case '@':
      cls = 'player';
      break;
    case "'":
    case '"':
    case ':':
      cls = 'grass';
      if (ch === ':') ch = '⋎';
      cls = 'grass';
      break;
    case '0':
      ch = '✲';
      cls = 'blue flower';
      break;
    case 'o':
      ch = '✲';
      cls = 'red flower';
      break;
    case 'O':
      ch = '✲';
      cls = 'yellow flower';
      break;
    case '.':
      ch = '‥';
      cls = 'stone';
      break;
    case '#':
      cls = 'wall';
      break;
    case 'A':
      ch = '❵❴';
      cls = 'silver butterfly';
      break;
    case 'B':
      ch = '❵❴';
      cls = 'blue butterfly';
      break;
    case 'C':
      ch = '❵❴';
      cls = 'green butterfly';
      break;
    case 'D':
      ch = '❵❴';
      cls = 'red butterfly';
      break;
    case 'E':
      ch = '❵❴';
      cls = 'elusive butterfly';
      break;
    case 'X':
      ch = '▣';
      cls = 'chest';
      break;
    case 'x':
      ch = '▨';
      cls = 'chest';
      break;
    default:
      ch = "'";
      cls = 'grass';
  }
  return { ch, cls };
}

function _nrToButterfly(nr) {
  let name = 'gray';
  switch (nr) {
    case 11:
    case 21:
      name = 'blue';
      break;
    case 12:
    case 22:
      name = 'green';
      break;
    case 13:
    case 23:
      name = 'red';
      break;
    case 14:
    case 24:
      name = 'elusive';
      break;
  }
  return name;
}

export function nrToStat(nr) {
  // (nr === 2) // ignore
  if (nr === 1) {
    return 'foundNet';
  }
  // (nr >= 10 && nr <= 14) // ignore
  if (nr >= 20 && nr <= 24) {
    return _nrToButterfly(nr);
  }
}

export function nrToLog(nr) {
  if (nr === 1) {
    return 'You find a butterfly net!';
  }
  if (nr === 2) {
    return 'The chest is empty.';
  }
  if ((nr >= 10 && nr <= 14) || (nr >= 20 && nr <= 24)) {
    const name = _nrToButterfly(nr);
    let msg = '';
    if (nr < 20) {
      const x = Math.random();
      if (x < 0.2)
        msg = `The quick ${name} butterfly slips through your fingers, leaving only a fleeting trace of its delicate touch.`;
      else if (x < 0.4)
        msg = `You strive to capture the ethereal beauty of a ${name} butterfly, but it eludes your grasp.`;
      else if (x < 0.6) msg = `You brush empty air, as the ${name} butterfly flutters beyond your reach.`;
      else if (x < 0.8) msg = `You fail to catch the delicate ${name} butterfly...`;
      else msg = `Despite your best efforts, you miss the ${name} butterfly...`;
    } else {
      msg = `You catch the ${name} butterfly!`;
    }
    return msg;
  }
  console.error(`Unknown event: ${nr}!`);
}
