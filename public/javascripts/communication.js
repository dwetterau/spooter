// Generated by CoffeeScript 1.8.0
(function() {
  var clearState, getPlayerId, move, setState, shoot, socket;

  socket = io('http://localhost:3001');

  socket.on('initialize', function(data) {
    var playerId;
    playerId = data.playerId;
    return clearState(playerId);
  });

  socket.on('state', function(data) {
    return setState(data);
  });

  move = function(mouseX, mouseY) {
    var playerId;
    playerId = getPlayerId();
    return socket.emit("move", {
      playerId: playerId,
      mouseX: mouseX,
      mouseY: mouseY
    });
  };

  shoot = function() {
    console.log("Shooting");
    return socket.emit("shoot", {});
  };

  getPlayerId = function() {
    return window.spooter.playerId;
  };

  clearState = function(playerId) {
    window.spooter.state = {};
    window.spooter.playerId = playerId;
    return window.spooter.initialized = false;
  };

  setState = function(newState) {
    window.spooter.state = newState;
    return window.spooter.initialized = true;
  };

  window.spooter = {
    initialized: false,
    move: move,
    shoot: shoot,
    state: {}
  };

}).call(this);

//# sourceMappingURL=communication.js.map
