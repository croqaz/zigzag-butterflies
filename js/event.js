import { createNanoEvents } from 'nanoevents';
export const bus = createNanoEvents();
bus.off = function (event, cb) {
  if (cb) this.events[event] = this.events[event]?.filter((i) => cb !== i);
  else this.events[event] = [];
};
