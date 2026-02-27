---
name: motioneyes-visual-analysis
description: Pixel-based motion and UI change analysis from frame sequences or screenshots using computer vision and visual comparison. Use when `.transition` or visual effects are not observable via MotionEyes logs, when you only have screenshots/video, when you need regression diffs across builds, or when you need to summarize on-screen changes without instrumentation. Do not use when MotionEyes traces are available and you need precise timing/values; use `motioneyes-animation-debug` instead.
---

# MotionEyes Visual Analysis

## Overview

Analyze UI motion by comparing frames directly. This skill produces annotated images plus a JSON summary of motion signals (translation, scale, rotation, opacity, color) and changed regions. It complements MotionEyes traces when instrumentation is unavailable or insufficient.

## Use With the Other MotionEyes Skill

- Use `motioneyes-animation-debug` when you can instrument the app and need precise timing or value traces.
- Use this skill when you only have pixels or when `.transition` and similar effects do not surface in MotionEyes logs.

## Inputs

Use one of these inputs:

- **Frames directory** with sequential image files (PNG/JPG).
- **Video file** captured from the simulator (preferred). Frames are extracted at `--fps`.
- **macOS window capture** using `screencapture` with a window id.

## Workflow

Follow this order:

1. Capture or gather frames for the target animation.
2. Normalize frames (same size, consistent crop).
3. Run analysis to generate diffs and grid overlays.
4. Select key frames (start/mid/end + top delta frames) for summary.
5. Write `analysis.json` and `summary.md`.
6. If validating the skill itself, optionally generate an HTML report with `--report`.
7. Use `--trim` to align analysis to the motion window and reduce static frames. Adjust with `--trim-threshold` and `--trim-relative` if the animation is subtle.

## Frame Capture

### Simulator (preferred)

- Use XcodeBuildMCP to run the app and record video.
- Record only the animation window you care about (for example, 1.0s).
- For precise start timing, use the capture script with motion gating so frames only begin once pixels change.

Example flow:

1. Build and run the demo app.
2. Trigger the animation.
3. Capture frames with motion gating.
4. Run analysis using `--frames-dir`.

Motion-gated capture (simulator):

```bash
python3 scripts/capture_sim_frames.py \
  --sim-id <SIM_ID> \
  --output-dir /path/to/frames_raw \
  --fps 15 \
  --frame-count 45 \
  --gate-threshold 4.0 \
  --gate-consecutive 1
```

### macOS window capture

- Use `scripts/analyze_sequence.py --source macos --window-id <id> --duration <seconds> --fps <fps>`.
- The script uses `screencapture` on the specified window id.

### Pre-captured frames

- Place images in a folder named `frames/`.
- Run analysis using `--frames-dir`.

## Pairwise Diffs

- Diff images are generated between **consecutive frames** (frame _n_ vs _n+1_).
- By default, only keyframe pairs are rendered. Use `--all-pairs` to render every pair.
- Use `--diff-grid` to overlay the alphanumeric grid on diff images for faster localization.
- Use `--grid-theme auto|light|dark` to ensure the grid is readable on dark or light backgrounds.

## Keyframe Selection

- Always analyze **all frames** for metrics.
- Summarize using **start**, **mid**, **end**, and the **top 2 delta frames**.
- If the sequence is very short (<=3 frames), include all frames.

## Outputs

The analyzer writes to the `--output` directory:

- `analysis.json`: machine-readable metrics.
- `summary.md`: short human summary.
- `frames/`: normalized frames.
- `grid/`: frames with alphanumeric grid overlay.
- `diff/`: absolute diff images.
- `diff_grid/`: diff images with grid overlay (when `--diff-grid` is enabled).
- `sprite/`: keyframe sprite sheet.

## Scripts

Primary entrypoint:

```bash
python3 scripts/analyze_sequence.py --video /path/to/capture.mp4 --fps 15 --duration 1.0 --output /path/to/report
```

If the capture includes idle time before/after the animation, add `--trim` to auto-detect the motion window.

See `scripts/analyze_sequence.py --help` for all flags.

## Dependencies

Create a local venv and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Reference

Load these references when needed:

- `references/motion-analysis-techniques.md`
- `references/report-schema.md`
- `references/grid-overlay-notes.md`
