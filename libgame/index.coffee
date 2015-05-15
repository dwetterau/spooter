LOOP_TIME_INTERVAL = 10
BULLET_SPEED = 500
PLAYER_SPEED_LIMIT = 200
PLAYER_ACCELERATION_LIMIT = 200

MIN_ENEMIES = 15
MAX_ENEMIES = 50
ENEMY_SPAWN_PERCENTAGE = .001
ENEMY_SHRINKAGE = 5
ENEMY_SIZE_RANGE = 40
ENEMY_MIN_SIZE = 20
ENEMY_SPEED_LIMIT = 120
ENEMY_ACCELERATION_LIMIT = 100
ENEMY_VISION_DIST = 250
ENEMY_SHOOT_PERCENTAGE = .01

BULLET_MIN_SIZE = 5
BULLET_SIZE_FACTOR = .2

class Game

  constructor: ->
    @worldWidth = 2000
    @worldHeight = 2000

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
    if not mouseX? or not mouseY? or playerId not of @players
      return

    player = @players[playerId]
    player.ax = mouseX - player.x
    player.ay = mouseY - player.y

  handleShoot: (message) =>
    if not message? or not message.playerId?
      return

    {playerId} = message
    if playerId not of @players
      return

    p = @players[playerId]
    {x, y} = p
    vx = p.ax
    vy = p.ay

    @createBullet x, y, vx, vy, p.type, p.r

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
      ax: 0
      ay: 0
    }

  createBullet: (x, y, vx, vy, ownerType, ownerR) =>
    id = @nextBulletId++
    mag = Math.sqrt(vx * vx + vy * vy)

    # We don't know where to shoot it
    if mag == 0
      return

    vx *= BULLET_SPEED / mag
    vy *= BULLET_SPEED / mag

    r = Math.max(BULLET_MIN_SIZE, Math.round(ownerR * BULLET_SIZE_FACTOR))

    @bullets[id] = {
      type: 'bullet'
      id
      r
      x
      y
      vx
      vy
      ownerType
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

  moveEntity: (entity, dt, ax, ay, speedLimit) =>
    # Update the velocity based on the mouse
    entity.vx += dt * ax
    entity.vy += dt * ay

    # cap velocity
    speed = Math.sqrt(entity.vx * entity.vx + entity.vy * entity.vy);
    if (speed > speedLimit)
      entity.vx *= speedLimit / speed;
      entity.vy *= speedLimit / speed;

    # Update the position based on the velocity
    entity.x += dt * entity.vx
    entity.y += dt * entity.vy

    # Basic bounds checking
    clampedX = false
    clampedY = false
    if entity.x - entity.r < 0
      clampedX = true
      entity.x = entity.r

    if entity.x + entity.r > @worldWidth
      clampedX = true
      entity.x = @worldWidth - entity.r

    if entity.y - entity.r < 0
      clampedY = true
      entity.y = entity.r

    if entity.y + entity.r > @worldHeight
      clampedY = true
      entity.y = @worldHeight - entity.r

    if clampedX
      entity.vx = 0
    if clampedY
      entity.vy = 0

  movePlayer: (player, dt) =>
    # Cap the player's acceleration
    mag = Math.sqrt player.ax * player.ax + player.ay * player.ay
    if mag > PLAYER_ACCELERATION_LIMIT
      player.ax *= PLAYER_ACCELERATION_LIMIT / mag
      player.ay *= PLAYER_ACCELERATION_LIMIT / mag

    @moveEntity player, dt, player.ax, player.ay, PLAYER_SPEED_LIMIT

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

  enemyAI: (enemy) =>
    # check if done wandering
    if enemy.destination
      vmag = enemy.vx * enemy.vx + enemy.vy * enemy.vy
      dx = enemy.x - enemy.destination.x
      dy = enemy.y - enemy.destination.y
      if (vmag > dx * dx + dy * dy)
        enemy.destination = undefined

    closestPlayer = undefined
    closestDistance = 100000000
    for pid, player of @players
      dx = enemy.x - player.x
      dy = enemy.y - player.y
      dist = Math.sqrt(dx * dx + dy * dy)
      if dist < closestDistance
        closestDistance = dist
        closestPlayer = player
    if (!enemy.destination && closestDistance > ENEMY_VISION_DIST)
      x = Math.random() * @worldWidth
      y = Math.random() * @worldHeight
      enemy.destination = {x, y}
    if (closestDistance < ENEMY_VISION_DIST)
      enemy.destination = {x: closestPlayer.x, y: closestPlayer.y}

      # shoot
      if Math.random() < ENEMY_SHOOT_PERCENTAGE
        ax = closestPlayer.x - enemy.x
        ay = closestPlayer.y - enemy.y
        @createBullet enemy.x, enemy.y, ax, ay, enemy.type, enemy.r
        console.log "enemy shooting"


  moveEnemy: (enemy, dt) =>
    if (!enemy.destination)
      return
    ax = enemy.destination.x - enemy.x
    ay = enemy.destination.y - enemy.y
    mag = Math.sqrt(ax * ax + ay * ay)
    if mag > ENEMY_ACCELERATION_LIMIT
      ax *= ENEMY_ACCELERATION_LIMIT / mag
      ay *= ENEMY_ACCELERATION_LIMIT / mag

    @moveEntity enemy, dt, ax, ay, ENEMY_SPEED_LIMIT


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

    for id, enemy of @enemies
      @enemyAI enemy

    for id, enemy of @enemies
      @moveEnemy enemy, dt

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
