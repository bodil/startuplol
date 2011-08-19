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

# Nth root solver - no built-in cube root in JS ;(

nth_root = (num, nArg, precArg) ->
  n = nArg || 2
  prec = precArg || 12
  x = 1
  for i in [0..prec-1]
    x = 1/n * ((n-1)*x + (num / Math.pow(x, n-1)))
  x

cube_root = (n) -> nth_root n, 3

exports.square_and_cube = (n) ->
  (Math.floor(Math.sqrt n) * Math.floor(Math.sqrt n) == n) && (Math.floor(cube_root n) * Math.floor(cube_root n))

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


