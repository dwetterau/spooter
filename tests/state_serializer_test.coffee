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
      assert.equal array.byteLength, 4

      convertedObject = serializer.toObject(array, {})

      assert.equal JSON.stringify(object), JSON.stringify(convertedObject)

    it 'should convert state with some entities back and forth', ->
      object = {
        numEntities: 3
        entities: [
          {
            x: 0.0
            y: 4.0
            vx: 2.0
            vy: 8.0
            r: 2.5
            id: 0
            type: 'player'
          },
          {
            x: 1.0
            y: 2.0
            vx: 3.0
            vy: 4.0
            r: 5.0
            id: 1
            type: 'enemy'
          },
          {
            x: 0.5
            y: 0.25
            vx: 0.125
            vy: 0.25
            r: 0.5
            id: 2
            type: 'bullet'
          }
        ]
      }

      array = serializer.toArray(object)

      # Should only have 4 + (28 * 3) bytes
      assert.equal array.byteLength, 4 + (28 * 3)

      convertedObject = serializer.toObject(array, {})

      assert.equal JSON.stringify(object), JSON.stringify(convertedObject)
