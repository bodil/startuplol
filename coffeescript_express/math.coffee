# Optimised Fibonacci (stolen from the internets)

MAXIMUM_JS_FIB_N = 1476

divmodBasic = (x, y) ->
	return [(q = Math.floor x/y), (r = if x < y then x else x % y)]

fib_bits = (n) ->
	bits = []
	while n > 0
    	[n, bit] = divmodBasic n, 2
    	bits.push bit
  	bits.reverse()
  	return bits

exports.fibFast = (n) ->
	if n < 0
		return
	[a, b, c] = [1, 0, 1]
	for bit in fib_bits n
	    if bit
	    	[a, b] = [(a+c)*b, b*b + c*c]
	    else
	    	[a, b] = [a*a + b*b, (a+c)*b]
	    c = a + b
	  	return b

# JS has no cube root function, but we can still check if a number is a cube.
# Math.pow n, 1/3 would give us the cube root, but stupid IEEE-754 gives a rounding error.
# It's going to be close to the correct answer, so we round it to the nearest integer
# and check if the cube of the rounded result equals the number we're checking.
# If they match, the number is a cube.
is_cube = (n) ->
  a = Math.round Math.pow n, 1/3
  n == a * a * a

# On the other hand, JS has a square root function, so let's do this one the easy way.
is_integer = (n) -> n == Math.floor n
is_square = (n) -> is_integer Math.sqrt n

exports.square_and_cube = (n) -> (is_square n) and (is_cube n)

# Dumb prime checker

exports.is_prime = (n) ->
  if n < 4
    return true
  if n % 2 == 0
    return false
  for i in [3..(n - 1)]
    if n % i == 0
      return false
  true


