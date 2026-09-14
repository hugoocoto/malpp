#include <stdio.h>

int
main()
{
        long i = 0;
        long limit = 5;

        // mal: loop i->limit
        for (; i < limit; i++) {
                printf("Hello %ld\n", i);
                // mal: check
        }

        return 0;
}
