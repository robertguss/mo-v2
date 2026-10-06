#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef ABI
#define ABI 2
#endif
uint64_t mo_abi(void) { return ABI; }
uint64_t mo_version(void) { return VERSION; }
#ifndef MISSING_STEP
uint64_t mo_step(uint64_t x, void (*gate)(void *), void *context) {
    /* The callback keeps a real return address in this module while held. */
    if (gate) gate(context);
#if VERSION == 1
    return x + 1;
#else
    return 3 * x + 7;
#endif
}
#endif
__attribute__((destructor)) static void unloaded(void) {
    const char *path = getenv("MO_UNLOAD_LOG");
    if (!path) return;
    FILE *f = fopen(path, "a");
    if (f) { fprintf(f, "%d\n", VERSION); fclose(f); }
}

#include <time.h>
#ifndef PREPARE_MS
#define PREPARE_MS 0
#endif
#ifndef READY
#define READY 42
#endif
uint64_t mo_prepare(void (*entered)(void *), void *context) {
    entered(context);
    struct timespec delay = {PREPARE_MS / 1000, (PREPARE_MS % 1000) * 1000000L};
    while (nanosleep(&delay, &delay) != 0) {}
    return READY;
}
