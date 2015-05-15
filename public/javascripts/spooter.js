// TODO remove
window.spooter = { state:
{
  worldWidth: 1500,
  worldHeight: 1500,
  entities: [
    { x: 100,
      y: 100,
      vx: 50,
      vy: 50,
      r: 20,
      type: "player",
      id: 0
    },
    { x: 20,
      y: 200,
      vx: 30,
      vy: 0,
      r: 6,
      type: "bullet",
      id: 1
    },
    { x: 400,
      y: 400,
      vx: 0,
      vy: 0,
      r: 15,
      type: "enemy",
      id: 2
    },
    { x: 300,
      y: 200,
      vx: 0,
      vy: 15,
      r: 20,
      type: "player",
      id: 3
    }
  ]
},
playerId: 0
};

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
  window.console.log("x: " + mouseX + ", y: " + mouseY);
  window.spooter.move(mouseX, mouseY);
}, false);

canvas.addEventListener('click', function(evt) {
  clicked = true;
  window.console.log("clicked");
  window.spooter.shoot();
}, false);

// updating state

function gameLoop() {
  var curms = new Date().getTime();
  if (lastms == 0) {
    lastms = curms;
  }
  var msdif = curms - lastms;
  lastms = curms;
  update(msdif);
  draw();
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

function draw() {
  ctx.fillStyle = "#FFFFFF";
  ctx.fillRect(0, 0, 640, 640);
  var drawState = window.spooter.state;
  for (var i = 0; i < drawState.entities.length; i++) {
    if (drawState.entities[i].type === "player" && drawState.entities[i].id == window.spooter.playerId) {
      viewportX = Math.max(0, drawState.entities[i].x - 320);
      viewportX = Math.min(viewportX, drawState.worldWidth - 640);
      viewportY = Math.max(0, drawState.entities[i].y - 240);
      viewportY = Math.min(viewportY, drawState.worldHeight - 480);
      window.console.log("viewport: (" + viewportX + ", "  + viewportY + ")");
      break;
    }
  }

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
