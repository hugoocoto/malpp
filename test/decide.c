#include <cstdio>

/* Code that only makes sense in the malleable build has to be guarded: malpp
 * defines MALPP in the file it generates, so the plain build skips it and the
 * source stays compilable without libmalleable. */
#ifdef MALPP

static ResizeDecision
keep_size(const EpochMetrics &m)
{
        (void) m;
        return ResizeDecision {};
}

#endif

int
main()
{
        long i = 0, iters = 100, hits = 0;

        // mal: decide=keep_size
        // mal: loop i->iters acc=hits
        for (; i < iters; i++) {
                if (i % 2) hits++;
                // mal: check
        }

        // mal: single
        std::printf("hits=%ld\n", hits);

        return 0;
}
