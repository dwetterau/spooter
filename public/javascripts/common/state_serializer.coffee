class StateSerializer
  constructor: ->

  # Serialized format:
  #   2 byte int -> number of entities
  #  12 bytes for each entity:
  #     2x2 byte integers for x, y,
  #     2x2 byte integers for vx, vy
  #     2 byte int for id
  #     1 byte integer for r
  #     1 byte int for type

  toArray: (object) ->
    numEntities = object.numEntities;
    size = 2 + (12 * numEntities)
    buffer = new ArrayBuffer(size)
    uint16View = new Uint16Array(buffer)
    int16View = new Int16Array(buffer)
    uint8View = new Uint8Array(buffer)

    # Write in the number of entities first
    offset = 0
    uint16View[offset++] = numEntities

    # Convert each entity to the packed form
    for i in [0...numEntities]
      entity = object.entities[i]
      uint16View[offset++] = entity.x
      uint16View[offset++] = entity.y
      int16View[offset++] = entity.vx
      int16View[offset++] = entity.vy

      uint16View[offset++] = entity.id
      uint8View[offset << 1] = entity.r
      uint8View[(offset << 1) + 1] = @_typeToInt entity.type
      offset++

    return buffer

  toObject: (arrayBuffer, object) ->
    uint16View = new Uint16Array(arrayBuffer)
    int16View = new Int16Array(arrayBuffer)
    uint8View = new Uint8Array(arrayBuffer)

    # get the number of entities out of the buffer first
    offset = 0
    numEntities = uint16View[offset++]
    object.numEntities = numEntities
    if not object.entities?
      object.entities = new Array(numEntities)

    entities = object.entities
    for i in [0...numEntities]
      x = uint16View[offset++]
      y = uint16View[offset++]
      vx = int16View[offset++]
      vy = int16View[offset++]
      id = uint16View[offset++]

      r = uint8View[offset << 1]
      type = @_intToType uint8View[(offset << 1) + 1]
      offset++

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
