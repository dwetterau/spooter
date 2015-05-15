// important stuff
var lastms = 0;

var canvas=document.getElementById("spooterCanvas");
var ctx=canvas.getContext("2d"); 

var viewportX = 0;
var viewportY = 0;

// input
var mouseX = -1;
var mouseY = -1;
var clicked;

canvas.addEventListener('mousemove', function(evt) {
  var rect = canvas.getBoundingClientRect();
  var root = document.documentElement;

  mouseX = viewportX + evt.clientX - rect.left - root.scrollLeft;
  mouseY = viewportY + evt.clientY - rect.top - root.scrollTop;
}, false);

canvas.addEventListener('click', function(evt) {
  clicked = true;
  window.spooter.shoot();
}, false);

function pollMouse() {
  if (mouseX >= 0 && mouseY >= 0) {
    window.spooter.move(mouseX, mouseY);
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
  setTimeout(gameLoop, 1);
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
  if (e.x - e.r > viewportX + 640 || e.x + e.r < viewportX) return false;
  if (e.y - e.r > viewportY + 480 || e.y + e.r < viewportY) return false;
  return true;
}

function drawLine(x1, y1, x2, y2) {
  ctx.beginPath();
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.stroke();
}

function draw() {
  ctx.fillStyle = "#FFFFFF";
  ctx.fillRect(0, 0, 640, 640);
  var drawState = window.spooter.state;
  for (var i = 0; i < drawState.entities.length; i++) {
    if (drawState.entities[i].type === "player" && drawState.entities[i].id == window.spooter.playerId) {
      viewportX = drawState.entities[i].x - 320;
      viewportY = drawState.entities[i].y - 240;
      break;
    }
  }

  // draw borders
  ctx.strokeStyle = "#000000";
  ctx.strokeRect(0, 0, drawState.worldWidth, drawState.worldHeight);

  // draw grid lines
  ctx.strokeStyle = "#808080";
  var gridWidth = 100;
  for (var i = gridWidth; i < drawState.worldWidth; i += gridWidth) {
    drawLine(0, i, gridHeight, i);
  }
  for (var i = gridWidth; i < drawState.worldHeight; i+= gridWidth) {
    drawLine(i, 0, i, gridHeight);
  }

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

gameLoop();
pollMouse();
