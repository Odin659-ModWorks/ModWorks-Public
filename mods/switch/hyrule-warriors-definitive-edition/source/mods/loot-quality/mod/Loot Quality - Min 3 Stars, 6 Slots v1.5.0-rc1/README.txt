Hyrule Warriors: Definitive Edition 1.0.1
Build ID: 815A2C19D1767896

TEST CANDIDATE: generated weapon stars start at 3 and can still roll 4 or 5.
The base skill-slot count is floored at 6 before the game's existing bonuses
and eight-slot cap. Higher natural slot counts remain possible.

This version changes the weighted star roll itself: low-tier weights are skipped,
and 3 is the fallback if no eligible 3-5-star tier is selected. Fixed scenario
rewards do not use that roll and are not raised by this candidate.

The patch changes seven existing instructions and uses no borrowed function or
code cave. It has been assembly-checked but has not yet been tested in Eden.
