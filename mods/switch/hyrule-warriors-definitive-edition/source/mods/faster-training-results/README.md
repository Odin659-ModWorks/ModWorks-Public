# Faster Training Results — development history

**Goal.** Reduce the repeated wait after Training Dojo level gains without changing EXP, level application, or result messages.

**Current result.** `v1.0.0`, Definitive Edition update 1.0.1, build `815A2C19D1767896`. The user tested the Dojo flow and reported it working. The standalone add-on is also included in Faster Bazaar.

**How it was built.** `FUN_7100361608` runs the per-level result sequence. At `0x7100361798`, the original instruction loads a 30-frame countdown into object `+0x0c`. The patch substitutes a five-frame countdown and leaves the surrounding level, message, animation, and sound calls intact. Exact instruction words are recorded in `research/NOTES.txt`, and the release writes are in `mod/Faster Training Results v1.0.0`.

**Limits.** This shortens the Dojo result sequence, not all training or menu animations. No unrelated progression changes were intended or reported.
