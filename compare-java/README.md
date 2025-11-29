# sml-splittable-random compare-java

Run `make` to compare `sml-splittable-random` output against
Java's `java.util.SplittableRandom`. This generates two files: `sml-out`
and `java-out`, and diffs them.

Currently the test measures 32-bit ints, 64-bit ints, doubles (real64),
and a few splits.

```bash
$ make
mlton -default-type int64 -default-type word64 sml-dump.mlb
./sml-dump 10000 15210 > sml-out
javac JavaDump.java
java JavaDump 10000 15210 > java-out

SUCCESS: results exactly match
```