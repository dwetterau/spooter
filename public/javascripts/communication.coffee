# client-side socket nonsense
socket = io('http://localhost:3001') # TODO change localhost to server endpoint

socket.on 'initialize', (data) ->
  initialize(data)

serializer = null

socket.on 'state', (data) ->
  if serializer
    setState serializer.toObject(data, window.spooter.state.newState)
  else
    if window.spooter.StateSerializer?
      serializer = new window.spooter.StateSerializer()

move = (ax, ay) ->
  playerId = getPlayerId()
  # Convert the x and y components into an angle
  angle = -Math.atan2(ay, ax)
  if angle < 0
    angle += Math.PI * 2
  angle = Math.round(angle / ((2 * Math.PI) / 255))

  buffer = new ArrayBuffer(2)
  byteView = new Uint8Array(buffer)
  byteView[0] = playerId
  byteView[1] = angle

  socket.emit("move", buffer)

shoot = ->
  playerId = getPlayerId()
  socket.emit("shoot", {playerId})

getPlayerId = ->
  return window.spooter.playerId

initialize = (data) ->
  {worldHeight, worldWidth, playerId} = data
  window.spooter.state = {
    drawState: {}
    newState: {}
  }
  window.spooter.playerId = playerId
  window.spooter.worldHeight = worldHeight
  window.spooter.worldWidth = worldWidth

  window.spooter.initialized = false

lastStateReceivedTime = 0
totalStateTime = 0
numStateUpdates = 0.0
setState = (newState) ->
  now = new Date().getTime()
  if lastStateReceivedTime != 0
    time = now - lastStateReceivedTime
    totalStateTime += time
    numStateUpdates++
    if Math.random() < .001
      console.log "Average state update interval", (totalStateTime / numStateUpdates)
  lastStateReceivedTime = now

  # Swap the state pointers
  oldState = window.spooter.state.drawState
  window.spooter.state.drawState = newState
  window.spooter.state.newState = oldState

  window.spooter.initialized = true

window.spooter = {initialized: false, move, shoot, state: {
  drawState: {}
  newState: {}
}}
