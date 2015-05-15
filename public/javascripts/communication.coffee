# client-side socket nonsense
socket = io('http://localhost:3001') # TODO change localhost to server endpoint

socket.on 'initialize', (data) ->
  {playerId} = data
  clearState(playerId)
  move(-1, -1)

socket.on 'state', (data) ->
  console.log data
  setState data

move = (mouseX, mouseY) ->
  playerId = getPlayerId()
  socket.emit("move", {playerId, mouseX, mouseY})

shoot = ->
  console.log "Shooting"
  socket.emit("shoot", {})

getPlayerId = ->
  return window.spooter.playerId

clearState = (playerId) ->
  window.spooter.state = {}
  window.spooter.playerId = playerId

setState = (newState) ->
  window.spooter.state = newState

window.spooter = {move, shoot, state: {}}
