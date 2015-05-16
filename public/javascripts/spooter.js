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

function pollMouse() {
  if (mouseX >= 0 && mouseY >= 0 && window.spooter.state.drawState) {
    p = undefined;
    for (i = 0; i < window.spooter.state.drawState.numEntities; i++) {
      entity = window.spooter.state.drawState.entities[i];
      if (window.spooter.playerId == entity.id && entity.type == "player") {
        p = window.spooter.state.drawState.entities[i];
        break;
      }
    }
    if (p) {
      ax = viewportX + mouseX - p.x;
      ay = viewportY + mouseY - p.y;

      if (ax != lastAx || ay != lastAy) {
        lastAx = ax;
        lastAy = ay;
        window.spooter.move(ax, ay);
      }
      //window.spooter.move(viewportX + mouseX, viewportY + mouseY);
    }
  }
  setTimeout(pollMouse, 10);
}

// updating state
totalMSDif = 0.0;
numMSDif = 0;
function gameLoop() {
  var curms = new Date().getTime();
  if (lastms == 0) {
    lastms = curms;
  }
  var msdif = curms - lastms;
  totalMSDif += msdif;
  numMSDif++;
  if (Math.random() < .0001) {
      console.log("Average Time between frames", (totalMSDif / numMSDif));
  }

  lastms = curms;

  if (window.spooter.initialized) {
    update(msdif);
    draw();
  }
  setTimeout(gameLoop, 1);
}

// basically move objects along their velocity
function update(framems) {
  var updateState = window.spooter.state.drawState;
  for (var i = 0; i < updateState.numEntities; i++) {
    updateState.entities[i].x += updateState.entities[i].vx * framems/1000.0;
    updateState.entities[i].y += updateState.entities[i].vy * framems/1000.0;
  }
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

function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  var drawState = window.spooter.state.drawState;
  for (var i = 0; i < drawState.numEntities; i++) {
    if (drawState.entities[i].type === "player" && drawState.entities[i].id == window.spooter.playerId) {
      viewportX = drawState.entities[i].x - (canvas.width >> 1);
      viewportY = drawState.entities[i].y - (canvas.height >> 1);
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
  for (var i = gridWidth; i < window.spooter.worldWidth; i += gridWidth) {
    drawLine(-viewportX, i - viewportY, window.spooter.worldHeight - viewportX, i - viewportY);
  }
  for (var i = gridWidth; i < window.spooter.worldHeight; i+= gridWidth) {
    drawLine(i - viewportX, -viewportY, i - viewportX, window.spooter.worldWidth - viewportY);
  }
  endDrawLine();

  // draw entities
  for (var i = 0; i < drawState.numEntities; i++) {
    if (!inViewport(drawState.entities[i])) continue;
    if (drawState.entities[i].type === "player") {
      if (drawState.entities[i].id == window.spooter.playerId) {
        ctx.fillStyle = "#FF0000";
      } else {
        ctx.fillStyle = "#FFFF00";
      }
    } else if (drawState.entities[i].type === "enemy") {
      ctx.fillStyle = "#5E2D79";
    } else {
      ctx.fillStyle = "#CC8800";
    }
    drawCircle(drawState.entities[i].x - viewportX, drawState.entities[i].y - viewportY, drawState.entities[i].r);
  }
}

resizeCanvas();
gameLoop();
pollMouse();
