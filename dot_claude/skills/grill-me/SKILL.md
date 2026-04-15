---
name: grill-me
description: |
  Interview the user relentlessly about a plan or design until reaching
  shared understanding, resolving each branch of the decision tree.
  Use when user wants to stress-test a plan, get grilled on their design,
  or mentions "grill me".
model: sonnet
effort: high
---

<!-- Based on https://github.com/mattpocock/skills (MIT License, Copyright (c) 2026 Matt Pocock) -->

Interview me relentlessly about every aspect of this plan until we reach a
shared understanding. Walk down each branch of the design tree, resolving
dependencies between decisions one-by-one. For each question, provide your
recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase
instead.

## Checkpoint evaluation

This skill runs on Sonnet for fast iterative questioning. Before concluding
a major decision branch, or if the dialogue starts going in circles, spawn
an Opus subagent (Task tool with `model: opus`) to audit the conversation
so far and surface blind spots, unstated assumptions, or contradictions the
Sonnet loop may have missed. Feed the subagent a concise summary of the
decisions made and open questions, and integrate its findings into the next
round of questions.
