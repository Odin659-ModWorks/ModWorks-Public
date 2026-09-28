# Fullscreen Menu Fade 4 Frames v0.1.0

For Xenoblade Chronicles 2 update 2.1.0, build ID
`F77F1559371C0EC6D50E78774AC59D95` only.

This mod changes the two **default** full-screen menu fade requests from
15 frames (about 0.5 seconds at 30 FPS) to 4 frames (about 0.13 seconds).
It is intended to speed the black transition on opening and closing the
main Characters/Blades menu. It does not skip menu work or transactions,
change gameplay speed, or touch the separate shop-sell callback. Caller-
supplied fade durations are unchanged.

Original executable instructions at both addresses are `E1 0F 00 32`
(`mov w1, #15`). The replacement is `81 00 80 52` (`mov w1, #4`).
The entry call is at `0x352014` and the exit call at `0x352A48` in the
2.1.0 executable. The user confirmed in gameplay that the transition feels
faster and works correctly; before/after video also showed a shorter fade.

Install or remove only while Eden is closed. This mod affects the default
full-screen transition; it does not fix the separate shop post-sale input
delay or quest-banner timing. It can be removed without changing saves.
