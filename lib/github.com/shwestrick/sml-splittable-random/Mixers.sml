structure Mixers:
sig

  type w64 = Word64.word
  type w32 = Word32.word

  (* ========================================================================
   * Transcribed+ported from Fig 16 of SplitMix paper:
   *   Fast Splittable Pseudorandom Number Generators
   *   Steele Jr, Lea, Flood (OOPSLA'14)
   *   https://gee.cs.oswego.edu/dl/papers/oopsla14.pdf
   *)
  structure Oopsla14:
  sig
    val mix64: w64 -> w64
    val mix64_variant13: w64 -> w64
    val mix32: w64 -> w32
    val mix_gamma: w64 -> w64
  end

  (* ======================================================================
   * Transcribed+ported from Java source:
   *   https://github.com/openjdk/jdk/blob/92e1357dfd2d874ef1a62ddd69c86a7bb189c6a2/src/java.base/share/classes/java/util/SplittableRandom.java
   *)
  structure FromJavaSrc:
  sig
    val mix64: w64 -> w64
    val mix32: w64 -> w32
    val mix_gamma: w64 -> w64
  end

end =
struct

  type w64 = Word64.word
  type w32 = Word32.word

  (* ========================================================================
   * Transcribed+ported from Fig 16 of SplitMix paper:
   *   Fast Splittable Pseudorandom Number Generators
   *   Steele Jr, Lea, Flood (OOPSLA'14)
   *   https://gee.cs.oswego.edu/dl/papers/oopsla14.pdf
   *)
  structure Oopsla14 =
  struct

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

  end


  (* ======================================================================
   * Transcribed+ported from Java source:
   *   https://github.com/openjdk/jdk/blob/92e1357dfd2d874ef1a62ddd69c86a7bb189c6a2/src/java.base/share/classes/java/util/SplittableRandom.java
   *)
  structure FromJavaSrc =
  struct

    (*
      private static long mix64(long z) {
        z = (z ^ (z >>> 30)) * 0xbf58476d1ce4e5b9L;
        z = (z ^ (z >>> 27)) * 0x94d049bb133111ebL;
        return z ^ (z >>> 31);
      }
    *)

    fun mix64 (z: w64) =
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
      private static int mix32(long z) {
        z = (z ^ (z >>> 33)) * 0x62a9d9ed799705f5L;
        return (int)(((z ^ (z >>> 28)) * 0xcb24d0a5c88c35b3L) >>> 32);
      }
    *)
  
    fun mix32 (z: w64) : w32 =
      let
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
        val z = Word64.* (z, 0wx62a9d9ed799705f5)
        val z = Word64.xorb (z, Word64.>> (z, 0w28))
        val z = Word64.* (z, 0wxcb24d0a5c88c35b3)
        val z = Word64.>> (z, 0w32)
      in
        Word32.fromLarge z
      end


    (*
      private static long mixGamma(long z) {
        z = (z ^ (z >>> 33)) * 0xff51afd7ed558ccdL; // MurmurHash3 mix constants
        z = (z ^ (z >>> 33)) * 0xc4ceb9fe1a85ec53L;
        z = (z ^ (z >>> 33)) | 1L;                  // force to be odd
        int n = Long.bitCount(z ^ (z >>> 1));       // ensure enough transitions
        return (n < 24) ? z ^ 0xaaaaaaaaaaaaaaaaL : z;
      }
    *)

    fun mix_gamma (z: w64) =
      let
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
        val z = Word64.* (z, 0wxff51afd7ed558ccd)
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
        val z = Word64.* (z, 0wxc4ceb9fe1a85ec53)
        val z = Word64.xorb (z, Word64.>> (z, 0w33))
        val z = Word64.orb (z, 0w1)
        val n = BitCount64.bit_count (Word64.xorb (z, Word64.>> (z, 0w1)))
      in
        if n < 24 then Word64.xorb (z, 0wxaaaaaaaaaaaaaaaa) else z
      end

  end

end