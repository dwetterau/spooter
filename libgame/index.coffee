LOOP_TIME_INTERVAL = 50 # 20 state updates per second
MAX_BULLET_SPEED = 500
PLAYER_SPEED_LIMIT = 500
PLAYER_ACCELERATION = 200
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
ENEMY_SPEED_LIMIT = 300
ENEMY_ACCELERATION_LIMIT = 100
ENEMY_VISION_DIST = 250
ENEMY_SHOOT_PERCENTAGE = .003

BULLET_MIN_SIZE = 5
BULLET_SIZE_FACTOR = .2

EPSILON = .001

Vector = require('./vector')
StateSerializer = require('../public/javascripts/common/state_serializer')
serializer = new StateSerializer()

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

    @entities = []
    @numEntities = 0
    @typeMap =
      player: @players
      enemy: @enemies
      bullet: @bullets

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
      if newPlayerId of @players
        @deleteEntity newPlayerId, @players

    socket.emit 'initialize', {
      playerId: newPlayerId,
      worldWidth: @worldWidth
      worldHeight: @worldHeight
    }

  handleMove: (buffer) =>
    # Invalid message
    if not buffer?
      return

    byteView = new Uint8Array(buffer)
    playerId = byteView[0]
    angle = byteView[1]

    angle *= (2 * Math.PI) / 255
    ax = Math.cos(angle)
    ay = -Math.sin(angle)

    if not ax? or not ay? or playerId not of @players
      return

    player = @entities[@players[playerId]]
    player.ax = ax
    player.ay = ay

  handleShoot: (message) =>
    if not message? or not message.playerId?
      return

    {playerId} = message
    if playerId not of @players
      return

    p = @entities[@players[playerId]]
    {x, y} = p
    vx = p.ax
    vy = p.ay

    @createBullet x, y, vx, vy, p

  createPlayer: (playerId) ->
    x = Math.random() * @worldWidth
    y = Math.random() * @worldHeight
    player = {
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
    @createEntity(playerId, @players, player)

  createBullet: (x, y, vx, vy, owner) =>
    id = @nextBulletId++
    mag = Math.sqrt(vx * vx + vy * vy)

    # We don't know where to shoot it
    if mag == 0
      return

    vx *= MAX_BULLET_SPEED / mag
    vy *= MAX_BULLET_SPEED / mag

    r = Math.max(BULLET_MIN_SIZE, Math.round(owner.r * BULLET_SIZE_FACTOR))

    vx *= BULLET_MIN_SIZE / r
    vy *= BULLET_MIN_SIZE / r

    # Add the launching vector for realistic bullet physics
    vx += owner.vx
    vy += owner.vy

    bullet = {
      type: 'bullet'
      id
      r
      x
      y
      vx
      vy
      ownerType: owner.type
      ownerId: owner.id
    }
    @createEntity(id, @bullets, bullet)

  createEnemy: =>
    r = parseInt(Math.random() * ENEMY_SIZE_RANGE) + ENEMY_MIN_SIZE
    x = r + Math.random() * (@worldWidth - 2 * r)
    y = r + Math.random() * (@worldHeight - 2 * r)

    # TODO: Make 'em move boys
    vx = 0
    vy = 0

    id = @nextEnemyId++

    enemy = {type: 'enemy', id, r, x, y, vx, vy}
    @createEntity(id, @enemies, enemy)

  createEntity: (id, map, entity) ->
    newIndex = @numEntities++
    @entities[newIndex] = entity
    map[id] = newIndex

  deleteEntity: (id, map) ->
    @numEntities--
    holeIndex = map[id]

    # We don't need to swap if the last thing we added was removed
    if @numEntities != holeIndex
      # Swap the last entity into the hole
      entity = @entities[@numEntities]
      @entities[holeIndex] = entity
      delete @entities[@numEntities]

      # Repair the mapping after the swap
      holeMap = @typeMap[entity.type]
      holeMap[entity.id] = holeIndex

    delete map[id]

  broadcastState: =>
    state = {
      numEntities: @numEntities
      entities: @entities
    }
    array = serializer.toArray(state)
    @io.sockets.emit 'state', array

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
    ax = player.ax * PLAYER_ACCELERATION
    ay = player.ay * PLAYER_ACCELERATION

    @moveEntity player, dt, ax, ay, (
      PLAYER_SPEED_LIMIT * (PLAYER_MIN_SIZE / player.r))

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

  growPlayer: (playerId) =>
    player = @entities[@players[playerId]]
    player.r = Math.min(
      PLAYER_GROWAGE + player.r,
      PLAYER_MAX_SIZE
    )

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

    closestPlayer = null
    closestDistance = Number.MAX_VALUE
    for pid, playerIndex of @players
      player = @entities[playerIndex]
      dx = enemy.x - player.x
      dy = enemy.y - player.y
      dist = Math.sqrt(dx * dx + dy * dy)
      if dist < closestDistance
        closestDistance = dist
        closestPlayer = player
    if !enemy.destination && closestPlayer && (
      closestDistance > ENEMY_VISION_DIST + closestPlayer.r + enemy.r)
      x = Math.random() * @worldWidth
      y = Math.random() * @worldHeight
      enemy.destination = {x, y}
    if closestDistance < ENEMY_VISION_DIST
      enemy.destination = {x: closestPlayer.x, y: closestPlayer.y}

      # shoot
      if Math.random() < ENEMY_SHOOT_PERCENTAGE
        ax = closestPlayer.x - enemy.x
        ay = closestPlayer.y - enemy.y
        @createBullet enemy.x, enemy.y, ax, ay, enemy

  moveEnemy: (enemy, dt) =>
    if !enemy.destination
      return
    ax = enemy.destination.x - enemy.x
    ay = enemy.destination.y - enemy.y
    mag = Math.sqrt(ax * ax + ay * ay)
    if mag > ENEMY_ACCELERATION_LIMIT
      ax *= ENEMY_ACCELERATION_LIMIT / mag
      ay *= ENEMY_ACCELERATION_LIMIT / mag

    @moveEntity enemy, dt, ax, ay, (
      ENEMY_SPEED_LIMIT * (ENEMY_MIN_SIZE / enemy.r))

  doPhysics: (dt) =>
    # Start by iterating through all of the players and updating their position
    for id, index of @players
      @movePlayer @entities[index], dt

    bulletsToRemove = []
    for id, index of @bullets
      if @moveBullet @entities[index], dt
        bulletsToRemove.push id

    for id in bulletsToRemove
      @deleteEntity(id, @bullets)

    # Process the bullet collisions
    enemiesToDelete = {}
    bulletsToRemove = []
    for id, index of @bullets
      bullet = @entities[index]
      if bullet.ownerType == 'player'
        for eid, enemyIndex of @enemies
          enemy = @entities[enemyIndex]
          if eid of enemiesToDelete
            continue

          if @collides enemy, bullet
            bulletsToRemove.push id
            if @shrinkEntity enemy, bullet
              enemiesToDelete[eid] = true
              if bullet.ownerId of @players
                @growPlayer bullet.ownerId
      else if bullet.ownerType == 'enemy'
        for pid, playerIndex of @players
          player = @entities[playerIndex]
          if @collides player, bullet
            bulletsToRemove.push id
            if @shrinkEntity player, bullet
              # player died
              @deleteEntity(pid, @players)
              @createPlayer(pid)

    for id of enemiesToDelete
      @deleteEntity(id, @enemies)

    for id in bulletsToRemove
      @deleteEntity(id, @bullets)

    for id, index of @enemies
      @enemyAI @entities[index]

    for id, index of @enemies
      @moveEnemy @entities[index], dt

    # Process the player to enemy collisions
    for pid, playerIndex of @players
      player = @entities[playerIndex]
      for eid, enemyIndex of @enemies
        enemy = @entities[enemyIndex]
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
