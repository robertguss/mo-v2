# Core Concepts

Mo: The AI-first, verification-focused programming language this project designs. A research experiment, not a competitor to existing languages.

AI-first: Designed on the assumption that agents write the code and humans own the decisions. Contrasts with human-first languages, which trade strictness for human ergonomics.

Agent: An AI system that writes, tests, and fixes code. In Mo, agents own implementation.

Human: The person accountable for a program. Humans own intent and decisions, approve waivers, and review specs rather than implementations.

Intent: What a human wants a program to do, in plain language ("a discount is never more than 50% off"). Where intent lives in Mo is still open.

Implementation: The code that does the work. Written by agents; not routinely read by humans.

Verification: Checking that an implementation matches what was declared about it. Always verification against something: types, contracts, tests, or intent.

Feedback loop: The cycle of an agent writing code, getting a check result, and fixing it. Mo aims to make every loop fast and precise.

Structured diagnostic: A machine-readable compiler or runtime message: a stable error code, the exact location, what went wrong, and a suggested fix. Written for agents first.
