result.diff: sml-out java-out
	@(diff sml-out java-out && echo "\nSUCCESS: results exactly match") || echo "\nERROR: output differs! see files: sml-out java-out"

sml-out: sml-dump
	./sml-dump 10000 15210 > sml-out

java-out: JavaDump.class
	java JavaDump 10000 15210 > java-out

sml-dump: *.mlb *.sml ../lib/github.com/shwestrick/sml-splittable-random/*
	mlton -default-type int64 -default-type word64 sml-dump.mlb

JavaDump.class: *.java
	javac JavaDump.java

clean:
	rm -f sml-out java-out sml-dump JavaDump.class