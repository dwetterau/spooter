assert = require 'assert'

StateSerializer = require('../public/javascripts/common/state_serializer')
serializer = null

describe 'StateSerializer', ->
  before ->
    serializer = new StateSerializer()

  describe 'state serialization', ->
    it 'should convert state without entities back and forth', ->
      object = {
        numEntities: 0
        entities: []
      }
      array = serializer.toArray(object)

      # Should only have 4 bytes with the length
      assert.equal array.byteLength, 2

      convertedObject = serializer.toObject(array, {})

      assert.equal JSON.stringify(object), JSON.stringify(convertedObject)

    it 'should convert state with some entities back and forth', ->
      object = {
        numEntities: 3
        entities: [
          {
            x: 0
            y: 4
            vx: 2
            vy: 65535
            r: 255
            id: 255
            type: 'player'
          },
          {
            x: 1
            y: 2
            vx: 3
            vy: 4
            r: 5
            id: 1
            type: 'enemy'
          },
          {
            x: 65535
            y: 65535
            vx: 0
            vy: 0
            r: 0
            id: 0
            type: 'bullet'
          }
        ]
      }

      array = serializer.toArray(object)

      # Should only have 2 + (12 * 3) bytes
      assert.equal array.byteLength, 2 + (12 * 3)

      convertedObject = serializer.toObject(array, {})

      assert.equal JSON.stringify(object), JSON.stringify(convertedObject)
