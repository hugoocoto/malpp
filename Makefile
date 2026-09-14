MPICXX = mpicxx

FORK_URL = https://github.com/hugoocoto/ppabli-tfm.git
MALLEABLE_DIR = build/fork/code/t2
MALLEABLE_INC = $(MALLEABLE_DIR)/malleable/include
MALLEABLE_LIB = $(MALLEABLE_DIR)/build/libmalleable.a

TESTS = $(basename $(notdir $(wildcard test/*.c)))

.PHONY: test clean

malpp: src/main.c src/lex.c src/parse.c src/lex.h src/parse.h src/shared.h
	gcc src/main.c src/lex.c src/parse.c -o malpp -Wall -Wextra -Werror

src/lex.c src/lex.h &: src/lex.l
	flex -o src/lex.c --header-file=src/lex.h src/lex.l

src/parse.c src/parse.h &: src/parse.y
	bison -d -o src/parse.c src/parse.y

$(MALLEABLE_LIB):
	mkdir -p build
	rm -rf build/fork
	git clone --depth 1 $(FORK_URL) build/fork
	$(MAKE) -C $(MALLEABLE_DIR) build/libmalleable.a

test: malpp $(MALLEABLE_LIB)
	@mkdir -p build
	@status=0; \
	for name in $(TESTS); do \
		$(CXX) -std=c++20 -Wall test/$$name.c -o build/$$name.plain \
			&& ./build/$$name.plain > build/$$name.plain.out 2>&1 \
			&& diff -u test/$$name.expected build/$$name.plain.out \
			&& echo "PASS $$name (plain)" \
			|| { echo "FAIL $$name (plain)"; status=1; }; \
		rm -f build/$$name; \
		if ./malpp test/$$name.c > build/$$name.gen.cpp \
			&& $(MPICXX) -std=c++20 -Wall -I$(MALLEABLE_INC) build/$$name.gen.cpp $(MALLEABLE_LIB) -lpthread -ldl -o build/$$name; then \
			mpirun -n 1 build/$$name > build/$$name.out 2>&1 \
				&& diff -u test/$$name.expected build/$$name.out \
				&& echo "PASS $$name (malleable, 1 proc)" \
				|| { echo "FAIL $$name (malleable, 1 proc)"; status=1; }; \
			mpirun build/$$name > build/$$name.max.out 2>&1 \
				&& sort test/$$name.expected > build/$$name.expected.sorted \
				&& sort build/$$name.max.out > build/$$name.max.sorted \
				&& diff -u build/$$name.expected.sorted build/$$name.max.sorted \
				&& echo "PASS $$name (malleable, max procs)" \
				|| { echo "FAIL $$name (malleable, max procs)"; status=1; }; \
		else \
			echo "FAIL $$name (malleable, build)"; status=1; \
		fi; \
	done; \
	exit $$status

clean:
	rm -rf build malpp src/lex.c src/lex.h src/parse.c src/parse.h
