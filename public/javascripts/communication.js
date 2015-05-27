// Generated by CoffeeScript 1.8.0
(function() {
  var getPlayerId, getStatesToInterpolate, incrStateBufferIndex, initialize, lastStateReceivedTime, move, nextState, numStateUpdates, serializer, setState, shoot, socket, totalStateTime, _getStateAtIndex, _setStateAtIndex;

  socket = io('http://localhost:3001');

  socket.on('initialize', function(data) {
    console.log("initializing...");
    return initialize(data);
  });

  serializer = null;

  socket.on('state', function(data) {
    if (serializer) {
      return setState(serializer.toObject(data, nextState(true)));
    } else {
      if (window.spooter.StateSerializer != null) {
        return serializer = new window.spooter.StateSerializer();
      }
    }
  });

  _setStateAtIndex = function(index, object) {
    return window.spooter.states[index] = object;
  };

  _getStateAtIndex = function(index) {
    var state;
    state = window.spooter.states[index];
    if (state == null) {
      return null;
    }
    return state;
  };

  nextState = function(create) {
    var index, state;
    index = (window.spooter.stateBufferIndex + 1) % window.spooter.STATE_BUFFER_SIZE;
    state = _getStateAtIndex(index);
    if (!state) {
      _setStateAtIndex(index, {});
      return _getStateAtIndex(index);
    }
    return state;
  };

  getStatesToInterpolate = function(time) {
    var index, leftIndex, rightIndex, t, _i, _len, _ref;
    leftIndex = null;
    _ref = window.spooter.stateTimes;
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      t = _ref[index];
      if (t <= time && window.spooter.stateTimes[(index + 1) % window.spooter.STATE_BUFFER_SIZE] >= time) {
        leftIndex = index;
        break;
      }
    }
    if (leftIndex === null) {
      return null;
    }
    rightIndex = (leftIndex + 1) % window.spooter.STATE_BUFFER_SIZE;
    return {
      leftState: _getStateAtIndex(leftIndex),
      rightState: _getStateAtIndex(rightIndex),
      leftTime: window.spooter.stateTimes[leftIndex],
      rightTime: window.spooter.stateTimes[rightIndex]
    };
  };

  incrStateBufferIndex = function() {
    window.spooter.stateBufferIndex++;
    return window.spooter.stateBufferIndex %= window.spooter.STATE_BUFFER_SIZE;
  };

  move = function(ax, ay) {
    var angle, buffer, byteView, playerId;
    playerId = getPlayerId();
    angle = -Math.atan2(ay, ax);
    if (angle < 0) {
      angle += Math.PI * 2;
    }
    angle = Math.round(angle / ((2 * Math.PI) / 255));
    buffer = new ArrayBuffer(2);
    byteView = new Uint8Array(buffer);
    byteView[0] = playerId;
    byteView[1] = angle;
    return socket.emit("move", buffer);
  };

  shoot = function() {
    var playerId;
    playerId = getPlayerId();
    return socket.emit("shoot", {
      playerId: playerId
    });
  };

  getPlayerId = function() {
    return window.spooter.playerId;
  };

  initialize = function(data) {
    var playerId, worldHeight, worldWidth;
    worldHeight = data.worldHeight, worldWidth = data.worldWidth, playerId = data.playerId;
    window.spooter.STATE_BUFFER_SIZE = 8;
    window.spooter.states = new Array(window.spooter.STATE_BUFFER_SIZE);
    window.spooter.stateTimes = new Array(window.spooter.STATE_BUFFER_SIZE);
    window.spooter.stateBufferIndex = -1;
    window.spooter.stateStartTime = null;
    window.spooter.playerId = playerId;
    window.spooter.worldHeight = worldHeight;
    window.spooter.worldWidth = worldWidth;
    window.spooter.move = move;
    window.spooter.shoot = shoot;
    window.spooter.getStatesToInterpolate = getStatesToInterpolate;
    return window.spooter.initialized = false;
  };

  lastStateReceivedTime = 0;

  totalStateTime = 0;

  numStateUpdates = 0.0;

  setState = function(newState) {
    var now, time;
    now = new Date().getTime();
    if (lastStateReceivedTime !== 0) {
      time = now - lastStateReceivedTime;
      totalStateTime += time;
      numStateUpdates++;
      if (Math.random() < .001) {
        console.log("Average state update interval", totalStateTime / numStateUpdates);
      }
    }
    lastStateReceivedTime = now;
    incrStateBufferIndex();
    now = new Date().getTime();
    if (window.spooter.stateStartTime === null) {
      window.spooter.stateStartTime = now;
    }
    window.spooter.stateTimes[window.spooter.stateBufferIndex] = now - window.spooter.stateStartTime;
    return window.spooter.initialized = true;
  };

  window.spooter = {};

}).call(this);

//# sourceMappingURL=communication.js.map
