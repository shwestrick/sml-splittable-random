MPL=mpl

main: lib *.mlb *.sml ../lib/github.com/shwestrick/sml-splittable-random/*
	$(MPL) -default-type int64 -default-type word64 main.mlb

lib:
	smlpkg sync