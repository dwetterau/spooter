LOOP_TIME_INTERVAL = 10
BULLET_SPEED = 500
PLAYER_SPEED_LIMIT = 300
MIN_ENEMIES = 5
MAX_ENEMIES = 50
ENEMY_SPAWN_PERCENTAGE = .05
ENEMY_SHRINKAGE = 5
ENEMY_SIZE_RANGE = 40
ENEMY_MIN_SIZE = 20

class Game

  constructor: ->
    @worldWidth = 4000
    @worldHeight = 4000

    @players = {}
    @nextPlayerId = 0

    @enemies = {}
    @nextEnemyId = 0

    @bullets = {}
    @nextBulletId = 0

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
    socket.on "shoot", @handleShoot
    socket.on "disconnect", =>
      console.log "Player disconnected!", newPlayerId
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

  handleShoot: (message) =>
    if not message? or not message.playerId?
      return

    {playerId} = message
    if playerId not of @players
      return

    p = @players[playerId]
    {x, y} = p
    vx = p.mouseX - x
    vy = p.mouseY - y

    @createBullet x, y, vx, vy, p.type

  createPlayer: (playerId) ->
    x = Math.random() * @worldWidth
    y = Math.random() * @worldHeight
    @players[playerId] = {
      type: 'player'
      id: playerId
      r: 20
      x
      y
      vx: 0
      vy: 0
      mouseX: x
      mouseY: y
    }

  createBullet: (x, y, vx, vy, type) =>
    id = @nextBulletId++
    mag = Math.sqrt(vx * vx + vy * vy)

    # We don't know where to shoot it
    if mag == 0
      return

    vx *= BULLET_SPEED / mag
    vy *= BULLET_SPEED / mag

    @bullets[id] = {
      type: 'bullet'
      id
      r: 5
      x
      y
      vx
      vy
      ownerType: type
    }

  createEnemy: =>
    r = parseInt(Math.random() * ENEMY_SIZE_RANGE) + ENEMY_MIN_SIZE
    x = r + Math.random() * (@worldWidth - 2 * r)
    y = r + Math.random() * (@worldHeight - 2 * r)

    # TODO: Make 'em move boys
    vx = 0
    vy = 0

    id = @nextEnemyId++

    @enemies[id] = {type: 'enemy', id, r, x, y, vx, vy}

  deletePlayer: (playerId) =>
    if playerId of @players
      delete @players[playerId]

  broadcastState: =>
    entities = []
    for id, bullet of @bullets
      entities.push bullet
    for id, enemy of @enemies
      entities.push enemy
    for id, player of @players
      entities.push player

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
    clampedX = false
    clampedY = false
    if player.x - player.r < 0
      clampedX = true
      player.x = player.r

    if player.x + player.r > @worldWidth
      clampedX = true
      player.x = @worldWidth - player.r

    if player.y - player.r < 0
      clampedY = true
      player.y = player.r

    if player.y + player.r > @worldHeight
      clampedY = true
      player.y = @worldHeight - player.r

    if clampedX
      player.vx = 0
    if clampedY
      player.vy = 0

    speed = Math.sqrt(player.vx * player.vx + player.vy * player.vy);
    if (speed > PLAYER_SPEED_LIMIT)
      player.vx *= PLAYER_SPEED_LIMIT / speed;
      player.vy *= PLAYER_SPEED_LIMIT / speed;

  # Returns true if the bullet is now gone
  moveBullet: (bullet, dt) ->
    # Update the position based on the velocity
    bullet.x += dt * bullet.vx
    bullet.y += dt * bullet.vy

    if bullet.x - bullet.r < 0
      return true

    if bullet.x + bullet.r > @worldWidth
      return true

    if bullet.y - bullet.r < 0
      return true

    if bullet.y + bullet.r > @worldHeight
      return true
    return false

  collides: (e1, e2) ->
    dx = (e1.x - e2.x)
    dy = (e1.y - e2.y)
    dr = e1.r + e2.r
    return dx * dx + dy * dy <= dr * dr

  shrinkEnemy: (enemy) =>
    enemy.r -= ENEMY_SHRINKAGE
    return enemy.r < ENEMY_MIN_SIZE

  doPhysics: (dt) =>
    # Start by iterating through all of the players and updating their position
    for id of @players
      @movePlayer @players[id], dt

    bulletsToRemove = []
    for id of @bullets
      if @moveBullet @bullets[id], dt
        bulletsToRemove.push id

    for id in bulletsToRemove
      delete @bullets[id]

    enemiesToDelete = []
    for id, bullet of @bullets
      if bullet.ownerType == 'player'
        for eid, enemy of @enemies
          if eid of enemiesToDelete
            continue

          if @collides enemy, bullet
            bulletsToRemove.push id
            if @shrinkEnemy enemy
              enemiesToDelete[eid] = true
      else if bullet.ownerType == 'enemy'
        for pid, player of @players
          if @collides player, bullet
            # TODO: do something
            console.log "player got hit by bullet from enemy"

    for eid of enemiesToDelete
      delete @enemies[eid]

    for id in bulletsToRemove
      delete @bullets[id]

  loop: =>
    startTime = new Date().getTime()

    numEnemies = Object.keys(@enemies).length
    if Math.random() < ENEMY_SPAWN_PERCENTAGE || numEnemies < MIN_ENEMIES
      if numEnemies < MAX_ENEMIES
        @createEnemy()

    @doPhysics(LOOP_TIME_INTERVAL / 1000.0)

    @broadcastState()
    diff = LOOP_TIME_INTERVAL - ((new Date().getTime()) - startTime)
    if diff < 0
      console.log "WARNING: Game loop computation too slow!"
      diff = 0
    setTimeout @loop, diff

module.exports = Game
