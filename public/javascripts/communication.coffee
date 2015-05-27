# client-side socket nonsense
socket = io('http://localhost:3001') # TODO change localhost to server endpoint

socket.on 'initialize', (data) ->
  console.log "initializing..."
  initialize(data)

serializer = null

socket.on 'state', (data) ->
  if serializer
    setState serializer.toObject(data, nextState(true))
  else
    if window.spooter.StateSerializer?
      serializer = new window.spooter.StateSerializer()

_setStateAtIndex = (index, object) ->
  window.spooter.states[index] = object

_getStateAtIndex = (index) ->
  state = window.spooter.states[index]
  if not state?
    return null
  return state

nextState = (create) ->
  index = (window.spooter.stateBufferIndex + 1) % window.spooter.STATE_BUFFER_SIZE
  state = _getStateAtIndex index
  if not state
    _setStateAtIndex index, {}
    return _getStateAtIndex index
  return state

# Returns the states to interpolate between with the time
getStatesToInterpolate = (time) ->
  leftIndex = null
  # Find the states that this time lies between
  for t, index in window.spooter.stateTimes
    if t <= time and window.spooter.stateTimes[(index + 1) % window.spooter.STATE_BUFFER_SIZE] >= time
      leftIndex = index
      break

  # If we didn't find some enclosing states, exit
  if leftIndex is null
    return null

  rightIndex = (leftIndex + 1) % window.spooter.STATE_BUFFER_SIZE
  return {
    leftState: _getStateAtIndex leftIndex
    rightState: _getStateAtIndex rightIndex
    leftTime: window.spooter.stateTimes[leftIndex]
    rightTime: window.spooter.stateTimes[rightIndex]
  }

incrStateBufferIndex = () ->
  window.spooter.stateBufferIndex++
  window.spooter.stateBufferIndex %= window.spooter.STATE_BUFFER_SIZE

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
  window.spooter.STATE_BUFFER_SIZE = 8;
  window.spooter.states = new Array(window.spooter.STATE_BUFFER_SIZE)
  window.spooter.stateTimes = new Array(window.spooter.STATE_BUFFER_SIZE)
  window.spooter.stateBufferIndex = -1
  window.spooter.stateStartTime = null

  window.spooter.playerId = playerId
  window.spooter.worldHeight = worldHeight
  window.spooter.worldWidth = worldWidth

  window.spooter.move = move
  window.spooter.shoot = shoot
  window.spooter.getStatesToInterpolate = getStatesToInterpolate
  window.spooter.initialized = false

lastStateReceivedTime = 0
totalStateTime = 0
numStateUpdates = 0.0
setState = (newState) ->
  # Collect data on how long between updates.
  now = new Date().getTime()
  if lastStateReceivedTime != 0
    time = now - lastStateReceivedTime
    totalStateTime += time
    numStateUpdates++
    if Math.random() < .001
      console.log "Average state update interval", (totalStateTime / numStateUpdates)
  lastStateReceivedTime = now

  incrStateBufferIndex()

  now = new Date().getTime()
  if window.spooter.stateStartTime is null
    window.spooter.stateStartTime = now

  window.spooter.stateTimes[window.spooter.stateBufferIndex] = (
    now - window.spooter.stateStartTime)

  window.spooter.initialized = true

window.spooter = {}
