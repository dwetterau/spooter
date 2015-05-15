// Generated by CoffeeScript 1.8.0
(function() {
  var Game,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Game = (function() {
    var LOOP_TIME_INTERVAL;

    function Game() {
      this.loop = __bind(this.loop, this);
      this.doPhysics = __bind(this.doPhysics, this);
      this.movePlayer = __bind(this.movePlayer, this);
      this.broadcastState = __bind(this.broadcastState, this);
      this.deletePlayer = __bind(this.deletePlayer, this);
      this.handleMove = __bind(this.handleMove, this);
      this.worldWidth = 4000;
      this.worldHeight = 4000;
      this.players = {};
      this.nextPlayerId = 0;
      this.enemies = {};
      this.bullets = {};
      this.io = null;
    }

    Game.prototype.start = function(io) {
      console.log("Game server started!");
      this.io = io;
      io.on('connection', (function(_this) {
        return function(socket) {
          return _this.initializeConnection(socket);
        };
      })(this));
      return this.loop();
    };

    Game.prototype.initializeConnection = function(socket) {
      var newPlayerId;
      newPlayerId = this.nextPlayerId++;
      this.createPlayer(newPlayerId);
      socket.on("move", this.handleMove);
      socket.on("disconnect", (function(_this) {
        return function() {
          console.log("Player disconnected!", newPlayerId);
          return _this.deletePlayer(newPlayerId);
        };
      })(this));
      return socket.emit('initialize', {
        playerId: newPlayerId
      });
    };

    Game.prototype.handleMove = function(message) {
      var mouseX, mouseY, player, playerId;
      if ((message == null) || (message.playerId == null)) {
        return;
      }
      mouseX = message.mouseX, mouseY = message.mouseY, playerId = message.playerId;
      if ((mouseX == null) || (mouseY == null)) {
        return;
      }
      player = this.players[playerId];
      player.mouseX = mouseX;
      return player.mouseY = mouseY;
    };

    Game.prototype.createPlayer = function(playerId) {
      var x, y;
      x = Math.random() * this.worldWidth;
      y = Math.random() * this.worldHeight;
      return this.players[playerId] = {
        type: 'player',
        id: playerId,
        r: 20,
        x: x,
        y: y,
        vx: 0,
        vy: 0,
        mouseX: x,
        mouseY: y
      };
    };

    Game.prototype.deletePlayer = function(playerId) {
      if (playerId in this.players) {
        return delete this.players[playerId];
      }
    };

    Game.prototype.broadcastState = function() {
      var bullet, enemy, entities, id, player, state, _ref, _ref1, _ref2;
      entities = [];
      _ref = this.enemies;
      for (id in _ref) {
        enemy = _ref[id];
        entities.push(enemy);
      }
      _ref1 = this.players;
      for (id in _ref1) {
        player = _ref1[id];
        entities.push(player);
      }
      _ref2 = this.bullets;
      for (id in _ref2) {
        bullet = _ref2[id];
        entities.push(bullet);
      }
      state = {
        worldWidth: this.worldWidth,
        worldHeight: this.worldHeight,
        entities: entities
      };
      return this.io.sockets.emit('state', state);
    };

    Game.prototype.movePlayer = function(player, dt) {
      var ax, ay, clampedX, clampedY;
      ax = player.mouseX - player.x;
      ay = player.mouseY - player.y;
      player.vx += dt * ax;
      player.vy += dt * ay;
      player.x += dt * player.vx;
      player.y += dt * player.vy;
      clampedX = false;
      clampedY = false;
      if (player.x - player.r < 0) {
        clampedX = true;
        player.x = player.r;
      }
      if (player.x + player.r > this.worldWidth) {
        clampedX = true;
        player.x = this.worldWidth - player.r;
      }
      if (player.y - player.r < 0) {
        clampedY = true;
        player.y = player.r;
      }
      if (player.y + player.r > this.worldHeight) {
        clampedY = true;
        player.y = this.worldHeight - player.r;
      }
      if (clampedX) {
        player.vx = 0;
      }
      if (clampedY) {
        player.vy = 0;
      }
      return player;
    };

    Game.prototype.doPhysics = function(dt) {
      var id, player, _ref, _results;
      _ref = this.players;
      _results = [];
      for (id in _ref) {
        player = _ref[id];
        _results.push(this.players[id] = this.movePlayer(player, dt));
      }
      return _results;
    };

    LOOP_TIME_INTERVAL = 10;

    Game.prototype.loop = function() {
      var diff, startTime;
      startTime = new Date().getTime();
      this.doPhysics(LOOP_TIME_INTERVAL / 1000.0);
      this.broadcastState();
      diff = LOOP_TIME_INTERVAL - ((new Date().getTime()) - startTime);
      if (diff < 0) {
        console.log("WARNING: Game loop computation too slow!");
        diff = 0;
      }
      return setTimeout(this.loop, diff);
    };

    return Game;

  })();

  module.exports = Game;

}).call(this);

//# sourceMappingURL=index.js.map
