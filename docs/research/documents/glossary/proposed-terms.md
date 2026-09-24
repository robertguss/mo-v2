# Proposed Terms

Under discussion, not yet decided. Move a term into its section once it's settled.

Isolated unit: A unit of work with its own memory that communicates only by messages, as in Erlang. Would let one unit stop on a defect without corrupting others. Not yet committed.

Share-nothing: A concurrency model where units never share memory; shared data lives in a dedicated owner unit. Shared memory would be a declared, approved waiver. Not yet committed.
