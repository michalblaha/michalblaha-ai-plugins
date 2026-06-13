# Humanizer — English Rules

Based on [Wikipedia's Signs of AI Writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing).

## Detection Categories

### CRITICAL — Immediate AI Detection

**Citation Bugs** (weight: 5x)
Flag any occurrence of: `oaicite`, `oai_citation`, `contentReference`, `turn0search`, `turn0image`, `utm_source=chatgpt`, `utm_source=openai`, `attached_file`, `grok_card`

**Knowledge Cutoff Phrases** (weight: 3x)
Flag: "as of my last", "as of my knowledge", "up to my last training", "based on available information", "while specific details are limited", "not widely available", "not widely documented", "in the provided sources", "in available sources"

**Chatbot Artifacts** (weight: 3x)
Flag and remove entire sentences containing: "I hope this helps", "Let me know if", "Would you like me to", "Great question", "Excellent question", "You're absolutely right", "That's a great point", "That's an excellent point", "Certainly!", "Of course!", "Absolutely!", "Happy to help", "I'd be happy to", "Feel free to", "Don't hesitate to", "Here is a", "Here's a", "I can help you with", "As an AI", "As a language model", "As an AI language model"

**Markdown Artifacts** (weight: 2x)
Flag: `**bold**`, `## headers`, ` ``` code blocks ``` `, `* **`, `- **`, `1. **`

### HIGH SIGNAL

**AI Vocabulary**
Flag these overused AI words: additionally, align with, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight, interplay, intricate, intricacies, key, landscape, pivotal, showcase, showcasing, tapestry, testament, underscore, underscores, valuable, vibrant, nuanced, multifaceted, paradigm, synergy, realm, underpins, unraveling, unveiling, leveraging, furthermore, moreover, consequently, subsequently, henceforth, thereby, wherein, thereof, whatsoever, nevertheless, notwithstanding

**Significance Inflation**
Flag: "stands as", "serves as", "is a testament", "is a reminder", "vital role", "significant role", "crucial role", "pivotal role", "key role", "pivotal moment", "key moment", "key turning point", "underscores its importance", "highlights its importance", "underscores its significance", "highlights its significance", "reflects broader", "symbolizing its ongoing/enduring/lasting", "contributing to the", "setting the stage for", "marking the", "shaping the", "represents a shift", "marks a shift", "evolving landscape", "focal point", "indelible mark", "deeply rooted", "enduring legacy", "rich tapestry", "broader movement"

**Promotional Language**
Flag: "boasts a/an", "vibrant", "rich cultural heritage", "profound", "enhancing its", "exemplifies", "commitment to", "natural beauty", "nestled", "in the heart of", "groundbreaking", "renowned", "breathtaking", "must-visit", "stunning", "bustling", "game-changing", "cutting-edge", "state-of-the-art", "world-class", "best-in-class", "industry-leading", "innovative", "revolutionary"

**Copula Avoidance** — Replace these:
| AI Pattern | Human Replacement |
|---|---|
| serves as a/an/the | is a/an/the |
| stands as a/an/the | is a/an/the |
| marks a/an/the | is a/an/the |
| represents a/an/the | is a/an/the |
| boasts a/an/the | has a/an/the |
| features a/an/the | has a/an/the |
| offers a/an | has a/an |

### MEDIUM SIGNAL

**Superficial -ing Constructions**
Flag: "highlighting", "underscoring", "emphasizing", "ensuring", "reflecting", "symbolizing", "contributing to", "cultivating", "fostering", "encompassing", "showcasing", "valuable insights", "align(s) with", "resonate(s) with"

**Filler Phrases** — Replace these:
| AI Filler | Human Replacement |
|---|---|
| in order to | to |
| due to the fact that | because |
| at this point in time | now |
| at the present time | now |
| has the ability to | can |
| it is important to note that | (remove) |
| it should be noted that | (remove) |
| it is worth noting that | (remove) |
| it is crucial to note that | (remove) |
| it is critical to remember that | (remove) |
| it goes without saying that | (remove) |
| needless to say | (remove) |
| Additionally, | (remove) |
| Furthermore, | (remove) |
| Moreover, | (remove) |
| In conclusion, | (remove) |
| To summarize, | (remove) |
| In summary, | (remove) |
| Overall, | (remove) |
| utilize/utilizes/utilizing/utilization | use/uses/using/use |
| leverage/leverages/leveraging | use/uses/using |
| facilitate/facilitates/facilitating | help/helps/helping |
| prioritize/prioritizes | focus on/focuses on |
| optimize/optimizes | improve/improves |
| streamline/streamlines | simplify/simplifies |

**Vague Attributions**
Flag: "industry reports", "observers have cited", "experts argue", "experts believe", "some critics argue", "several sources", "several publications", "according to experts", "widely regarded", "it is widely believed", "many believe", "some would say"

**Challenges Formula**
Flag: "despite its", "faces several challenges", "despite these challenges", "challenges and legacy", "future outlook", "future prospects", "looking ahead", "moving forward", "going forward"

**Hedging Phrases**
Flag: "it could potentially", "it might possibly", "arguably", "it could be argued that", "some would say", "in some ways", "to some extent", "in certain respects", "may vary", "results may vary"

### STYLE SIGNAL

**Curly Quotes** (ChatGPT signature)
Replace: `"` `"` -> `"`, `'` `'` -> `'`

**Em Dash Overuse**
Flag if more than 3 em dashes (—) in the text. Replace excessive em dashes with commas.

**Negative Parallelisms**
Flag: "not only... but also", "it's not just about... it's about", "it is not merely... it is", "not just... but", "no longer... instead"

**Rule of Three**
Flag forced triplets: "innovation, inspiration, and...", "engage, educate, and...", "plan, execute, and...", "design, develop, and...", "research, develop, and...", "create, collaborate, and...", "learn, grow, and..."

## AI Probability Scoring

| Rating | Criteria |
|---|---|
| Very High | Citation bugs, knowledge cutoff, or chatbot artifacts present |
| High | >30 issues OR >5% issue density (issues/words * 100) |
| Medium | >15 issues OR >2% issue density |
| Low | <15 issues AND <2% density |

## Report Format

```
AI DETECTION SCAN — {issue_count} issues ({word_count} words)
AI Probability: {LOW/MEDIUM/HIGH/VERY HIGH}

{For each category with findings, list the category name, found patterns, and counts}

{If transforming: show "TRANSFORMATIONS ({count})" section listing all changes made}
{Show before/after comparison: issues, probability, word count, improvement %}
```

## Transformation Rules (in order)

1. Remove citation bugs (oaicite, turn0search, contentReference, etc.)
2. Strip markdown formatting (bold, headers, code blocks)
3. Remove entire sentences containing chatbot artifacts
4. Apply copula avoidance replacements (serves as -> is, boasts -> has)
5. Apply filler phrase replacements (in order to -> to, utilize -> use, etc.)
6. Fix curly quotes to straight quotes
7. In aggressive mode: simplify -ing clauses, replace excessive em dashes with commas

## Important Notes

- Preserve the original meaning and factual content
- Do not add new information or change facts
- Keep the same overall structure and paragraph breaks
- When removing filler, ensure sentences still flow naturally
- AI vocabulary words are flagged for awareness but not auto-replaced (they require contextual judgment)
- After transformation, re-scan and report improvement
