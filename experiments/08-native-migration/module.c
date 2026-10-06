#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdatomic.h>
#include <time.h>
#ifndef ABI
#define ABI 3
#endif
#ifndef MIGRATE_MS
#define MIGRATE_MS 0
#endif
#ifndef CORRUPT
#define CORRUPT 0
#endif
typedef struct { uint64_t value[4]; } Row;
#if VERSION == 1
typedef struct { size_t count; Row rows[8]; } Queue;
#else
typedef struct Node { Row row; struct Node *next; } Node;
typedef struct { size_t count; Node *head, *tail; } Queue;
#endif
static _Atomic uint64_t live_queues;
uint64_t mo_abi(void) { return ABI; }
uint64_t mo_version(void) { return VERSION; }
uint64_t mo_layout(void) { return VERSION == 1 ? 1 : 2; }
#ifndef MISSING_STEP
uint64_t mo_step(uint64_t x, void (*gate)(void *), void *context) {
    if (gate) gate(context);
#if VERSION == 1
    return x + 1;
#else
    return 3 * x + 7;
#endif
}
#endif
uint64_t mo_push(void *opaque, const Row *row) {
    Queue *q = opaque;
    if (q->count == 8) return 0;
#if VERSION == 1
    q->rows[q->count] = *row;
#else
    Node *n = malloc(sizeof(*n));
    if (!n) return 0;
    n->row = *row; n->next = NULL;
    if (q->tail) q->tail->next = n; else q->head = n;
    q->tail = n;
#endif
    q->count++;
    return 1;
}
uint64_t mo_pop(void *opaque, Row *out) {
    Queue *q = opaque;
    if (!q->count) return 0;
#if VERSION == 1
    *out = q->rows[0];
    memmove(q->rows, q->rows+1, (q->count-1)*sizeof(Row));
#else
    Node *n = q->head; *out = n->row;
    q->head = n->next;
    if (!q->head) q->tail = NULL;
    free(n);
#endif
    q->count--;
    return 1;
}
uint64_t mo_export(void *opaque, Row *out) {
    Queue *q = opaque;
#if VERSION == 1
    memcpy(out, q->rows, q->count*sizeof(Row));
#else
    size_t i = 0;
    for (Node *n=q->head; n; n=n->next) out[i++] = n->row;
#endif
    return q->count;
}
void mo_free(void *opaque) {
    Row row;
    while (mo_pop(opaque, &row)) {}
    free(opaque);
    atomic_fetch_sub(&live_queues, 1);
}
void *mo_migrate(const Row *rows, uint64_t count, void (*gate)(void *), void *context) {
    if (count > 8) return NULL;
    if (gate) gate(context);
    struct timespec delay = {MIGRATE_MS/1000, (MIGRATE_MS%1000)*1000000L};
    while (nanosleep(&delay, &delay) != 0) {}
    Queue *q = calloc(1, sizeof(*q));
    if (!q) return NULL;
    atomic_fetch_add(&live_queues, 1);
    for (uint64_t i=0; i<count; i++) {
        Row r = rows[i];
        if (CORRUPT && i==0) r.value[2]++;
        if (!mo_push(q,&r)) { mo_free(q); return NULL; }
    }
    if (CORRUPT && count==0) {
        Row r = {{999,999,999,999}};
        if (!mo_push(q,&r)) { mo_free(q); return NULL; }
    }
    return q;
}
__attribute__((destructor)) static void unloaded(void) {
    const char *path = getenv("MO_UNLOAD_LOG");
    if (!path) return;
    FILE *f = fopen(path, "a");
    if (f) { fprintf(f, "%d:%llu\n", VERSION, (unsigned long long)atomic_load(&live_queues)); fclose(f); }
}
