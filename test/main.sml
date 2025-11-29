val r = SplittableRandom.new 15210
val (r, xs) = SplittableRandom.gen_many_int r

val (s, tm) = Util.getTime (fn () => Seq.tabulate xs 10000000)
val _ = print (Time.fmt 4 tm ^ "\n")

val _ = print (Util.summarizeArraySlice 10 Int.toString s ^ "\n")
