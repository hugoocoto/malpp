# malpp: preproc abstraction layer for libmalleable

The aim of this tool is to give programmers the ability to enable malleability
just by adding a comment above their loops.

# Usage

## Build

malpp is a flex + bison program. Building it needs flex, bison and a C
compiler:

```sh
make        # builds ./malpp
make test   # also needs MPI; clones and builds libmalleable under build/
```

## Command usage

malpp reads the file given as argument (or stdin) and writes the expanded
source to stdout, so it can be embedded into any build pipeline:

```c
malpp program.c > program_malleable.c
```

The parsing can be done automatically from the Makefile with a rule like the one
below:

```make
program_malleable.c: program.c 
    malpp $^ > $@
```

## Example

With malpp, a malleable sum of squares only needs the directives:

```c
long i = 0, iters = 10, sum = 0;

// mal: loop i->iters acc=sum
for (; i < iters; i++) {
    sum += i * i;
    // mal: check
}

// mal: single
printf("sum=%ld\n", sum);
```

Without malpp, same problem:

```c
mal_init();

const long total = 10;
long i, limit, sum = 0;
MalFor f = mal_for(total, i, limit);
mal_attach_acc(f, sum);

for (; i < limit; i++) {
    sum += i * i;
    mal_check_for(f);
}

mal_finalize();

if (mal_rank() == 0)
    printf("sum=%ld\n", sum);
```

## Directives

### mal: loop

A single linear loop can be declared using one of the `mal: loop` variants. This
directive has to be followed by a loop, in the form below:

```c
int i=0, iters=100;

// mal: loop i->iters
for (; i < iters; i++){
    // mal: check
}
```

The variables have to be declared outside the loop, and the iterator has to be
zero-initialized. `// mal: check` must appear somewhere inside the loop body.

An accumulator can be declared to those problems that required count events.

```c
int i=0, iters=100, hits=0;

// mal: loop i->iters acc=hits
for (; i < iters; i++){
    if (i % 2) hits++;
    // mal: check
}
```

The accumulator variable must be one of the types libmalleable knows how to
reduce (`int`, `long`, `long long`, `unsigned`, `unsigned long`, `float`,
`double`). After the loop, the reduced value is only meaningful on rank 0 (see
`mal: single` below).

### mal: single

`// mal: single` guards the statement right below it so only rank 0 runs it:

```c
// mal: single
printf("done\n");
```

### mal: decide

`// mal: decide=<func>` sets `<func>` as the custom resize decision function:

```c
// mal: decide=my_decide
```

A decision function written inside the program is the one thing that cannot
compile in the sequential build. Guard it with `MALPP` to keep it working:

```c
#ifdef MALPP
static ResizeDecision
keep_size(const EpochMetrics &m)
{
        (void) m;
        return ResizeDecision {};
}
#endif

// mal: decide=keep_size
```

`// mal: decide=<path>:<func>` sets the custom resize from a dynamically linked
library; loads `<func>` at runtime from the compiled file at `<path>`:

```c
// mal: decide=./decide.so:decide
```

This second form needs no guard: the decision function lives in its own file,
which is compiled against libmalleable separately.

# Optimization

Generated code uses a malpp_i-style dispatch loop purely as a structural template; it produces correct output even unoptimized, but at -O0 you pay for a real loop and branches that only exist to be folded away.

Build with -O1 or higher (or mark the function/file for GCC's optimize("O2")) to let the compiler eliminate this scaffolding.

# Collaboration

I'm open to any kind of collaboration. I only ask collaborators to review the
code 'by hand' and test it properly before creating a pull request.

