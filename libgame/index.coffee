class Game

  constructor: ->
    @worldWidth = 4000
    @worldHeight = 4000

    @players = {}
    @nextPlayerId = 0
    @enemies = {}
    @bullets = {}

    @io = null

  # Attach all the proper listeners to io
  start: (io) ->
    io.on 'connection', (socket) =>
      @initializeConnection socket

  initializeConnection: (socket) ->
    socket.on "move", @handleMove

    newPlayerId = @nextPlayerId++
    socket.emit {playerId: newPlayerId}

  handleMove: (from, message) ->
    {mouseX, mouseY} = message
    playerId = from

module.exports = Game