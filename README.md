# sml-splittable-random

Splittable, pseudo-random generator in Standard ML, based on SplitMix by
Steele, Lea, and Flood (https://gee.cs.oswego.edu/dl/papers/oopsla14.pdf).
This generator is optimized for efficiency, and is suitable for general
pseudo-randomness, such as in the implementation of randomized algorithms or
random testing.

This library should **not** be used for any cryptographic purposes.

Splitting is useful for divide-and-conquer-style code, especially
parallel algorithms, where multiple generators can be used independently
in two or more subtasks. Splitting also conveniently allows for generating
unbounded streams of pseudo-random values.

The SplitMix algorithm is
the basis of Java's `java.util.SplittableRandom` class. The
`sml-splittable-random` library has been checked against
`java.util.SplittableRandom`: on the same seed, the two implementations
produce exactly the same values.
See [`compare-java/`](./compare-java). (Last checked 11-29-2025,
Java version `24.0.1`.)

Compatible with the [`smlpkg`](https://github.com/diku-dk/smlpkg)
package manager.

# Library sources

Three source files:

* `lib/github.com/shwestrick/sml-splittable-random/sources.mlb`
* `lib/github.com/shwestrick/sml-splittable-random/sources.cm`
* `lib/github.com/shwestrick/sml-splittable-random/sources.not-mlton.mlb`

The `.mlb` file is for use with [MLton](http://mlton.org/)
or [MaPLe](https://github.com/mpllang/mpl); these use MLton-based features for
improved efficiency. The `.not-mlton.mlb` file can be used for other
implementations. The `.cm` file is for
use with SML/NJ. All have the same interface, described below.

# Interface

The full interface is shown below. A fresh generator can be instantiated with
`new s` where `s` is some seed. Note that all generators constructed in this
way have the same initial `gamma` (the stride in the SplitMix algorithm).

This library is purely functional. Each value
`r: rand` is a generator, and "using" a generator returns a new generator.
Typical usage therefore should be in a linear style. You should only "use"
each generator exactly once, to guarantee you don't get the same pseudo-random
value multiple times.

```sml
val r = new seed
val (r, a: Word64.word) = gen_w64 r
val (r, b: real) = gen_real r
val (r, i: int) = gen_int r
```

A generator can be split into two independent generators with the `split`
function. Use `split_many` to produce many independent generators. This
produces a function `g: int -> rand` where `g i` is the ith generator.
For every `i >= 0`, the generator `g i` will be fresh (producing different
output from the original input generator, and also different from any other
`g j`) with high probability. Note that the indices `i` should be at least 0, 
but can be arbitrarily large.

```sml
(* split into two generators *)
val (r, r') = split r

(* both r and r' are now usable *)
val (r, x) = gen_int r    
val (r', x') = gen_int r' 

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
val (r, x) = gen_real r    (* new version of r is still usable *)
val (r', x') = gen_real r' (* r' is also still usable *)
```

Generators for base types come in two flavors: individual, and
"many". The "many" versions return functions of type `int -> ...`,
used in the same manner as described above.

```sml
structure SplittableRandom:
sig
  type t
  type rand = t

  type w64 = Word64.word
  type w32 = Word32.word
  type r64 = Real64.real

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

  val gen_r64: rand -> rand * r64
  val gen_many_r64: rand -> rand * (int -> r64)
end
```