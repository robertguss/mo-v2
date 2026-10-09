"""Hash/count a decoded byte stream without parsing or retaining large records.

Usage: gzip -dc ORIGINAL.gz | python3 inspect_stream.py > NEW_REPORT.json
The caller must retain gzip stderr and both pipeline exit codes separately.
This is postmortem inspection, not semantic verification or candidate execution.
"""
import hashlib
import json
import sys

digest = hashlib.sha256()
size = records = trailing = 0
while chunk := sys.stdin.buffer.read(256 * 1024):
    digest.update(chunk)
    size += len(chunk)
    records += chunk.count(b'\n')
    end = chunk.rfind(b'\n')
    trailing = trailing + len(chunk) if end < 0 else len(chunk) - end - 1
print(json.dumps(dict(decoded_bytes=size, complete_retained_records=records,
                      decoded_bytes_sha256=digest.hexdigest(),
                      trailing_partial_record_bytes=trailing,
                      inspection_only=True, candidate_executed=False), indent=2))
