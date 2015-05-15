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
    console.log "Game server started!"
    @io = io
    io.on 'connection', (socket) =>
      @initializeConnection socket

    # Entering the loop
    @loop()

  initializeConnection: (socket) ->
    newPlayerId = @nextPlayerId++
    @createPlayer(newPlayerId)

    socket.on "move", @handleMove
    socket.on "disconnect", =>
      @deletePlayer newPlayerId

    socket.emit 'initialize', {playerId: newPlayerId}

  handleMove: (message) =>
    # Invalid message
    if not message? or not message.playerId?
      return

    {mouseX, mouseY, playerId} = message
    if not mouseX? or not mouseY?
      return

    player = @players[playerId]
    player.mouseX = mouseX
    player.mouseY = mouseY

  createPlayer: (playerId) ->
    @players[playerId] = {
      type: 'player'
      id: playerId
      r: 20
      x: Math.random() * @worldWidth
      y: Math.random() * @worldHeight
      vx: 0
      vy: 0
    }

  deletePlayer: (playerId) =>
    if playerId of @players
      delete @players[playerId]

  broadcastState: =>
    entities = []
    for id, enemy of @enemies
      entities.push enemy
    for id, player of @players
      entities.push player
    for id, bullet of @bullets
      entities.push bullet

    state = {
      worldWidth: @worldWidth
      worldHeight: @worldHeight
      entities
    }
    @io.sockets.emit 'state', state

  movePlayer: (player, dt) =>
    # Update the velocity based on the mouse
    ax = player.mouseX - player.x
    ay = player.mouseY - player.y
    player.vx += dt * ax
    player.vy += dt * ay

    # Update the position based on the velocity
    player.x += dt * player.vx
    player.y += dt * player.vy

    # Basic bounds checking
    if player.x - player.r < 0
      player.x = player.r

    if player.x + player.r > @worldWidth
      player.x = @worldWidth - player.r

    if player.y - player.r < 0
      player.y = player.r

    if player.y + player.r > @worldHeight
      player.y = @worldHeight - player.r

  doPhysics: (dt) =>
    # Start by iterating through all of the players and updating their position
    for id, player in @players
      player = @movePlayer player, dt

  LOOP_TIME_INTERVAL = 100
  loop: =>
    startTime = new Date().getTime()

    @doPhysics(LOOP_TIME_INTERVAL / 1000.0)

    @broadcastState()
    diff = LOOP_TIME_INTERVAL - ((new Date().getTime()) - startTime)
    if diff < 0
      console.log "WARNING: Game loop computation too slow!"
      diff = 0
    setTimeout @loop, diff


module.exports = Game