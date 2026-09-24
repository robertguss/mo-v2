# Pools (regions)

**Label:** To explore

Values made for one job go into a pool freed all at once when the job ends. Very fast for job-shaped work; usually combined with another option.

* Languages: Erlang (per-process heaps), Zig arenas, MLKit.

Open: Robert wants to explore this (Erlang and the BEAM), for example each long-running part owning its memory, so a part stopped by a bug (D29) frees everything at once. Belongs with running programs.
