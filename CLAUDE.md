# Working rules for AI agents in Mo v2

Mo v1 went wrong because AI agents made most of the decisions and checked their
own work. These rules exist to stop that happening again.

- **Robert decides; you propose.** Never record a decision Robert did not make.
  If a choice is needed, stop and ask. A question waits for his answer; it is
  never turned into a provisional decision.
- **Ask one question per message.**
- **Robert does not read code** (D5). Anything he is asked to trust must be
  something he can read: a spec, a property stated in plain English, a theorem
  statement, a test's name and example, a run on real data.
- **No self-certification.** The agent that writes code may not write or change
  the checks that accept it. Acceptance criteria are written and approved before
  the work starts. Changing an expected output to match a program's actual
  output is forbidden.
- **Every piece of work has a written stop condition** before it starts.
- **Builders work where Robert can see them** (D14): start each builder as a
  new Claude Code session in a Herdr pane (`herdr agent start --kind claude`),
  never as a hidden subagent.
- **Nothing from v1 comes over without a decision.** `../mo-lang` is reference
  only.
- **No process machinery** (auditors, handoff protocols, extra review layers)
  unless Robert decides to add it.
- Never use `tr` in shell commands on this machine; use python3.
