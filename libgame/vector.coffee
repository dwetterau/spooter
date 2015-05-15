class Vector
  constructor: (@a, @b) ->

  fromAngle: (theta, magnitude) ->
    @a = magnitutde * Math.cos theta
    @b = magnitutde * Math.sin theta

  addVector: (v) ->
    @a += v.a
    @b += v.b

  dot: (v) ->
    @a * v.a + @b * v.b

  project: (v) ->
    overlap = @dot(v) / v.dot(v)
    new Vector(v.a * overlap, v.b * overlap)

  getMagnitude: ->
    Math.sqrt(@a * @a + @b * @b)

  normalize: ->
    mag = @getMagnitude()
    @a /= mag
    @b /= mag

  reverse: ->
    @a = -@a
    @b = -@b

  makeMagnitude: (newMag) ->
    mag = @getMagnitude()
    @a *= newMag / mag
    @b *= newMag / mag

  scaleInPlace: (factor) ->
    @a *= factor
    @b *= factor

  scaledVector: (factor) ->
    return new Vector(@a * factor, @b * factor)

module.exports = Vector
