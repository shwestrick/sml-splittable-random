(* Standard ML unfortunately does not expose a bit count operation.
 * We can hack around it with some minor overhead.
 *)
structure BitCount64:
sig
  val bit_count: Word64.word -> int
  val bit_count_loop: Word64.word -> int
end =
struct

  (* Useful to check correctness of bit_count, below. *)
  fun bit_count_loop w =
    let
      fun loop count w =
        if w = 0w0 then count
        else loop (count + Word64.andb (w, 0w1)) (Word64.>> (w, 0w1))
    in
      Word64.toIntX (loop 0w0 w)
    end

  (* Inspired by
   *   https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetNaive
   * reworked with a little AI help...
   *)
  fun bit_count (w: Word64.word) : int =
    let
      val u = Word64.>> (w, 0w1)
      val u = Word64.andb (u, 0wx5555555555555555)
      val u = Word64.- (w, u)

      val t = Word64.andb (u, 0wx3333333333333333)
      val u = Word64.>> (u, 0w2)
      val u = Word64.andb (u, 0wx3333333333333333)
      val u = Word64.+ (t, u)

      val u = Word64.+ (u, Word64.>> (u, 0w4))
      val u = Word64.andb (u, 0wx0f0f0f0f0f0f0f0f)

      val u = Word64.* (u, 0wx0101010101010101)
      val u = Word64.>> (u, 0w56)
    in
      Word64.toIntX u
    end

end