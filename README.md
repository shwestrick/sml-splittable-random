# sml-splittable-random

Splittable pseudo-random generator in Standard ML, based on SplitMix by
Steele, Lea, and Flood (https://gee.cs.oswego.edu/dl/papers/oopsla14.pdf).
The generated output exactly matches Java 24.0.1.
See [`compare-java/`](./compare-java).

Compatible with the [`smlpkg`](https://github.com/diku-dk/smlpkg)
package manager.

# Library sources

Two source files:

* `lib/github.com/shwestrick/sml-splittable-random/sources.mlb`
* `lib/github.com/shwestrick/sml-splittable-random/sources.cm`

The `.mlb` file is for use with [MLton](http://mlton.org/)
or [MaPLe](https://github.com/mpllang/mpl). The `.cm` file is for use
with SML/NJ. All have the same interface, described below.

# Interface

A fresh generator can be instantiated with `new s` where `s` is some seed.
Note that all generators constructed in this way have the same initial
`gamma` (the stride in the SplitMix algorithm).

Basic usage is in a linear style: you should "use" each generator exactly
once:

```sml
val r = new seed
val (r, a: Word64.word) = gen_w64 r
val (r, b: real) = gen_real r
val (r, i: int) = gen_int r
```

A generator can be split into two independent generators with the `split`
function. Use `split_many` to produce many independent generators. This
produces a function `g: int -> rand` where `g i` is the ith generator.
Here, `i` should be at least 0, but can be arbitrarily large.

```sml
(* split into two generators *)
val (r, r') = split r

(* split into many generators *)
val (r, g) = split_many r
val xs = List.tabulate (1000, fn i =>
  let
    val r' = g i
  in
    ... (* use r' *)
  end)

(* splitting always returns a new version of
 * the original generator which can be used freely.
 *)
val (r, x) = gen_real r
val (r', x') = gen_real r'
```

Similarly, generators for base types come in two flavors: individual, and
"many". The "many" versions return functions of type `int -> ...`,
used in the same manner as described above.

```sml
structure SplittableRandom:
sig
  type t
  type rand = t

  type w64 = Word64.word
  type w32 = Word32.word

  (* construction and splitting *)

  val new: int -> rand
  val split: rand -> rand * rand
  val split_many: rand -> rand * (int -> rand)

  (* generators *)

  val gen_w32: rand -> rand * w32
  val gen_many_w32: rand -> rand * (int -> w32)

  val gen_w64: rand -> rand * w64
  val gen_many_w64: rand -> rand * (int -> w64)

  val gen_int: rand -> rand * int
  val gen_many_int: rand -> rand * (int -> int)

  val gen_int_in_range: rand -> int * int -> rand * int
  val gen_many_int_in_range: rand -> int * int -> rand * (int -> int)

  val gen_real: rand -> rand * real
  val gen_many_real: rand -> rand * (int -> real)
end
```