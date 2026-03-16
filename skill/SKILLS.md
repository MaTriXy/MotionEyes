# MotionEyes Skills

Use this guide to choose the right MotionEyes skill.

## Quick Choice

- Use `motioneyes-animation-debug` when you can instrument the app and need precise timing, easing, geometry values, or trace-based assertions from MotionEyes logs.
- Use `motioneyes-visual-analysis` when you only have pixels (screenshots/video), need regression diffs, or `.transition` and visual effects are not observable via MotionEyes logs.

## Comparison

| Skill | Best For | Signals | Requires App Changes |
| --- | --- | --- | --- |
| `motioneyes-animation-debug` | Timing, easing, geometry values, scroll offsets, trace assertions | MotionEyes log traces | Yes (temporary instrumentation) |
| `motioneyes-visual-analysis` | Visual changes, `.transition`, pixel diffs, regression checks | Frame diffs, SSIM, optical flow | No |
