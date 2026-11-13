CC = cc
CFLAGS = -std=c99 -Wall -Wextra -g

.PHONY: all test clean
all: build/analisador

build:
	mkdir -p build

build/parser.stamp: gramatica_semantico_c-.y arvore.h | build
	bison -d -o build/semantico.tab.c gramatica_semantico_c-.y
	touch $@

build/lex.yy.c: lexico.l | build
	flex -o $@ lexico.l

build/analisador: build/parser.stamp build/lex.yy.c arvore.c semantico.c arvore.h
	$(CC) $(CFLAGS) -D_POSIX_C_SOURCE=200809L -DANALISE_SEMANTICA -I. -Ibuild build/semantico.tab.c build/lex.yy.c arvore.c semantico.c -o $@

test: build/analisador
	python3 tests/test_semantico.py

clean:
	rm -f build/analisador build/semantico.tab.c build/semantico.tab.h build/lex.yy.c build/parser.stamp
