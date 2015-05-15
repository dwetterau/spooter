LOOP_TIME_INTERVAL = 10
MAX_BULLET_SPEED = 500
PLAYER_SPEED_LIMIT = 200
PLAYER_ACCELERATION_LIMIT = 200
PLAYER_SHRINKAGE = 2
PLAYER_GROWAGE = 10
PLAYER_MIN_SIZE = 15
PLAYER_MAX_SIZE = 80

MIN_ENEMIES = 15
MAX_ENEMIES = 50
ENEMY_SPAWN_PERCENTAGE = .001
ENEMY_SHRINKAGE = 5
ENEMY_SIZE_RANGE = 40
ENEMY_MIN_SIZE = 20
ENEMY_SPEED_LIMIT = 120
ENEMY_ACCELERATION_LIMIT = 100
ENEMY_VISION_DIST = 250
ENEMY_SHOOT_PERCENTAGE = .003

BULLET_MIN_SIZE = 5
BULLET_SIZE_FACTOR = .2

EPSILON = .001

Vector = require('./vector')

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

    @createBullet x, y, vx, vy, p.type, p.r, p.id

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

  createBullet: (x, y, vx, vy, ownerType, ownerR, ownerId) =>
    id = @nextBulletId++
    mag = Math.sqrt(vx * vx + vy * vy)

    # We don't know where to shoot it
    if mag == 0
      return

    vx *= MAX_BULLET_SPEED / mag
    vy *= MAX_BULLET_SPEED / mag

    r = Math.max(BULLET_MIN_SIZE, Math.round(ownerR * BULLET_SIZE_FACTOR))

    vx *= BULLET_MIN_SIZE / r
    vy *= BULLET_MIN_SIZE / r

    @bullets[id] = {
      type: 'bullet'
      id
      r
      x
      y
      vx
      vy
      ownerType
      ownerId
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
      entity.x = entity.r + EPSILON

    if entity.x + entity.r > @worldWidth
      clampedX = true
      entity.x = @worldWidth - entity.r - EPSILON

    if entity.y - entity.r < 0
      clampedY = true
      entity.y = entity.r + EPSILON

    if entity.y + entity.r > @worldHeight
      clampedY = true
      entity.y = @worldHeight - entity.r - EPSILON

    if clampedX
      entity.vx = -entity.vx
    if clampedY
      entity.vy = -entity.vy

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

  bounceCollision: (e1, e2) ->
    m1 = e1.r * e1.r * Math.PI
    m2 = e2.r * e2.r * Math.PI

    between = new Vector(e2.x - e1.x, e2.y - e1.y)

    # Move the second entity out of the collision
    between.makeMagnitude e1.r + e2.r + EPSILON
    e2.x = e1.x + between.a
    e2.y = e1.y + between.b

    centerVelocity = new Vector(
      (e1.vx * m1 + e2.vx * m2) / (m1 + m2),
      (e1.vy * m1 + e2.vy * m2) / (m1 + m2)
    )
    # The collision switches the direction
    centerVelocity.reverse()

    v1 = new Vector e1.vx, e1.vy
    v2 = new Vector e2.vx, e2.vy

    # Convert these velocities to center of mass view
    v1.addVector centerVelocity
    v2.addVector centerVelocity

    between.normalize()
    v1Between = v1.project between
    v1Between.reverse()
    v1Between.scaleInPlace 2
    v1.addVector v1Between

    between.reverse()
    v2Between = v2.project between
    v2Between.reverse()
    v2Between.scaleInPlace 2
    v2.addVector v2Between

    # Convert the velocities back out of center of mass view
    centerVelocity.reverse()
    v1.addVector centerVelocity
    v2.addVector centerVelocity

    # Copy the new velocities back out
    e1.vx = v1.a
    e1.vy = v1.b
    e2.vx = v2.a
    e2.vy = v2.b

  shrinkEntity: (entity, bullet) =>
    er2 = entity.r * entity.r
    br2 = bullet.r * bullet.r * 10
    return true if er2 < br2
    entity.r = Math.sqrt(er2 - br2)
    if entity.type == 'player'
      return entity.r < PLAYER_MIN_SIZE
    if entity.type == 'enemy'
      return entity.r < ENEMY_MIN_SIZE
    return false

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
        @createBullet enemy.x, enemy.y, ax, ay, enemy.type, enemy.r, enemy.id


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

    # Process the bullet collisions
    enemiesToDelete = []
    bulletsToRemove = []
    for id, bullet of @bullets
      if bullet.ownerType == 'player'
        for eid, enemy of @enemies
          if eid of enemiesToDelete
            continue

          if @collides enemy, bullet
            bulletsToRemove.push id
            if @shrinkEntity enemy, bullet
              enemiesToDelete[eid] = true
              if bullet.ownerId of @players
                @players[bullet.ownerId].r = Math.min(PLAYER_GROWAGE + @players[bullet.ownerId].r, PLAYER_MAX_SIZE)
      else if bullet.ownerType == 'enemy'
        for pid, player of @players
          if @collides player, bullet
            bulletsToRemove.push id
            if @shrinkEntity player, bullet
              # player died
              id = player.id
              delete @players[id]
              @createPlayer(id)

    for eid of enemiesToDelete
      delete @enemies[eid]

    for id in bulletsToRemove
      delete @bullets[id]

    for id, enemy of @enemies
      @enemyAI enemy

    for id, enemy of @enemies
      @moveEnemy enemy, dt

    # Process the player to enemy collisions
    for pid, player of @players
      for eid, enemy of @enemies
        if @collides enemy, player
          @bounceCollision enemy, player

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
