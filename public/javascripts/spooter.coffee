# important stuff
lastms = 0

canvas = document.getElementById("spooterCanvas")
ctx = canvas.getContext("2d")

viewportX = 0
viewportY = 0

# input
mouseX = -1
mouseY = -1
lastAx = 0
lastAy = 0

# The amount in milliseconds clients are forced to be behind
# Three state updates (3 * 20) + 3 frames (3 * 16)
FORCED_DELAY = 110

window.addEventListener 'resize', resizeCanvas, false

resizeCanvas = ->
  canvas.width = window.innerWidth
  canvas.height = window.innerHeight

canvas.addEventListener 'mousemove', (evt) ->
  rect = canvas.getBoundingClientRect()
  root = document.documentElement

  mouseX = evt.clientX - rect.left - root.scrollLeft
  mouseY = evt.clientY - rect.top - root.scrollTop
, false

canvas.addEventListener 'click', ->
  window.spooter.shoot()
, false

getState = ->
  if interpolatedState
    return interpolatedState
  if not window.spooter.states? or not window.spooter.stateBufferIndex?
    return null

  index = window.spooter.stateBufferIndex
  if window.spooter.states[index]?
    return window.spooter.states[index]
  return null

getPlayer = ->
  state = getState()
  if not state
    return null

  i = 0
  for i in [0...state.numEntities]
    entity = state.entities[i]
    if window.spooter.playerId == entity.id and entity.type == 'player'
      return entity
  return null

pollMouse = ->
  if mouseX >= 0 and mouseY >= 0
    p = getPlayer()
    if p
      ax = viewportX + mouseX - p.x
      ay = viewportY + mouseY - p.y

      if ax != lastAx or ay != lastAy
        lastAx = ax
        lastAy = ay
        window.spooter.move(ax, ay)

  setTimeout pollMouse, 10

# updating state
totalMSDif = 0.0
numMSDif = 0
drawStartTime = null
interpolatedState = null
gameLoop = ->
  now = new Date().getTime()
  if not drawStartTime and window.spooter.stateStartTime
    drawStartTime = window.spooter.stateStartTime + FORCED_DELAY

  # Compute average frame update timing information
  if lastms == 0
    lastms = now

  totalMSDif += now - lastms
  numMSDif++
  if Math.random() < .0001
    console.log("Average Time between frames", (totalMSDif / numMSDif))

  lastms = now
  if window.spooter.initialized and update(now - drawStartTime)
    draw(interpolatedState)
  setTimeout gameLoop, Math.max(1, (17 - (now - lastms)))

stop = false
# Performs Hermite Interpolation between the two points given their
# first derivatives. Note velocity is in pixels / second so we need
# to convert it to ms here.
hermiteInterpolation = (p0, p1, v0, v1, t0, t1, t) ->
  a = p0
  b = v0 / 1000.0
  h = t1 - t0
  c = (p1 - a - (b * h)) / (h * h)
  d = ((v1 / 1000.0) - b - (2 * c * h)) / (h * h)
  e = t - t0
  ee = e * e
  return a + b * e + c * (ee) + d * (ee * (t - t1))

# Interpolate the positions of each entity between the two given states
update = (drawTime) ->
  object = window.spooter.getStatesToInterpolate(drawTime)
  if object is null
    return false

  t0 = object.leftTime
  t1 = object.rightTime
  leftEntityMap = {}
  for i in [0...object.leftState.numEntities]
    entity = object.leftState.entities[i]
    leftEntityMap[entity.id + entity.type] = object.leftState.entities[i]

  numEntities = object.rightState.numEntities
  if not interpolatedState?
    interpolatedState = {
      entities: new Array(numEntities)
    }
  interpolatedState.numEntities = numEntities
  for i in [0...numEntities]
    entity = object.rightState.entities[i]
    interpolatedState.entities[i] = {}
    newEntity = interpolatedState.entities[i]

    newEntity.type = entity.type
    newEntity.id = entity.id
    newEntity.r = entity.r
    key = entity.id + entity.type
    if key of leftEntityMap
      leftEntity = leftEntityMap[key]
      # An updated entity, interpolate between the two states
      x0 = leftEntity.x
      vx0 = leftEntity.vx
      x1 = entity.x
      vx1 = entity.vx

      y0 = leftEntity.y
      vy0 = leftEntity.vy
      y1 = entity.y
      vy1 = entity.vy

      newEntity.x = hermiteInterpolation(x0, x1, vx0, vx1, t0, t1, drawTime)
      newEntity.y = hermiteInterpolation(y0, y1, vy0, vy1, t0, t1, drawTime)
  return true

# drawing stuff

drawCircle = (x, y, radius) ->
  ctx.beginPath()
  ctx.arc(x, y, radius, 0, 2*Math.PI)
  ctx.fill()

inViewport = (e) ->
  if e.x - e.r > viewportX + canvas.width or e.x + e.r < viewportX then return false
  if e.y - e.r > viewportY + canvas.height or e.y + e.r < viewportY then return false
  return true

startDrawLine = () ->
  ctx.beginPath()

endDrawLine = () ->
  ctx.stroke()

drawLine = (x1, y1, x2, y2) ->
  ctx.moveTo(x1, y1)
  ctx.lineTo(x2, y2)

drawEntity = (entity) ->
  if entity.type is "player"
    if entity.id is window.spooter.playerId
      ctx.fillStyle = "#FF0000"
    else
      ctx.fillStyle = "#FFFF00"
  else if entity.type is "enemy"
    ctx.fillStyle = "#5E2D79"
  else
    ctx.fillStyle = "#CC8800"
  drawCircle entity.x - viewportX, entity.y - viewportY, entity.r

draw = (state) ->
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  for i in [0...state.numEntities]
    if state.entities[i].type == "player" and state.entities[i].id == window.spooter.playerId
      viewportX = state.entities[i].x - (canvas.width >> 1)
      viewportY = state.entities[i].y - (canvas.height >> 1)
      break

  # draw borders
  ctx.strokeStyle = "#000000"
  ctx.strokeRect(-viewportX, -viewportY, window.spooter.worldWidth, window.spooter.worldHeight)

  # draw grid lines
  ctx.strokeStyle = "#808080"
  gridWidth = 100
  startDrawLine()
  i = gridWidth
  while i < window.spooter.worldWidth
    drawLine(-viewportX, i - viewportY, window.spooter.worldHeight - viewportX, i - viewportY)
    i += gridWidth

  i = gridWidth
  while i < window.spooter.worldHeight
    drawLine(i - viewportX, -viewportY, i - viewportX, window.spooter.worldWidth - viewportY)
    i += gridWidth
  endDrawLine()

  # draw entities
  for i in [0...state.numEntities]
    entity = state.entities[i]
    if not inViewport(entity) then continue
    drawEntity entity

resizeCanvas()
gameLoop()
pollMouse()
