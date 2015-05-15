class StateSerializer
  constructor: ->
    @array = null
    @object = null

  setArray: (byteArray) ->
    @array = byteArray

  setObject: (object) ->
    @object = object

  # Serialized format:
  #   4 byte int -> number of entities
  #  24 bytes for each entity:
  #     4 byte floats for x, y, vx, vy, r
  #     3 byte int for id
  #     1 byte for type

  toArray: ->
    numEntities = @object.entities.length;
    size = 4 + (24 * numEntities)
    buffer = new ArrayBuffer(size)
    byteView = new Uint8Array(buffer)

    # Write in the number of entities first
    numEntitiesBytes = @_intToBytes numEntities, 4
    offset = 0
    for i in [0..3]
      byteView[offset++] = numEntitiesBytes[i]

    # Convert each entity to the packed form
    for entity in @object.entities
      writeFloat = (float) =>
        floatBytes = @_floatToBytes float
        for i in [0..3]
          byteView[offset++] = floatBytes[i]

      writeFloat entity.x
      writeFloat entity.y
      writeFloat entity.vx
      writeFloat entity.vy
      writeFloat entity.r

      # Write the 3 id bytes
      intBytes = @_intToBytes entity.id, 3
      for i in [0..2]
        byteView[offset++] = intBytes[i]

      # Write the 1 type byte
      typeByte = @_typeToByte entity.type
      byteView[offset++] = typeByte[0]

    return buffer

  toObject: ->
    # get the number of entities out of the buffer first
    numEntitiesBytes = @_copyToBytes @array, 0, 4
    numEntities = @_bytesToInt numEntitiesBytes, 4
    offset = 4
    entities = new Array(numEntities)
    for i in [0...numEntities]
      readFloat = () =>
        floatBytes = @_copyToBytes @array, offset, offset + 4
        offset += 4
        return @_bytesToFloat floatBytes

      x = readFloat()
      y = readFloat()
      vx = readFloat()
      vy = readFloat()
      r = readFloat()

      int3Bytes = @_copyToBytes @array, offset, offset + 3
      offset += 3
      id = @_bytesToInt int3Bytes, 3

      typeByte = @_copyToBytes @array, offset, offset + 1
      offset += 1
      type = @_byteToType typeByte

      entities[i] = {
        x, y, vx, vy, r, id, type
      }
    return {entities}

  _copyToBytes: (buffer, start, end) ->
    bytes = new Uint8Array(end - start);
    offset = 0
    for i in [start...end]
      bytes[offset++] = buffer[i]
    return bytes

  # Warning: doesn't handle negative numbers!
  _intToBytes: (integer, numBytes) ->
    buffer = new ArrayBuffer(4)
    intView = new Int32Array(buffer)
    bytes = new Uint8Array(buffer)
    intView[0] = integer

    if numBytes == 4
      return bytes

    toReturn = new Uint8Array(numBytes)
    for i in [0..numBytes]
      toReturn[i] = bytes[i]
    return toReturn

  _bytesToInt: (bytes, numBytes) ->
    buffer = new ArrayBuffer(4)
    viewBytes = new Uint8Array(buffer)
    intView = new Int32Array(buffer)

    for i in [0..numBytes]
      viewBytes[i] = bytes[i]

    return intView[0]

  _floatToBytes: (float) ->
    buffer = new ArrayBuffer(4)
    floatView = new Float32Array(buffer)
    bytes = new Uint8Array(buffer)
    floatView[0] = float
    return bytes

  _bytesToFloat: (bytes) ->
    buffer = new ArrayBuffer(4)
    viewBytes = new Uint8Array(buffer)
    floatView = new Float32Array(buffer)


    for i in [0..3]
      viewBytes[i] = bytes[i]

    return floatView[0]

  _typeToByte: (type) ->
    integer = 127
    if type == 'player'
      integer = 0
    else if type == 'enemy'
      integer = 1
    else if type =='bullet'
      integer = 2

    return @_intToBytes integer, 1

  _byteToType: (byte) ->
    integer = @_bytesToInt byte, 1
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
