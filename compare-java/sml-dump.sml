fun loop (lo, hi) b f =
  if lo >= hi then b else loop (lo + 1, hi) (f (b, lo)) f

fun fix_neg str =
  if String.size str > 0 andalso String.sub (str, 0) = #"~" then
    "-" ^ (String.substring (str, 1, String.size str - 1))
  else
    str

(* ======================================================================== *)

structure R = SplittableRandom

fun dump_at r count =
  let
    (* Should exactly match Java: for(...) { r.nextLong() } *)
    val r = loop (0, count) r (fn (r, _) =>
      let val (r, w) = R.gen_w64 r
      in print (fix_neg (Int.toString (Word64.toIntX w)) ^ "\n"); r
      end)

    (* Should exactly match Java: for(...) { r.nextInt() } *)
    val r = loop (0, count) r (fn (r, _) =>
      let val (r, w) = R.gen_w32 r
      in print (fix_neg (Int.toString (Word32.toIntX w)) ^ "\n"); r
      end)

    (* Should exactly match Java: for(...) { r.nextDouble() } *)
    val r = loop (0, count) r (fn (r, _) =>
      let val (r, w) = R.gen_real r
      in print (fix_neg (Real.fmt (StringCvt.FIX (SOME 11)) w) ^ "\n"); r
      end)
  in
    r
  end


(* ======================================================================== *)

val (count, seed) =
  case CommandLine.arguments () of
    [count, seed] => (valOf (Int.fromString count), valOf (Int.fromString seed))
  | _ =>
      ( print ("Usage: sml-dump <count> <seed>\n")
      ; OS.Process.exit OS.Process.failure
      )

val r = R.new seed
val r = dump_at r count

val (r_l, r_r) = R.split r
val r_l = dump_at r_l count
val r_r = dump_at r_r count

val (r_ll, r_lr) = R.split r_l
val r_ll = dump_at r_ll count
val r_lr = dump_at r_lr count

val (r_rl, r_rr) = R.split r_r
val r_rl = dump_at r_rl count
val r_rr = dump_at r_rr count