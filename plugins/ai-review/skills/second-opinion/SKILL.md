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

argument-hint: "question / file / decision to review"

---

# Second Opinion via Codex, Antigravity & Claude Code CLI

Get an external AI perspective from OpenAI (via Codex CLI), Google (via Antigravity CLI — `agy`), or Anthropic (via Claude Code CLI) to validate decisions or compare approaches.

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

Verify availability before use:

```bash
codex --version || echo "Codex CLI not installed"
command -v agy >/dev/null && agy models >/dev/null 2>&1 \
  && echo "Antigravity (agy) OK" \
  || echo "Antigravity CLI (agy) not installed or not configured"
claude --version || echo "Claude Code CLI not installed"
```

**Authentication:**
- **Codex:** `codex login` or `OPENAI_API_KEY` env var
- **Antigravity (agy):** `agy install` (PATH + shell aliases) then follow login instructions
- **Claude Code:** `claude auth login` or `ANTHROPIC_API_KEY` env var

**Workdir:** All examples below use `WORK=$(mktemp -d)` and then `$WORK/...` for intermediate outputs. This avoids collisions during parallel runs.

**Codex — mandatory `--skip-git-repo-check` flag:** Every `codex exec` call **must** include `--skip-git-repo-check`. Codex refuses to run outside a git repo by default; this skill never writes via Codex so the check is unnecessary and would fail when CWD is outside a repo.

**Fallback when `codex exec` fails:** If a Codex call fails despite the flags (timeout, auth issue, runtime error), delegate to the `codex:codex-rescue` skill / subagent. Use only one retry; if that also fails, switch to a different provider and note the failure in the *Uncertainties* section of your final answer.

**IMPORTANT: Run `codex`, `agy`, and `claude` directly on the system, NOT in a sandboxed environment — they need login credentials that are unavailable in a sandbox.**

---

## 3. Quick Patterns

### Using Codex (OpenAI)

#### Simple Question
```bash
WORK=$(mktemp -d)
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/answer.txt" \
  "Your question here"
cat "$WORK/answer.txt"
```

#### Structured Analysis (Recommended)

**IMPORTANT:** When using `--output-schema`, ALL objects (including nested ones) must have:
- `"additionalProperties": false`
- `"required": [...]` with all property names

```bash
WORK=$(mktemp -d)
cat > "$WORK/schema.json" << 'EOF'
{
  "type": "object",
  "properties": {
    "assessment": { "type": "string" },
    "strengths": { "type": "array", "items": { "type": "string" } },
    "concerns": { "type": "array", "items": { "type": "string" } },
    "recommendation": { "type": "string" }
  },
  "required": ["assessment", "strengths", "concerns", "recommendation"],
  "additionalProperties": false
}
EOF

codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-schema "$WORK/schema.json" \
  --output-last-message "$WORK/result.json" \
  "Analyze [topic]. Provide structured assessment."

cat "$WORK/result.json"
```

#### Nested Objects Example
```bash
WORK=$(mktemp -d)
cat > "$WORK/nested_schema.json" << 'EOF'
{
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "details": {
      "type": "object",
      "properties": {
        "score": { "type": "string" },
        "items": { "type": "array", "items": { "type": "string" } }
      },
      "required": ["score", "items"],
      "additionalProperties": false
    }
  },
  "required": ["summary", "details"],
  "additionalProperties": false
}
EOF
```

### Using Antigravity / agy (Google)

Antigravity CLI (`agy`) is Google's agentic CLI with access to Gemini, Claude, and GPT-OSS models. For "second opinion from Google" always call with a `Gemini 3.1 Pro` / `Gemini 3.5 Flash` model.

#### Simple Question
```bash
WORK=$(mktemp -d)
agy -p "Your question here" --model "Gemini 3.1 Pro (High)" > "$WORK/answer.txt"
cat "$WORK/answer.txt"
```

#### JSON Output
```bash
WORK=$(mktemp -d)
agy -p "Analyze [topic]. Respond in JSON with: assessment (string), strengths (array), concerns (array), recommendation (string). Return ONLY the JSON object, no surrounding prose." \
  --model "Gemini 3.1 Pro (High)" > "$WORK/result.json"
cat "$WORK/result.json"
```

**Note:** `agy` has no `--output-format` flag — output is always raw text on stdout. Enforce JSON shape in the prompt. For strict schema-validated output, use Codex with `--output-schema`.

### Using Claude Code (Anthropic)

#### Simple Question
```bash
WORK=$(mktemp -d)
claude -p "Your question here" --model opus --output-format text > "$WORK/answer.txt"
cat "$WORK/answer.txt"
```

#### JSON Output
```bash
WORK=$(mktemp -d)
claude -p "Analyze [topic]. Respond in JSON with: assessment (string), strengths (array), concerns (array), recommendation (string)" \
  --model opus --output-format json > "$WORK/result.json"
cat "$WORK/result.json"
```

#### With Cheaper Model (Simple Tasks)
```bash
WORK=$(mktemp -d)
claude -p "Your question here" --model haiku --output-format text > "$WORK/answer.txt"
cat "$WORK/answer.txt"
```

**Note:** Claude Code CLI uses `--print` (`-p`) for non-interactive mode. The spawned instance runs independently without access to the current session context, providing a genuinely fresh perspective.

---

## 4. Use Cases

### Architecture Review

**Codex:**
```bash
WORK=$(mktemp -d)
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/arch.txt" \
  "Review this architecture decision: [description].
   Assess: scalability, maintainability, security risks, alternatives."
cat "$WORK/arch.txt"
```

**Antigravity (agy):**
```bash
WORK=$(mktemp -d)
agy -p "Review this architecture decision: [description].
  Assess: scalability, maintainability, security risks, alternatives." \
  --model "Gemini 3.1 Pro (High)" > "$WORK/arch.txt"
cat "$WORK/arch.txt"
```

**Claude Code:**
```bash
WORK=$(mktemp -d)
claude -p "Review this architecture decision: [description].
  Assess: scalability, maintainability, security risks, alternatives." \
  --model opus --output-format text > "$WORK/arch.txt"
cat "$WORK/arch.txt"
```

### Security Audit

**Codex:**
```bash
WORK=$(mktemp -d)
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/security.txt" \
  "Security review of [file/code]:
   - Input validation
   - Authentication/authorization
   - Data exposure risks
   Provide specific vulnerabilities and fixes."
cat "$WORK/security.txt"
```

**Antigravity (agy):**
```bash
WORK=$(mktemp -d)
agy -p "Security review of [file/code]:
  - Input validation
  - Authentication/authorization
  - Data exposure risks
  Provide specific vulnerabilities and fixes." \
  --model "Gemini 3.1 Pro (High)" > "$WORK/security.txt"
cat "$WORK/security.txt"
```

**Claude Code:**
```bash
WORK=$(mktemp -d)
claude -p "Security review of [file/code]:
  - Input validation
  - Authentication/authorization
  - Data exposure risks
  Provide specific vulnerabilities and fixes." \
  --model opus --output-format text > "$WORK/security.txt"
cat "$WORK/security.txt"
```

### Code Review

**Codex:**
```bash
WORK=$(mktemp -d)
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/review.txt" \
  "Review [file] for: bugs, performance issues, maintainability.
   Provide line-level recommendations."
cat "$WORK/review.txt"
```

**Antigravity (agy):**
```bash
WORK=$(mktemp -d)
agy -p "Review [file] for: bugs, performance issues, maintainability.
  Provide line-level recommendations." \
  --model "Gemini 3.1 Pro (High)" > "$WORK/review.txt"
cat "$WORK/review.txt"
```

**Claude Code:**
```bash
WORK=$(mktemp -d)
claude -p "Review [file] for: bugs, performance issues, maintainability.
  Provide line-level recommendations." \
  --model opus --output-format text > "$WORK/review.txt"
cat "$WORK/review.txt"
```

---

## 5. When AI cross-check isn't enough

AI models share training data — and with it, shared hallucinations. When verifying a **fact** (existence of a person/account, date, value, quote, legal/historical claim), the strongest check is not another model but an **independent source**:

- For public institutions and persons: official registries, Wikidata, parliamentary/judicial databases, Hlídač státu MCP server, trusted media.
- For recent facts: web search focused on primary sources, trusted media.
- For code and libraries: official documentation, repo, changelog.
- Trusted media:
  - Czech: ceskenoviny.cz, iDnes.cz, DenikN.cz, SeznamZpravy.cz, Denik.cz, iHned.cz, cc.cz, cnn.iprima.cz, ct24.ceskatelevize.cz, irozhlas.cz, lupa.cz, novinky.cz
  - International: reuters.com, apnews.com, bbc.com, theguardian.com, nytimes.com, washingtonpost.com, wsj.com, ft.com, economist.com, npr.org, pbs.org, propublica.org, bloomberg.com, theatlantic.com, icij.org, occrp.org

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

After completing the cross-check, save the **full exchange** to a log file in the local `.claude/` directory. The log must capture all three parts: the **prompt** you sent, the external model's **response**, and your own **evaluation** (accepted/rejected findings, recommendations, uncertainties).

Write the prompt and your evaluation to files first (so the log contains them verbatim), then assemble the log:

```bash
# Store the exact prompt you sent and your evaluation as files
cat > "$WORK/prompt.txt" << 'EOF'
[the exact prompt/question sent to the external model]
EOF

cat > "$WORK/evaluation.txt" << 'EOF'
[your evaluation: accepted findings, rejected findings, recommendations, uncertainties]
EOF

# Log into the local .claude/ directory
mkdir -p .claude
TIMESTAMP=$(date '+%Y-%m-%d_%H.%M.%S')
LOG=".claude/_second-opinion-talk_${TIMESTAMP}.log"

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
```

---

## 8. Key Options

### Codex CLI Options

| Option | Purpose |
|--------|---------|
| `-m gpt-5.5` | Best model (recommended) |
| `-m gpt-5.5-codex` | Codex-optimized version for agentic coding |
| `-m gpt-5.4-mini` | Faster, cheaper for simple tasks |
| `-c 'model_reasoning_effort="high"'` | Reasoning level. Values: `low`, `medium`, `high`, `xhigh` |
| `--output-schema file.json` | Structured JSON with schema validation |
| `--output-last-message file.txt` | Save response to file |
| `-i image.png` | Include image for analysis |

### Antigravity (agy) CLI Options

| Option | Purpose |
|--------|---------|
| `--model "Gemini 3.1 Pro (High)"` | Best Gemini reasoning (quotes required due to spaces) |
| `--model "Gemini 3.1 Pro (Low)"` | Faster Gemini Pro |
| `--model "Gemini 3.5 Flash (High)"` | Faster, cheaper Gemini |
| `--model "Claude Opus 4.6 (Thinking)"` | Anthropic via agy (**do not use for cross-check** — loses provider independence) |
| `--model "GPT-OSS 120B (Medium)"` | Open-source GPT-OSS model |
| `-p "prompt"` / `--print` / `--prompt` | Non-interactive print mode (required for scripts) |
| `--print-timeout 5m` | Timeout for print mode (default 5m) |
| `--add-dir <path>` | Add directory to workspace (repeatable) |
| `--dangerously-skip-permissions` | Auto-approve tool permission prompts (for non-interactive scripts) |
| `agy models` | List available models |
| `agy install` | First-time setup (PATH, shell aliases) |

**Note:** `agy` has no `--output-format` flag. Output is always raw text on stdout. Enforce JSON shape in the prompt. For schema validation use Codex.

### Claude Code CLI Options

| Option | Purpose |
|--------|---------|
| `--model opus` | Alias for best available Opus |
| `--model sonnet` | Balanced speed and quality |
| `--model haiku` | Fastest, cheapest for simple tasks |
| `--effort xhigh` | Deep reasoning. Values: `low`, `medium`, `high`, `xhigh`, `max` |
| `--output-format text` | Plain text output (recommended) |
| `--output-format json` | JSON message object output |
| `-p "prompt"` | Non-interactive print mode (required) |
| `--max-turns N` | Limit agentic turns (default: no limit) |
| `--max-budget-usd N` | Cap spend per session |

---

## 9. Provider Comparison

| Use Case | Codex (OpenAI) | Antigravity / agy (Google) | Claude Code (Anthropic) |
|----------|---------------|----------------------------|------------------------|
| Complex architectural review | `gpt-5.5` | `"Gemini 3.1 Pro (High)"` | `opus` |
| Fast code review | `gpt-5.4-mini` | `"Gemini 3.5 Flash (High)"` | `haiku` |
| Security audit (deep) | `gpt-5.5` | `"Gemini 3.1 Pro (High)"` | `opus` |
| Structured output (schema) | `gpt-5.5` + schema | N/A (no schema support) | N/A (no schema support) |
| Multi-provider consensus | All three! | All three! | All three! |

---

## 10. Multi-Provider Consensus Example

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

# 5. Save log (prompt + all responses + your evaluation) into .claude/
cat > "$WORK/prompt.txt" << 'EOF'
Should we use Redis or PostgreSQL for session storage in e-commerce app?
EOF
cat > "$WORK/evaluation.txt" << 'EOF'
[your evaluation: accepted findings, rejected findings, recommendations, uncertainties]
EOF

mkdir -p .claude
TIMESTAMP=$(date '+%Y-%m-%d_%H.%M.%S')
{
  echo "=== Second Opinion Log: $TIMESTAMP ==="
  echo "--- Prompt ---"; cat "$WORK/prompt.txt"
  echo "--- Codex ---"; cat "$WORK/codex_opinion.txt"
  echo "--- agy ---"; cat "$WORK/agy_opinion.txt"
  echo "--- Claude ---"; cat "$WORK/claude_opinion.txt"
  echo "--- Evaluation ---"; cat "$WORK/evaluation.txt"
} > ".claude/_second-opinion-talk_${TIMESTAMP}.log"
```

Analyze agreement/disagreement across all three providers and synthesize a final recommendation.
