#include <cstdio>

int
main()
{
        long i = 0, iters = 100, hits = 0;

        // mal: loop i->iters acc=hits
        for (; i < iters; i++) {
                if (i % 2) hits++;
                // mal: check
        }

        // mal: single
        std::printf("hits=%ld\n", hits);

        return 0;
}
