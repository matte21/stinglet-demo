#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <sys/mman.h>

int main(int argc, char **argv) {
    if (argc != 3 || strcmp(argv[1], "-m")) {
        printf("Usage: %s -m <num GiBs to use (must be > 0)>\n", argv[0]);
        return 1;
    }
    int num_gibs = atoi(argv[2]);
    if (num_gibs <= 0) {
        printf("Usage: %s -m <num GiBs to use (must be > 0)>\n", argv[0]);
        printf("Error: last argument %s is either <= 0 or not a number\n", argv[2]);
        return 1;
    }

    printf("PID: %ld\n", (long int) getpid());
    sleep(20);

    size_t bytes_to_alloc = (size_t) num_gibs * ((size_t) 1 << 30);
    unsigned long longs_to_alloc =
        (bytes_to_alloc + sizeof(unsigned long) - 1) / sizeof(unsigned long);
    bytes_to_alloc = longs_to_alloc * sizeof(unsigned long);

    unsigned long *buffer = malloc(bytes_to_alloc);
    if (!buffer) {
        printf("malloc failed to allocate %zu bytes for buffer, with errno %d\n",
            bytes_to_alloc, errno);
        return 1;
    }

    for (size_t i = 0; i < longs_to_alloc; i++) {
        buffer[i] = 0;
    }

    if (mlock(buffer, bytes_to_alloc)) {
        printf("mlock failed to lock %zu bytes in buffer, with errno %d\n",
            bytes_to_alloc, errno);
        return 1;
    }

    printf("Allocated, zeroed, and locked %zu bytes. Holding indefinitely.\n",
        bytes_to_alloc);
    for (;;) {
        sleep(60);
    }

    return 0;
}
