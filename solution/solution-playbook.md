# Solution Playbook

Use this playbook to help the learner without spoiling too early.

## Hint Types

Conceptual hint:

- Explain the idea without code.

Tactical hint:

- Name the next query, function, command, or file to inspect.

Partial solution:

- Show a small pattern with placeholders.

Full solution:

- Provide a complete implementation only when the learner asks or after
  repeated attempts.

## Common Project Help

### Setup Problems

Ask:

- What command did you run?
- What error did you get?
- Which file should define the dependency or configuration?

Guide toward reproducible setup with `uv` unless the learner chose otherwise.

### SQL Problems

Ask:

- What is the grain of each table?
- Which join can multiply rows?
- What should one output row represent?
- How can you test row counts and totals?

### Python Pipeline Problems

Ask:

- What are the inputs and outputs?
- What should happen on missing columns?
- Is the function deterministic?
- Can you test it with a small fixture?

### Modeling Problems

Ask:

- What is the fact table?
- What are the dimensions?
- Which metrics are additive?
- What business question does the model answer?

### Interview Explanation Problems

Ask the learner to explain:

- The problem in one sentence.
- The data flow from source to output.
- The hardest bug or tradeoff.
- The validation strategy.
- The next improvement.

