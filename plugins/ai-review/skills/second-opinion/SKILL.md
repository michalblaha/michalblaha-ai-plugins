---
name: second-opinion
description: "Získej druhý názor od modelů OpenAI (Codex), Google (Antigravity / agy) nebo Anthropic (Claude Code). Použij při validaci architektonických rozhodnutí, kontrole bezpečnosti kódu, porovnávání implementačních přístupů nebo když multi-model konsenzus přidá hodnotu. Podporuje všechny tři hlavní AI CLI nástroje pro maximální flexibilitu."

allowed-tools:
  - AskUserQuestion
  - Read
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Bash(command -v *)
  - Bash(codex --version:*)
  - Bash(codex -a never exec:*)
  - Bash(claude --version:*)
  - Bash(claude -p:*)
  - Bash(date:*)
  - Bash(agy -p:*)
  - Bash(agy --print:*)
  - Bash(agy --prompt:*)
  - Bash(agy models:*)
  - Bash(mktemp:*)
  - Bash(mkdir:*)
  - Bash(cat:*)
  - Bash(echo:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git add:*)
  - Bash(git commit:*)

argument-hint: "question / file / decision to review"

---

# Second Opinion via Codex, Antigravity & Claude Code CLI

Get an external AI perspective from OpenAI (via Codex CLI), Google (via Antigravity CLI — `agy`), or Anthropic (via Claude Code CLI) to validate decisions or compare approaches.

**Shared reference files** (paths relative to this skill's directory):

- `../references/cli-reference.md` — availability checks, authentication, mandatory flags, failure handling, full call patterns, CLI option tables, and model recommendations for all three providers. **Read it before making the first provider call.**
- `../references/trusted-sources.md` — when AI cross-check isn't enough: independent sources and the trusted-media list.

---

## 1. Identify yourself

Before starting, determine which model is running this skill (system prompt, CLI name, auth context). Choose verifiers from the **remaining** providers:

- If you are **Claude** → use **Codex** and/or **agy** (with a Gemini model).
- If you are **GPT/Codex** → use **Claude** and/or **agy** (with a Gemini model).
- If you are **Gemini** → use **Codex** and/or **Claude**.

Never verify with the same model family that produced the answer — it shares the same weaknesses. Note: `agy` also hosts Claude and GPT-OSS models; for cross-checking always call it with a `Gemini …` model (otherwise you lose provider independence).

---

## 2. Environment prerequisites

Skill assumes a shell environment with the relevant CLI tools installed. **In a shell-less environment** (plain chat without bash tool), offer the user to send the verification prompt to another model manually, or use web search for fact grounding.

Details live in `../references/cli-reference.md`. The non-negotiables:

- Verify CLI availability before use (see reference §1 for the check snippet and authentication).
- Run `codex`, `agy`, and `claude` **directly on the system, NOT in a sandbox** — they need login credentials unavailable there.
- Every Codex call is `codex -a never exec --skip-git-repo-check ...`; on failure fall back to `codex:codex-rescue` (one retry), then switch provider.
- Check exit codes on every provider call — an **empty output file means the call failed**, not that the model returned an empty answer. After one retry, switch provider and record the failure under *Uncertainties*.
- Use `WORK=$(mktemp -d)` for intermediate outputs.

---

## 3. Quick Patterns

Minimal one-shot examples. Full patterns (structured/schema output, images, workspace grounding, cheaper tiers) are in `../references/cli-reference.md` §3.

```bash
WORK=$(mktemp -d)

# Codex (OpenAI)
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/codex.txt" \
  "Your question here"
cat "$WORK/codex.txt"

# Antigravity / agy (Google) — always a Gemini model
agy -p "Your question here" --model "Gemini 3.1 Pro (High)" > "$WORK/agy.txt"
cat "$WORK/agy.txt"

# Claude Code (Anthropic)
claude -p "Your question here" --model opus --output-format text > "$WORK/claude.txt"
cat "$WORK/claude.txt"
```

For schema-validated structured output use Codex `--output-schema` or Claude `--json-schema` (see reference §3); `agy` has no schema support — enforce JSON shape in the prompt.

**Note:** The spawned instance runs independently without access to the current session context, providing a genuinely fresh perspective.

---

## 4. Use Cases

Reusable prompt templates — combine with any provider pattern above.

**Architecture review:**

```text
Review this architecture decision: [description].
Assess: scalability, maintainability, security risks, alternatives.
```

**Security audit:**

```text
Security review of [file/code]:
- Input validation
- Authentication/authorization
- Data exposure risks
Provide specific vulnerabilities and fixes.
```

**Code review:**

```text
Review [file] for: bugs, performance issues, maintainability.
Provide line-level recommendations.
```

---

## 5. When AI cross-check isn't enough

AI models share training data — and with it, shared hallucinations. When verifying a **fact** (existence of a person/account, date, value, quote, legal/historical claim), the strongest check is not another model but an **independent source**. See `../references/trusted-sources.md` for the source strategy and the trusted-media list.

Use AI cross-check for **reasoning, structure, logical gaps, code review, design decisions**. For facts, use it only as a first filter and then verify against a source.

---

## 6. Evaluating findings

Treat the external model's output as **hypotheses, not truth**. The second model may have the same blind spot as you — "verified by cross-check" is not the same as "verified against reality".

### Evaluation process

1. Read the external model's findings point by point.
2. For each concrete finding, verify it independently against available files, tests, documentation, or a primary source.
3. **Accept** findings that are concrete, relevant, and confirmed by your own verification.
4. **Reject** findings that are speculative, invalid, or out of scope. Never apply a recommendation just because another model stated it — apply it only after your own verification.

### Structure of final answer

Clearly separate:

- **Second opinion** — which provider/model was used and a brief summary of what it said.
- **Accepted findings** — what you confirmed as valid after your own verification. For each: location + evidence or reasoning.
- **Rejected findings** — what you did not confirm and why.
- **Changes or recommendations** — what was done or what should follow.
- **Uncertainties** — what requires a primary source, a test, or a decision from the user.

---

## 7. Saving the conversation log

After completing the cross-check, save the **full exchange** to a log file in the **project root** (not `.claude/`). The log must capture all three parts: the **prompt** you sent, the external model's **response**, and your own **evaluation** (accepted/rejected findings, recommendations, uncertainties).

Write the prompt and your evaluation to files first (so the log contains them verbatim), then assemble the log:

```bash
# Store the exact prompt you sent and your evaluation as files
cat > "$WORK/prompt.txt" << 'EOF'
[the exact prompt/question sent to the external model]
EOF

cat > "$WORK/evaluation.txt" << 'EOF'
[your evaluation: accepted findings, rejected findings, recommendations, uncertainties]
EOF

# Log into the project root
TIMESTAMP=$(date '+%Y-%m-%d_%H.%M.%S')
LOG="./.second-opinion-talk_${TIMESTAMP}.log"

{
  echo "=== Second Opinion Log: $TIMESTAMP ==="
  echo "Provider: [provider/model]"
  echo ""
  echo "--- Prompt ---"
  cat "$WORK/prompt.txt"
  echo ""
  echo "--- Response ---"
  cat "$WORK/answer.txt"
  echo ""
  echo "--- Evaluation ---"
  cat "$WORK/evaluation.txt"
} > "$LOG"

echo "Log saved to: $LOG"

# The logs are meant to be versioned — commit the log if the project is a git repo
[ -d .git ] && git add "$LOG" && git commit -m "second-opinion: log ${TIMESTAMP}"
```

---

## 8. Multi-Provider Consensus Example

Get second opinions from all three providers and compare:

```bash
WORK=$(mktemp -d)

# 1. Ask Codex
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/codex_opinion.txt" \
  "Should we use Redis or PostgreSQL for session storage in e-commerce app?"

# 2. Ask Antigravity (agy)
agy -p "Should we use Redis or PostgreSQL for session storage in e-commerce app?" \
  --model "Gemini 3.1 Pro (High)" > "$WORK/agy_opinion.txt"

# 3. Ask Claude Code
claude -p "Should we use Redis or PostgreSQL for session storage in e-commerce app?" \
  --model opus --output-format text > "$WORK/claude_opinion.txt"

# 4. Compare outputs
echo "=== Codex (OpenAI) ===" && cat "$WORK/codex_opinion.txt"
echo ""
echo "=== Antigravity / agy (Google) ===" && cat "$WORK/agy_opinion.txt"
echo ""
echo "=== Claude Code (Anthropic) ===" && cat "$WORK/claude_opinion.txt"

# 5. Save log (prompt + all responses + your evaluation) into the project root
cat > "$WORK/prompt.txt" << 'EOF'
Should we use Redis or PostgreSQL for session storage in e-commerce app?
EOF
cat > "$WORK/evaluation.txt" << 'EOF'
[your evaluation: accepted findings, rejected findings, recommendations, uncertainties]
EOF

TIMESTAMP=$(date '+%Y-%m-%d_%H.%M.%S')
LOG="./.second-opinion-talk_${TIMESTAMP}.log"
{
  echo "=== Second Opinion Log: $TIMESTAMP ==="
  echo "--- Prompt ---"; cat "$WORK/prompt.txt"
  echo "--- Codex ---"; cat "$WORK/codex_opinion.txt"
  echo "--- agy ---"; cat "$WORK/agy_opinion.txt"
  echo "--- Claude ---"; cat "$WORK/claude_opinion.txt"
  echo "--- Evaluation ---"; cat "$WORK/evaluation.txt"
} > "$LOG"
[ -d .git ] && git add "$LOG" && git commit -m "second-opinion: log ${TIMESTAMP}"
```

Analyze agreement/disagreement across all three providers and synthesize a final recommendation.
