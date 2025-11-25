structure SplittableRandom:
sig
  type t
  type rand = t
  type w64 = Word64.word
  type w32 = Word32.word

  val new: int -> rand


  val gen_w64: rand -> rand * w64
  val gen_int_in_range: rand -> int * int -> rand * int

  val gen_many_w64: rand -> rand * (int -> w64)
  val gen_many_int_in_range: rand -> int * int -> rand * (int -> int)

  (*
  val gen_real_in_range: rand -> real * real -> rand * real
  val gen_bool: rand -> rand * bool
  *)

  val split: rand -> rand * rand
  val split_many: rand -> rand * (int -> rand)


  structure Internal:
  sig
    val new_from_seed_and_gamma: w64 * w64 -> rand
    val mix64: w64 -> w64
    val mix64_variant13: w64 -> w64
    val mix32: w64 -> w32
    val mix_gamma: w64 -> w64
  end

end =
struct

  type w64 = Word64.word
  type w32 = Word32.word

  datatype rand = Rand of {seed: w64, gamma: w64}
  type t = rand


  val golden_gamma: w64 = 0wx9e3779b97f4a7c15

  fun new seed =
    Rand {seed = Word64.fromInt seed, gamma = golden_gamma}


  structure Internal =
  struct

    fun new_from_seed_and_gamma (seed, gamma) =
      Rand {seed = seed, gamma = gamma}

    (*
      private static long mix64(long z) {
        z = (z ^ (z >>> 33)) * 0xff51afd7ed558ccdL;
        z = (z ^ (z >>> 33)) * 0xc4ceb9fe1a85ec53L;
        return z ^ (z >>> 33);
      }
    *)

    fun mix64 (z: w64) =
      let
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
        val z = Word64.* (z, 0wxff51afd7ed558ccd)
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
        val z = Word64.* (z, 0wxc4ceb9fe1a85ec53)
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
      in
        z
      end

    (*
      private static int mix32(long z) {
        z = (z ^ (z >>> 33)) * 0xff51afd7ed558ccdL;
        z = (z ^ (z >>> 33)) * 0xc4ceb9fe1a85ec53L;
        return (int)(z >>> 32); 
      }
    *)

    fun mix32 (z: w64) : w32 =
      let
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
        val z = Word64.* (z, 0wxff51afd7ed558ccd)
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
        val z = Word64.* (z, 0wxc4ceb9fe1a85ec53)
        val z = Word64.>> (z, 0w32)
      in
        Word32.fromLarge z
      end

    (*
      private static long mix64variant13(long z) {
        z = (z ^ (z >>> 30)) * 0xbf58476d1ce4e5b9L;
        z = (z ^ (z >>> 27)) * 0x94d049bb133111ebL;
        return z ^ (z >>> 31); 
      }
    *)

    fun mix64_variant13 (z: w64) =
      let
        val z = Word64.xorb (z, Word64.>> (z, 0w30))
        val z = Word64.* (z, 0wxbf58476d1ce4e5b9)
        val z = Word64.xorb (z, Word64.>> (z, 0w27))
        val z = Word64.* (z, 0wx94d049bb133111eb)
        val z = Word64.xorb (z, Word64.>> (z, 0w31))
      in
        z
      end

    (*
      private static long mixGamma(long z) {
        z = mix64variant13(z) | 1L;
        int n = Long.bitCount(z ^ (z >>> 1));
        if (n >= 24) z ^= 0xaaaaaaaaaaaaaaaaL;
        return z; 
      }
    *)


    fun mix_gamma (z: w64) =
      let
        val z = Word64.orb (mix64_variant13 z, 0w1)
        val n = BitCount64.bit_count (Word64.xorb (z, Word64.>> (z, 0w1)))
      in
        if n >= 24 then Word64.xorb (z, 0wxaaaaaaaaaaaaaaaa) else z
      end


    fun advance (Rand {seed, gamma}) =
      (Rand {seed = seed + gamma, gamma = gamma}, seed)

    fun nth_seed (Rand {seed, gamma}) i =
      seed + Word64.* (i, gamma)

    fun jump (Rand {seed, gamma}) i =
      Rand {seed = seed + Word64.* (i, gamma), gamma = gamma}

  end


  fun split r =
    let
      val (r, seed1) = Internal.advance r
      val (r, seed2) = Internal.advance r
      val newr =
        Rand {seed = Internal.mix64 seed1, gamma = Internal.mix_gamma seed2}
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
          Rand {seed = Internal.mix64 seed1, gamma = Internal.mix_gamma seed2}
        end
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
        (r, Word64.toIntX w)
      end


  fun gen_many_int_in_range r (lo, hi) =
    if lo >= hi then
      raise Fail "SplittableRandom.gen_int_in_range: error: lo >= hi"
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
            Word64.+ (wlo, Word64.mod (w, n))
          end
      in
        (r, gen)
      end


end
