# Obel Final Stretch Surface Spec

This draft locks the remaining small core additions before `0.1.0`:

```clojure
(map f coll)
(filter pred coll)
(reduce f start coll)
(find pred coll)
(pick f coll)

(fn (a b . rest)
  body...)
```

## Higher-Order Collection Functions

These are ordinary built-in functions, not special forms.

They do not introduce bindings.

They call their function argument using normal Obel call rules.

If the function argument is not callable, this is a runtime error.

If the callback receives too few arguments, normal Obel missing-argument behavior applies.

If the callback receives too many arguments, normal Obel extra-argument behavior applies.

These functions enforce their own built-in arity:

```text
(map f coll)          ; exactly 2 args
(filter pred coll)    ; exactly 2 args
(reduce f start coll) ; exactly 3 args
(find pred coll)      ; exactly 2 args
(pick f coll)         ; exactly 2 args
```

`coll` must be a vector or map.

## Collection Input

`coll` may be a vector or map.

### Vector Input

For vector input, the item is each vector value in index order.

```clojure
(map f [1 2 3])
```

calls:

```clojure
(f 1)
(f 2)
(f 3)
```

### Map Input

For map input, the item is a snapshot entry:

```clojure
[key value]
```

Map order is unspecified.

Map HOF traversal is snapshot-style, equivalent to using `(pairs m)`.

```clojure
(map f m)
```

is semantically like:

```clojure
(map f (pairs m))
```

The map snapshot is made before callback calls begin.

Each entry is a fresh `[key value]` vector.

Mutating an entry vector does not mutate the original map.

The key and value inside the entry are ordinary Obel values. Mutable vector and map values remain shared objects.

The callback receives one argument: the entry vector.

It does not receive key and value as separate arguments.

```clojure
(map
  (fn (entry)
    (def [k v] entry)
    ...)
  m)
```

This keeps callback arity uniform:

```text
vector input -> f(item)
map input    -> f(entry)
```

Direct live map traversal remains the job of `each`:

```clojure
(each [k v] m
  ...)
```

## `map`

```clojure
(map f coll)
```

Transforms each item.

Returns a fresh vector containing each result.

Vector example:

```clojure
(map
  (fn (x) (* x 2))
  [1 2 3])
; [2 4 6]
```

Map example:

```clojure
(map
  (fn (entry)
    (def [k v] entry)
    (str k "=" v))
  {:a 1 :b 2})
; vector of strings, order unspecified
```

## `filter`

```clojure
(filter pred coll)
```

Keeps items where `pred(item)` returns truthy.

Returns a fresh vector of the original items.

Vector example:

```clojure
(filter
  (fn (x) (> x 0))
  [-1 2 -3 4])
; [2 4]
```

Map example:

```clojure
(filter
  (fn (entry)
    (def [k v] entry)
    (> v 10))
  scores)
; vector of [key value] entries, order unspecified
```

## `reduce`

```clojure
(reduce f start coll)
```

Carries one running result through the collection.

The running result starts as `start`.

For each item:

```clojure
(set result (f result item))
```

After all items are processed, `reduce` returns the final result.

Empty collection returns `start`.

Vector example:

```clojure
(reduce + 0 [1 2 3])
; 6
```

Map example:

```clojure
(reduce
  (fn (result entry)
    (def [k v] entry)
    (set (key result k) (* v 2))
    result)
  {}
  {:a 1 :b 2})
; map with doubled values, order irrelevant
```

`reduce` always requires an explicit `start` value.

There is no no-start reduce form.

## `find`

```clojure
(find pred coll)
```

Returns the first original item where `pred(item)` returns truthy.

Returns `nil` if nothing matches.

`find` stops at the first match.

No later callback calls are made.

For map input, "first" means first in the snapshot's unspecified map order.

Vector example:

```clojure
(find
  (fn (x) (> x 3))
  [1 2 4 5])
; 4
```

Map example:

```clojure
(find
  (fn (entry)
    (def [k v] entry)
    (> v 10))
  scores)
; first matching [key value] entry, or nil
```

`find` returns the item, not the predicate result.

## `pick`

```clojure
(pick f coll)
```

Returns the first truthy value produced by `f(item)`.

Returns `nil` if no call produces a truthy value.

`pick` stops at the first truthy produced value.

No later callback calls are made.

For map input, "first" means first in the snapshot's unspecified map order.

Vector example:

```clojure
(pick
  (fn (guy)
    (if (> (key guy :hp) 0)
      (key guy :name)
      nil))
  guys)
; first living guy name, or nil
```

Map example:

```clojure
(pick
  (fn (entry)
    (def [k v] entry)
    (if (> v 10)
      k
      nil))
  scores)
; first key whose value is greater than 10, or nil
```

`pick` differs from `find`:

```text
find returns the original item.
pick returns the produced value.
```

## Mutation During HOF Traversal

HOF traversal is value-producing traversal.

The HOF itself does not mutate the input collection.

The callback may perform side effects because Obel is mutable.

For vector input:

```text
The vector is evaluated once.
The initial vector length is used.
Items are read when reached.
Changing an existing vector item before it is reached changes the value the HOF sees.
Appending during traversal does not visit appended items.
Removing items during traversal may make a later read error.
```

For map input:

```text
Map HOF traversal uses snapshot entries, equivalent to `(pairs m)`.
Changing the original map during traversal does not change which entries are visited.
```

Use `each` or `while` for live mutation-heavy traversal.

## Rest Arguments

Rest args let a function collect extra arguments into one vector.

```clojure
(fn (a b . rest)
  body...)
```

Named functions use the same parameter rules:

```clojure
(def (f a b . rest)
  body...)
```

Fixed params bind normally.

The rest param receives a fresh vector of extra arguments.

```clojure
(def (pack a b . rest)
  [a b rest])

(pack 1)
; [1 nil []]

(pack 1 2)
; [1 2 []]

(pack 1 2 3 4)
; [1 2 [3 4]]
```

## Rest Parameter Rules

`.` is valid only as the rest marker in function parameter lists.

Outside that position, `.` is a reserved symbol and cannot be used as a binding.

This is invalid:

```clojure
(def . 1)
```

A rest marker must be followed by exactly one parameter symbol.

The rest parameter must be the final parameter.

Only one rest marker is allowed.

The rest parameter is a normal function parameter binding.

It has the same mutability rule as other parameters.

Duplicate parameter names are errors, including the rest parameter name.

Valid:

```clojure
(fn (a b . rest)
  body...)

(fn (. args)
  body...)
```

`(fn (. args) ...)` means all supplied arguments are collected into `args`.

Invalid:

```clojure
(fn (a b .)
  body...)

(fn (a b . rest more)
  body...)

(fn (a b . rest . more)
  body...)

(fn (a a . rest)
  body...)

(fn (a b . a)
  body...)
```

## Call Rules With Rest Args

Without a rest parameter:

```text
missing args bind nil
extra args are a runtime error
```

With a rest parameter:

```text
missing fixed args still bind nil
extra args are collected into the rest vector
extra args are not an error
```

Examples:

```clojure
(def (f a b . rest)
  [a b rest])

(f)
; [nil nil []]

(f 1)
; [1 nil []]

(f 1 2)
; [1 2 []]

(f 1 2 3)
; [1 2 [3]]
```

The rest vector is fresh per call.

Mutating the rest vector does not mutate the caller's argument list.
