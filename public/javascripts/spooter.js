// important stuff
var lastms = 0;

var canvas = document.getElementById("spooterCanvas");
var ctx = canvas.getContext("2d");

var viewportX = 0;
var viewportY = 0;

// input
var mouseX = -1;
var mouseY = -1;
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
  if (mouseX >= 0 && mouseY >= 0) {
    window.spooter.move(viewportX + mouseX, viewportY + mouseY);
  }
  setTimeout(pollMouse, 10);
}

// updating state

function gameLoop() {
  var curms = new Date().getTime();
  if (lastms == 0) {
    lastms = curms;
  }
  var msdif = curms - lastms;
  lastms = curms;

  if (window.spooter.initialized) {
    update(msdif);
    draw();
  }
  setTimeout(gameLoop, 5);
}

// basically move objects along their velocity
function update(framems) {
  var updateState = window.spooter.state;
  for (var i = 0; i < updateState.entities.length; i++) {
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
  var drawState = window.spooter.state;
  for (var i = 0; i < drawState.entities.length; i++) {
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
  for (var i = 0; i < drawState.entities.length; i++) {
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
