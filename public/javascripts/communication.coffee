# client-side socket nonsense
socket = io('http://localhost') # TODO change localhost to server endpoint
socket.on 'state', (data) ->
  console.log data
  socket.emit('my other event', { my: 'data' })

move = (mouseX, mouseY) ->
  socket.emit("move", { mouseX, mouseY })

shoot = ->
  console.log "Shooting"
  socket.emit("shoot", {})
