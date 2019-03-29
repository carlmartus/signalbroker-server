SRC=$(wildcard c_lib/*.c c_lib/csunixds.h.in)

all: priv priv/testunit

priv/testunit: priv $(SRC)
	@cmake -Hc_lib -Bpriv
	@make -s -C priv

priv:
	mkdir $@

clean:
	@rm -r priv


