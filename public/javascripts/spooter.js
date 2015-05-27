// important stuff
var lastms = 0;

var canvas = document.getElementById("spooterCanvas");
var ctx = canvas.getContext("2d");

var viewportX = 0;
var viewportY = 0;

// input
var mouseX = -1;
var mouseY = -1;
var lastAx = 0;
var lastAy = 0;
var clicked;

// The amount in milliseconds clients are forced to be behind
// Three state updates + 3 frames
var FORCED_DELAY = 200;

window.addEventListener('resize', resizeCanvas, false);

function resizeCanvas() {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
}

canvas.addEventListener('mousemove', function(evt) {
  var rect = canvas.getBoundingClientRect();
  var root = document.documentElement;

  mouseX = evt.clientX - rect.left - root.scrollLeft;
  mouseY = evt.clientY - rect.top - root.scrollTop;
}, false);

canvas.addEventListener('click', function(evt) {
  clicked = true;
  window.spooter.shoot();
}, false);

function getState() {
  if (interpolatedState) {
      return interpolatedState;
  }
  if (window.spooter.states == undefined ||
      window.spooter.stateBufferIndex == undefined) {
    return null;
  }
  var index = window.spooter.stateBufferIndex;
  if (window.spooter.states[index] != undefined) {
    return window.spooter.states[index]
  }
  return null;
}

function getPlayer() {
  var state = getState();
  if (!state) {
    return null;
  }
  var i = 0;
  for (i = 0; i < state.numEntities; i++) {
    var entity = state.entities[i];
    if (window.spooter.playerId == entity.id && entity.type == 'player') {
      return entity;
    }
  }
  return null;
}

function pollMouse() {
  if (mouseX >= 0 && mouseY >= 0) {
    var p = getPlayer();
    if (p) {
      ax = viewportX + mouseX - p.x;
      ay = viewportY + mouseY - p.y;

      if (ax != lastAx || ay != lastAy) {
        lastAx = ax;
        lastAy = ay;
        window.spooter.move(ax, ay);
      }
    }
  }
  setTimeout(pollMouse, 10);
}

// updating state
var totalMSDif = 0.0;
var numMSDif = 0;
var drawStartTime = null;
var interpolatedState = null;
function gameLoop() {
  var now = new Date().getTime();
  if (!drawStartTime && window.spooter.stateStartTime) {
    drawStartTime = window.spooter.stateStartTime + FORCED_DELAY;
  }

  // Compute average frame update timing information
  if (lastms == 0) {
    lastms = now;
  }
  totalMSDif += now - lastms;
  numMSDif++;
  if (Math.random() < .0001) {
      console.log("Average Time between frames", (totalMSDif / numMSDif));
  }

  lastms = now;

  if (window.spooter.initialized) {
    if (update(now - drawStartTime)) {
      draw(interpolatedState);
    }
  }
  setTimeout(gameLoop, 1);
}

stop = false;
// Interpolate the positions of each entity between the two given states
function update(drawTime) {
  object = window.spooter.getStatesToInterpolate(drawTime);
  if (object == null) {
    return false;
  }
  var t0 = object.leftTime;
  var t1 = object.rightTime;
  var leftEntityMap = {};
  for (var i = 0; i < object.leftState.numEntities; i++) {
    var entity = object.leftState.entities[i];
    leftEntityMap[entity.id + entity.type] = object.leftState.entities[i]
  }
  interpolatedState = {numEntities: object.rightState.numEntities};
  interpolatedState.entities = new Array(object.rightState.numEntities);
  for (i = 0; i < object.rightState.numEntities; i++) {
    entity = object.rightState.entities[i];
    var newEntity = {
      type: entity.type,
      r: entity.r,
      id: entity.id
    };
    if (leftEntityMap.hasOwnProperty(entity.id + entity.type)) {
      var leftEntity = leftEntityMap[entity.id + entity.type];
      // An updated entity, interpolate between the two states
      var x0 = leftEntity.x;
      var y0 = leftEntity.y;
      var x1 = entity.x;
      var y1 = entity.y;
      newEntity.x = (x1 - x0) / (t1 - t0) * (drawTime - t0) + x0;
      newEntity.y = (y1 - y0) / (t1 - t0) * (drawTime - t0) + y0;
      if (entity.id == 0) {
      }
    }
    interpolatedState.entities[i] = newEntity;
  }
  return true;
}

// drawing stuff

function drawCircle(x, y, radius) {
  ctx.beginPath();
  ctx.arc(x, y, radius, 0, 2*Math.PI);
  ctx.fill();
}

function inViewport(e) {
  if (e.x - e.r > viewportX + canvas.width || e.x + e.r < viewportX) return false;
  if (e.y - e.r > viewportY + canvas.height || e.y + e.r < viewportY) return false;
  return true;
}

function startDrawLine() {
    ctx.beginPath();
}

function endDrawLine() {
    ctx.stroke();
}

function drawLine(x1, y1, x2, y2) {
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
}

function draw(state) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  for (var i = 0; i < state.numEntities; i++) {
    if (state.entities[i].type === "player" && state.entities[i].id == window.spooter.playerId) {
      viewportX = state.entities[i].x - (canvas.width >> 1);
      viewportY = state.entities[i].y - (canvas.height >> 1);
      break;
    }
  }

  // draw borders
  ctx.strokeStyle = "#000000";
  ctx.strokeRect(-viewportX, -viewportY, window.spooter.worldWidth, window.spooter.worldHeight);

  // draw grid lines
  ctx.strokeStyle = "#808080";
  var gridWidth = 100;
  startDrawLine();
  for (i = gridWidth; i < window.spooter.worldWidth; i += gridWidth) {
    drawLine(-viewportX, i - viewportY, window.spooter.worldHeight - viewportX, i - viewportY);
  }
  for (i = gridWidth; i < window.spooter.worldHeight; i+= gridWidth) {
    drawLine(i - viewportX, -viewportY, i - viewportX, window.spooter.worldWidth - viewportY);
  }
  endDrawLine();

  // draw entities
  for (i = 0; i < state.numEntities; i++) {
    if (!inViewport(state.entities[i])) continue;
    if (state.entities[i].type === "player") {
      if (state.entities[i].id == window.spooter.playerId) {
        ctx.fillStyle = "#FF0000";
      } else {
        ctx.fillStyle = "#FFFF00";
      }
    } else if (state.entities[i].type === "enemy") {
      ctx.fillStyle = "#5E2D79";
    } else {
      ctx.fillStyle = "#CC8800";
    }
    drawCircle(state.entities[i].x - viewportX, state.entities[i].y - viewportY, state.entities[i].r);
  }
}

resizeCanvas();
gameLoop();
pollMouse();
