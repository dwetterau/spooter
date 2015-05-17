class StateSerializer
  constructor: ->

  # Serialized format:
  #   4 byte int -> number of entities
  #  28 bytes for each entity:
  #     4 byte floats for x, y, vx, vy, r
  #     4 byte int for id
  #     4 byte for type

  toArray: (object) ->
    numEntities = object.numEntities;
    size = 4 + (28 * numEntities)
    buffer = new ArrayBuffer(size)
    floatView = new Float32Array(buffer)
    intView = new Int32Array(buffer)

    # Write in the number of entities first
    offset = 0
    intView[offset++] = numEntities

    # Convert each entity to the packed form
    for i in [0...numEntities]
      entity = object.entities[i]
      floatView[offset++] = entity.x
      floatView[offset++] = entity.y
      floatView[offset++] = entity.vx
      floatView[offset++] = entity.vy
      floatView[offset++] = entity.r

      intView[offset++] = entity.id
      intView[offset++] = @_typeToInt entity.type

    return buffer

  toObject: (arrayBuffer, object) ->
    floatView = new Float32Array(arrayBuffer)
    intView = new Int32Array(arrayBuffer)

    # get the number of entities out of the buffer first
    offset = 0
    numEntities = intView[offset++]
    object.numEntities = numEntities
    if not object.entities?
      object.entities = new Array(numEntities)

    entities = object.entities
    for i in [0...numEntities]
      x = floatView[offset++]
      y = floatView[offset++]
      vx = floatView[offset++]
      vy = floatView[offset++]
      r = floatView[offset++]

      id = intView[offset++]
      type = @_intToType intView[offset++]

      entities[i] = {
        x, y, vx, vy, r, id, type
      }
    return object

  _typeToInt: (type) ->
    integer = -1
    if type == 'player'
      integer = 0
    else if type == 'enemy'
      integer = 1
    else if type =='bullet'
      integer = 2

    return integer

  _intToType: (integer) ->
    if integer == 0
      return 'player'
    else if integer == 1
      return 'enemy'
    else if integer ==  2
      return 'bullet'
    return 'UNKNOWN TYPE'

# TODO: user browserify and make it not hacky
if window?
  window.spooter.StateSerializer = StateSerializer

if module?
  module.exports = StateSerializer
