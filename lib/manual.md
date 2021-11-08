# JLP manual

## Evaluation

There is an `Evaluator` class, which handles state and has an `eval` function.

`eval(x)` should return...
- `x` if `x` is a number/bool/null
- "Resolve" `x` if `x` is a string
- "Run" `x` if `x` is a list

### Resolution:

- `"'asd'"` should resolve to the string `"asd"`.
- `"&asd"` should resolve to the variable named `asd`.
- if `"x"` in `"xasd"` is alphanumerical, it should resolve as-is

If no rule matches, it should just return the string as-is.

### Running:

`eval([head, par0, par1, ...])` should return... 
- First, save `head` to `"funlist"` and `[par0, par1, ...]` to `"parlist"`.
- If `head` is a string...
  1. try resolving it. On success, repeat from the beginning.
  2. find referenced function. If found run it.
  3. find base function, and run it.
  4. error?
- If `head` is a list...
  1. and `["lambda" ...]`, eval parameters, and run lambda.
  2. and `["macro" ...]`, run with raw parameters, the eval the returned function.
  3. error?

  
## Base function list

A `:` character before the name makes the call "macro"-like: does not evaluate the parameters. 

### Memory handling
#### `[":define", name, value]`
Stores `value` in the `name` cell.

#### `[":resolve", name]`
Returns the value stored at `name`.

#### `[new_scope]` and `[del_scope]`
Creates and removes a new variable scope.

#### `[":up", name, times?]`
Sends `name` to a `times` (or 1) higher scope.

### Execution control

#### `["do", par0, par1, ...]`
Run `eval(par0)`, then `eval(par1)`, etc. Return the last element

#### `[":if", cond, succ, fail]`

If `eval(cond)` is bool, and it is true, returns `eval(succ)`.

If `eval(cond)` is bool, and it is false, returns `eval(fail)`.
(If there are only two parameters, returns `null`).

#### `[":while", cond, body]`

While `eval(cond)` is true, run `eval(body)`. Return the last value.

### Element creators
- `[":pass", a]` returns `a`, wtihout evaling it.
- `["pass", a]` returns `eval(a)`
- `[":string", a]` returns `a.toString()`
- `[":point", a]` returns `"&" + a`
- `[":list", a, b, c]` returns `[a, b, c]`
- `[":dict", a, b, c, d]` returns `{a: b, c: d}`

### Operator calls
- `[":add", a, b]` returns `a + b`
- `[":sub", a, b]` returns `a - b`
- `[":mul", a, b]` returns `a * b`
- `[":div", a, b]` returns `a / b`
- `[":mod", a, b]` returns `a % b`
- `[":eq", a, b]` returns `a == b`
- `[":less", a, b]` returns `a < b`
- `[":greater", a, b]` returns `a > b`
- `[":not", a]` returns `!a`
- `[":or", a, b]` returns `a | b`
- `[":and", a, b]` returns `a & b`
- `[":ind", a, b]` returns `a[b]`