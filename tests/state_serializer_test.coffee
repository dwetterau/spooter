assert = require 'assert'

StateSerializer = require('../public/javascripts/common/state_serializer')
serializer = null

describe 'StateSerializer', ->
  before ->
    serializer = new StateSerializer()

  describe 'integer conversion', ->
    it 'should convert integers to 4 bytes and back', ->
      testNumber = (number) ->
        bytes = serializer._intToBytes number, 4
        convertedNumber = serializer._bytesToInt bytes, 4
        assert.equal bytes.length, 4
        assert.equal number, convertedNumber

      testNumber 0x7ABBCCDD
      testNumber 0x00BBCCDD
      testNumber 0x7ABBCC00
      testNumber 0x00000000

    it 'should convert integers to 3 bytes and back', ->
      testNumber = (number) ->
        bytes = serializer._intToBytes number, 3
        convertedNumber = serializer._bytesToInt bytes, 3
        assert.equal bytes.length, 3
        assert.equal number, convertedNumber

      testNumber 0x7ABBCC
      testNumber 0x00BBCC
      testNumber 0x7ABBCC
      testNumber 0x000000

    it 'should convert integers to 1 byte and back', ->
      testNumber = (number) ->
        bytes = serializer._intToBytes number, 1
        convertedNumber = serializer._bytesToInt bytes, 1
        assert.equal bytes.length, 1
        assert.equal number, convertedNumber

      testNumber 0x7A
      testNumber 0xBB
      testNumber 0x01
      testNumber 0x00

  describe 'float conversion', ->
    it 'should convert floats to bytes and back', ->
      testNumber = (number) ->
        number = parseFloat number
        bytes = serializer._floatToBytes number
        convertedNumber = serializer._bytesToFloat bytes
        assert Math.abs((number - convertedNumber) / convertedNumber) < 1e-5

      testNumber 12345.12134
      testNumber 1e32
      testNumber 2.5

  describe 'state serialization', ->
    it 'should convert state without entities back and forth', ->
      object = {
        entities: []
      }
      serializer.setObject object
      array = serializer.toArray()

      # Should only have 4 bytes with the length
      assert.equal array.byteLength, 4

      serializer.setArray array
      convertedObject = serializer.toObject()

      assert.equal JSON.stringify(object), JSON.stringify(convertedObject)

    it 'should convert state with some entities back and forth', ->
      object = {
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

      serializer.setObject object
      array = serializer.toArray()

      # Should only have 4 + (24 * 3) bytes
      assert.equal array.byteLength, 4 + (24 * 3)

      serializer.setArray array
      convertedObject = serializer.toObject()

      assert.equal JSON.stringify(object), JSON.stringify(convertedObject)
