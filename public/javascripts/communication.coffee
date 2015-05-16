# client-side socket nonsense
socket = io('http://localhost:3001') # TODO change localhost to server endpoint

socket.on 'initialize', (data) ->
  initialize(data)

serializer = null

socket.on 'state', (data) ->
  if serializer
    setState serializer.toObject(data)
  else
    if window.spooter.StateSerializer?
      serializer = new window.spooter.StateSerializer()

move = (mouseX, mouseY) ->
  playerId = getPlayerId()
  socket.emit("move", {playerId, mouseX, mouseY})

shoot = ->
  playerId = getPlayerId()
  socket.emit("shoot", {playerId})

getPlayerId = ->
  return window.spooter.playerId

initialize = (data) ->
  {worldHeight, worldWidth, playerId} = data
  window.spooter.state = {}
  window.spooter.playerId = playerId
  window.spooter.worldHeight = worldHeight
  window.spooter.worldWidth = worldWidth

  window.spooter.initialized = false

setState = (newState) ->
  window.spooter.state = newState
  window.spooter.initialized = true

window.spooter = {initialized: false, move, shoot, state: {}}
