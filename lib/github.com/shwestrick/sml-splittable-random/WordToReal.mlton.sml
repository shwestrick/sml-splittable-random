structure WordToReal:
sig
  val w64_to_r64: Word64.word -> Real64.real
end =
struct

  fun w64_to_r64 (w: Word64.word) =
    MLton.Real64.fromLargeWord w

end