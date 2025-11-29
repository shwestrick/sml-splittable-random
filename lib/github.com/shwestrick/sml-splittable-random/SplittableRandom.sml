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

end =
struct

  type w64 = Word64.word
  type w32 = Word32.word

  datatype rand = Rand of {seed: w64, gamma: w64}
  type t = rand

  val golden_gamma: w64 = 0wx9e3779b97f4a7c15

  structure Internal =
  struct

    fun new (seed, gamma) =
      Rand {seed = seed + gamma, gamma = gamma}

    fun advance (Rand {seed, gamma}) =
      (Rand {seed = seed + gamma, gamma = gamma}, seed)

    fun nth_seed (Rand {seed, gamma}) i =
      seed + Word64.* (i, gamma)

    fun jump (Rand {seed, gamma}) i =
      Rand {seed = seed + Word64.* (i, gamma), gamma = gamma}

    local
      open Mixers.FromJavaSrc
    in
      val mix64 = mix64
      val mix32 = mix32
      val mix_gamma = mix_gamma
    end

  end


  fun new seed =
    Internal.new (Word64.fromInt seed, golden_gamma)


  fun split r =
    let
      val (r, seed1) = Internal.advance r
      val (r, seed2) = Internal.advance r
      val newr =
        Internal.new (Internal.mix64 seed1, Internal.mix_gamma seed2)
    in
      (r, newr)
    end


  fun split_many r =
    let
      val (r, new_r) = split r

      fun gen i =
        let
          val i = Word64.fromInt i
          val seed1 = Internal.nth_seed new_r (0w2 * i)
          val seed2 = Internal.nth_seed new_r (0w2 * i + 0w1)
        in
          Internal.new (Internal.mix64 seed1, Internal.mix_gamma seed2)
        end
    in
      (r, gen)
    end


  fun gen_w32 (r: rand) : rand * w32 =
    let val (r, w) = Internal.advance r
    in (r, Internal.mix32 w)
    end


  fun gen_many_w32 r =
    let
      val (r, new_r) = split r
      fun gen i =
        Internal.mix32 (Internal.nth_seed new_r (Word64.fromInt i))
    in
      (r, gen)
    end


  fun gen_w64 (r: rand) : rand * w64 =
    let val (r, w) = Internal.advance r
    in (r, Internal.mix64 w)
    end


  fun gen_many_w64 r =
    let
      val (r, new_r) = split r
      fun gen i =
        Internal.mix64 (Internal.nth_seed new_r (Word64.fromInt i))
    in
      (r, gen)
    end


  val int_sign_bit_pos: word =
    case Int.precision of
      NONE => 0w63
    | SOME p =>
        if p >= 64 then
          0w63
        else
          Word.fromInt (p - 1)

  val int_shifter =
    case Int.minInt of
      NONE => Int64.toInt (valOf Int64.minInt)
    | SOME mi => mi


  fun into_int w =
    let
      val sign_bit_mask = Word64.<< (0w1, int_sign_bit_pos)
      val top = Word64.andb (sign_bit_mask, w)
      val bottom = Word64.andb (Word64.- (sign_bit_mask, 0w1), w)
      val x = Word64.toIntX bottom
    in
      if top > 0w0 then x + int_shifter else x
    end


  fun gen_int (r: rand) : rand * int =
    let val (r, w) = Internal.advance r
    in (r, into_int (Internal.mix64 w))
    end


  fun gen_many_int r =
    let
      val (r, new_r) = split r
      fun gen i =
        into_int (Internal.mix64 (Internal.nth_seed new_r (Word64.fromInt i)))
    in
      (r, gen)
    end


  fun gen_int_in_range r (lo, hi) =
    if lo >= hi then
      raise Fail "SplittableRandom.gen_int_in_range: error: lo >= hi"
    else
      let
        val wlo = Word64.fromInt lo
        val whi = Word64.fromInt hi
        val n = whi - wlo

        val (r, w) = gen_w64 r
        val w = Word64.+ (wlo, Word64.mod (w, n))
      in
        (r, into_int w)
      end


  fun gen_many_int_in_range r (lo, hi) =
    if lo >= hi then
      raise Fail "SplittableRandom.gen_many_int_in_range: error: lo >= hi"
    else
      let
        val wlo = Word64.fromInt lo
        val whi = Word64.fromInt hi
        val n = whi - wlo

        val (r, new_r) = split r

        fun gen i =
          let
            val w = Internal.mix64 (Internal.nth_seed new_r (Word64.fromInt i))
          in
            into_int (Word64.+ (wlo, Word64.mod (w, n)))
          end
      in
        (r, gen)
      end


  val double_ulp: Real64.real =
    1.0 / (Real64.fromInt (Word64.toIntX (Word64.<< (0w1, 0w53))))


  fun gen_real r =
    let
      val (r, w) = gen_w64 r
      val x = Real64.fromInt (Word64.toIntX (Word64.>> (w, 0w11))) * double_ulp
    in
      (r, Real.fromLarge IEEEReal.TO_NEAREST x)
    end


  fun gen_many_real r =
    let
      val (r, new_r) = split r
      fun gen i =
        let
          val w = Internal.mix64 (Internal.nth_seed new_r (Word64.fromInt i))
          val x =
            Real64.fromInt (Word64.toIntX (Word64.>> (w, 0w11))) * double_ulp
        in
          Real.fromLarge IEEEReal.TO_NEAREST x
        end
    in
      (r, gen)
    end


end
