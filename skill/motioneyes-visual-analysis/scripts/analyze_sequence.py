#!/usr/bin/env python3
import argparse
import json
import math
import os
import subprocess
import sys
import time
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
GRIDGPT_FONT = ROOT / "third_party" / "GridGPT" / "arial.ttf"


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def natural_sort(paths):
    return sorted(paths, key=lambda p: p.name)


def load_frames_from_dir(frames_dir: Path):
    frame_paths = [p for p in frames_dir.iterdir() if p.suffix.lower() in {".png", ".jpg", ".jpeg"}]
    frame_paths = natural_sort(frame_paths)
    frames = []
    for path in frame_paths:
        img = cv2.imread(str(path))
        if img is None:
            continue
        frames.append((path, img))
    return frames


def extract_frames_from_video(
    video_path: Path,
    frames_dir: Path,
    target_fps: int,
    duration: float | None,
    start_time: float,
):
    ensure_dir(frames_dir)
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Unable to open video: {video_path}")

    video_fps = cap.get(cv2.CAP_PROP_FPS)
    if not video_fps or math.isnan(video_fps) or video_fps <= 0:
        video_fps = target_fps

    frame_interval = max(1, round(video_fps / target_fps))
    frame_idx = 0
    saved_idx = 0
    start_frame = max(0, int(round(start_time * video_fps)))
    end_frame = None
    if duration is not None:
        end_frame = start_frame + int(round(duration * video_fps))

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        if frame_idx < start_frame:
            frame_idx += 1
            continue
        if end_frame is not None and frame_idx > end_frame:
            break

        if frame_idx % frame_interval == 0:
            out_path = frames_dir / f"frame_{saved_idx:03d}.png"
            cv2.imwrite(str(out_path), frame)
            saved_idx += 1

        frame_idx += 1

    cap.release()
    return load_frames_from_dir(frames_dir)


def capture_macos_frames(output_dir: Path, fps: int, duration: float, window_id: str | None, region: str | None):
    ensure_dir(output_dir)
    interval = 1.0 / fps
    frame_count = max(1, int(round(duration * fps)))

    for idx in range(frame_count):
        out_path = output_dir / f"frame_{idx:03d}.png"
        cmd = ["screencapture", "-x"]
        if window_id:
            cmd += ["-l", window_id]
        if region:
            cmd += ["-R", region]
        cmd.append(str(out_path))
        subprocess.run(cmd, check=True)
        time.sleep(interval)

    return load_frames_from_dir(output_dir)


def normalize_frames(frames):
    if not frames:
        return frames, False
    heights = [img.shape[0] for _, img in frames]
    widths = [img.shape[1] for _, img in frames]
    min_h, min_w = min(heights), min(widths)
    resized = False
    normalized = []
    for path, img in frames:
        if img.shape[0] != min_h or img.shape[1] != min_w:
            resized = True
            img = cv2.resize(img, (min_w, min_h), interpolation=cv2.INTER_AREA)
        normalized.append((path, img))
    return normalized, resized


def compute_mean_abs_diffs(frames):
    if len(frames) < 2:
        return []
    diffs = []
    for idx in range(len(frames) - 1):
        gray_a = cv2.cvtColor(frames[idx][1], cv2.COLOR_BGR2GRAY)
        gray_b = cv2.cvtColor(frames[idx + 1][1], cv2.COLOR_BGR2GRAY)
        diff = cv2.absdiff(gray_a, gray_b)
        diffs.append(float(diff.mean()))
    return diffs


def find_trim_window(diff_scores, frame_count, threshold, relative, padding, min_run):
    if not diff_scores:
        return None
    max_diff = max(diff_scores)
    if max_diff <= 0:
        return None
    abs_threshold = max_diff * relative
    if threshold is not None:
        abs_threshold = max(abs_threshold, min(threshold, max_diff))

    segments = []
    current_start = None
    for idx, score in enumerate(diff_scores):
        if score >= abs_threshold:
            if current_start is None:
                current_start = idx
        else:
            if current_start is not None:
                segments.append((current_start, idx - 1))
                current_start = None
    if current_start is not None:
        segments.append((current_start, len(diff_scores) - 1))

    segments = [seg for seg in segments if (seg[1] - seg[0] + 1) >= min_run]
    if not segments:
        return None

    segments.sort(key=lambda seg: (-(seg[1] - seg[0] + 1), seg[0]))
    best = segments[0]
    start_idx = max(0, best[0] - padding)
    end_idx = min(frame_count - 1, best[1] + 1 + padding)

    return {
        "start": start_idx,
        "end": end_idx,
        "threshold": abs_threshold,
        "max_diff": max_diff,
        "segment": best,
    }


def grid_label(index: int) -> str:
    if index < 1000:
        return f"{index:03d}"
    index -= 1000
    return f"{chr(65 + index // 100)}{index % 100:02d}"


def resolve_grid_theme(image_bgr, theme: str) -> str:
    if theme in {"light", "dark"}:
        return theme
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    mean_luma = gray.mean()
    return "light" if mean_luma < 110 else "dark"


def add_grid_overlay(image_bgr, cell_size: int, font_path: Path | None, theme: str = "auto"):
    image = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
    base = Image.fromarray(image).convert("RGBA")
    overlay = Image.new("RGBA", base.size, (255, 255, 255, 0))

    if font_path and font_path.exists():
        font = ImageFont.truetype(str(font_path), 16)
    else:
        font = ImageFont.load_default()

    draw = ImageDraw.Draw(overlay)
    width, height = base.size
    cols = math.ceil(width / cell_size)
    rows = math.ceil(height / cell_size)
    resolved_theme = resolve_grid_theme(image_bgr, theme)
    if resolved_theme == "light":
        label_bg = (0, 0, 0, 110)
        grid_color = (255, 255, 255, 110)
        text_color = (255, 255, 255, 200)
    else:
        label_bg = (255, 255, 255, 32)
        grid_color = (0, 0, 0, 70)
        text_color = (0, 0, 0, 120)

    for y in range(rows):
        for x in range(cols):
            left = x * cell_size
            top = y * cell_size
            right = min(left + cell_size, width)
            bottom = min(top + cell_size, height)
            draw.rectangle([left, top, right, bottom], outline=grid_color, fill=label_bg)
            label = grid_label(x + y * cols)
            draw.text((left + 6, top + 6), label, font=font, fill=text_color)

    combined = Image.alpha_composite(base, overlay)
    return cv2.cvtColor(np.array(combined.convert("RGB")), cv2.COLOR_RGB2BGR)


def compute_diff(gray_a, gray_b):
    diff = cv2.absdiff(gray_a, gray_b)
    mean_abs = float(diff.mean())
    _, thresh = cv2.threshold(diff, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel, iterations=2)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    bboxes = []
    for c in contours:
        x, y, w, h = cv2.boundingRect(c)
        if w * h < 64:
            continue
        bboxes.append({"x": int(x), "y": int(y), "w": int(w), "h": int(h)})
    return diff, mean_abs, mask, bboxes


def estimate_affine(gray_a, gray_b):
    orb = cv2.ORB_create(500)
    kp1, des1 = orb.detectAndCompute(gray_a, None)
    kp2, des2 = orb.detectAndCompute(gray_b, None)
    if des1 is None or des2 is None:
        return None
    matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
    matches = matcher.match(des1, des2)
    if len(matches) < 6:
        return None
    matches = sorted(matches, key=lambda m: m.distance)[:50]
    src_pts = np.float32([kp1[m.queryIdx].pt for m in matches])
    dst_pts = np.float32([kp2[m.trainIdx].pt for m in matches])
    matrix, _ = cv2.estimateAffinePartial2D(src_pts, dst_pts, method=cv2.RANSAC)
    return matrix


def affine_to_params(matrix):
    if matrix is None:
        return None
    a, b, tx = matrix[0]
    c, d, ty = matrix[1]
    scale = math.sqrt(a * a + b * b)
    rotation = math.degrees(math.atan2(b, a))
    return {
        "affine_dx": float(tx),
        "affine_dy": float(ty),
        "rotation_deg": float(rotation),
        "scale_ratio": float(scale),
    }


def compute_color_delta(frame_a, frame_b, mask):
    if mask is None or mask.sum() == 0:
        return {"h": 0.0, "s": 0.0, "v": 0.0}, 0.0
    hsv_a = cv2.cvtColor(frame_a, cv2.COLOR_BGR2HSV).astype(np.float32)
    hsv_b = cv2.cvtColor(frame_b, cv2.COLOR_BGR2HSV).astype(np.float32)
    mask_bool = mask.astype(bool)
    mean_a = hsv_a[mask_bool].mean(axis=0)
    mean_b = hsv_b[mask_bool].mean(axis=0)
    delta = (mean_b - mean_a) / np.array([180.0, 255.0, 255.0])
    opacity_delta = float((frame_b[mask_bool].mean() - frame_a[mask_bool].mean()) / 255.0)
    return {"h": float(delta[0]), "s": float(delta[1]), "v": float(delta[2])}, opacity_delta


def pick_keyframes(frame_count, diff_scores):
    if frame_count <= 3:
        return list(range(frame_count))
    start = 0
    mid = frame_count // 2
    end = frame_count - 1
    top_pairs = sorted(range(len(diff_scores)), key=lambda i: diff_scores[i], reverse=True)[:2]
    top_frames = [min(frame_count - 1, i + 1) for i in top_pairs]
    keyframes = [start, mid, end] + top_frames
    return sorted(set(keyframes))


def make_sprite_sheet(frames, keyframes, output_path: Path):
    images = [Image.fromarray(cv2.cvtColor(frames[i], cv2.COLOR_BGR2RGB)) for i in keyframes]
    labels = [f"frame {i}" for i in keyframes]
    cols = min(3, len(images))
    rows = math.ceil(len(images) / cols)
    thumb_w, thumb_h = images[0].size
    label_h = 24
    sheet_w = cols * thumb_w
    sheet_h = rows * (thumb_h + label_h)
    sheet = Image.new("RGB", (sheet_w, sheet_h), (20, 20, 20))

    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()

    for idx, img in enumerate(images):
        row = idx // cols
        col = idx % cols
        x = col * thumb_w
        y = row * (thumb_h + label_h)
        sheet.paste(img, (x, y))
        draw.text((x + 6, y + thumb_h + 4), labels[idx], fill=(230, 230, 230), font=font)

    sheet.save(output_path)


def build_summary(motion, key_frames, diff_scores):
    dx = motion.get("affine_dx", 0.0)
    dy = motion.get("affine_dy", 0.0)
    mag = math.hypot(dx, dy)

    dir_x = "right" if dx > 0.2 else "left" if dx < -0.2 else "stable"
    dir_y = "down" if dy > 0.2 else "up" if dy < -0.2 else "stable"
    top_delta = sorted(range(len(diff_scores)), key=lambda i: diff_scores[i], reverse=True)[:2]

    summary = (
        f"Primary motion trends {dir_x} and {dir_y}. "
        f"Estimated translation magnitude is {mag:.2f}. "
        f"Largest visual deltas occur around pairs {top_delta}. "
        f"Key frames: {key_frames}."
    )
    return summary


def generate_report(output_dir: Path, summary_text: str):
    index_path = output_dir / "index.html"
    summary_path = output_dir / "summary.md"
    analysis_path = output_dir / "analysis.json"

    with summary_path.open("w", encoding="utf-8") as f:
        f.write(summary_text + "\n")

    html = """<!doctype html>
<html lang=\"en\">
<head>
<meta charset=\"utf-8\" />
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
<title>MotionEyes Visual Analysis Report</title>
<style>
body { font-family: ui-sans-serif, system-ui; background:#0f1115; color:#e7e9ee; margin:0; padding:24px; }
section { margin-bottom: 32px; }
h1 { margin-top:0; font-size: 24px; }
pre { background:#171a21; padding:16px; border-radius:8px; overflow:auto; }
.grid { display:flex; flex-wrap:wrap; gap:12px; }
.grid img { max-width: 320px; border-radius:8px; border:1px solid #2b2f3a; }
.small { color:#9aa3b2; font-size: 13px; }
</style>
</head>
<body>
<h1>MotionEyes Visual Analysis Report</h1>
<section>
<h2>Summary</h2>
<pre id=\"summary\"></pre>
</section>
<section>
<h2>Analysis JSON</h2>
<pre id=\"analysis\"></pre>
</section>
<section>
<h2>Frames</h2>
<div class=\"grid\" id=\"frames\"></div>
</section>
<section>
<h2>Grid Overlay</h2>
<div class=\"grid\" id=\"grid\"></div>
</section>
<section>
<h2>Diff</h2>
<div class=\"grid\" id=\"diff\"></div>
</section>
<section>
<h2>Diff + Grid</h2>
<div class=\"grid\" id=\"diffgrid\"></div>
</section>
<section>
<h2>Sprite Sheet</h2>
<div class=\"grid\" id=\"sprite\"></div>
</section>
<script>
async function loadText(path) {
  const res = await fetch(path);
  return res.text();
}
async function loadJson(path) {
  const res = await fetch(path);
  return res.json();
}
function addImages(containerId, paths) {
  const container = document.getElementById(containerId);
  paths.forEach(p => {
    const img = document.createElement('img');
    img.src = p;
    container.appendChild(img);
  });
}
(async () => {
  document.getElementById('summary').textContent = await loadText('summary.md');
  const analysis = await loadJson('analysis.json');
  document.getElementById('analysis').textContent = JSON.stringify(analysis, null, 2);
  const frames = analysis.frames.map(f => f.path.replace('frames/', 'frames/'));
  addImages('frames', frames);
  addImages('grid', frames.map(p => p.replace('frames/', 'grid/')));
  addImages('diff', analysis.pairwise_diffs.map(p => `diff/diff_${p.pair[0]}_${p.pair[1]}.png`));
  addImages('diffgrid', analysis.pairwise_diffs.map(p => `diff_grid/diff_grid_${p.pair[0]}_${p.pair[1]}.png`));
  addImages('sprite', ['sprite/keyframes.jpg']);
})();
</script>
</body>
</html>"""

    with index_path.open("w", encoding="utf-8") as f:
        f.write(html)


def main():
    parser = argparse.ArgumentParser(description="Analyze UI motion across frame sequences.")
    parser.add_argument("--video", type=str, help="Path to a video file to sample frames from.")
    parser.add_argument("--frames-dir", type=str, help="Directory of pre-captured frames.")
    parser.add_argument("--output", type=str, default=str(ROOT / "build" / "vision-report"))
    parser.add_argument("--fps", type=int, default=15)
    parser.add_argument("--duration", type=float, help="Duration to sample from video or capture.")
    parser.add_argument("--start", type=float, default=0.0, help="Start time offset (seconds) when sampling video.")
    parser.add_argument("--source", type=str, choices=["video", "frames", "macos"], default="video")
    parser.add_argument("--window-id", type=str, help="macOS window id for screencapture.")
    parser.add_argument("--region", type=str, help="macOS capture region x,y,w,h.")
    parser.add_argument("--no-grid", action="store_true", help="Disable grid overlay generation.")
    parser.add_argument("--grid-cell", type=int, default=80)
    parser.add_argument(
        "--grid-theme",
        type=str,
        choices=["auto", "light", "dark"],
        default="auto",
        help="Grid contrast mode (auto picks based on image brightness).",
    )
    parser.add_argument("--report", action="store_true", help="Generate HTML report for validation.")
    parser.add_argument(
        "--all-pairs",
        action="store_true",
        help="Render diff images for every consecutive pair (default is keyframe pairs only).",
    )
    parser.add_argument(
        "--diff-grid",
        action="store_true",
        help="Generate diff images with grid overlay for faster localization.",
    )
    parser.add_argument("--trim", action="store_true", help="Auto-trim to the motion window.")
    parser.add_argument("--trim-threshold", type=float, default=3.0, help="Minimum mean abs diff to detect motion.")
    parser.add_argument("--trim-relative", type=float, default=0.35, help="Relative threshold vs max diff.")
    parser.add_argument("--trim-padding", type=int, default=0, help="Frames to include before/after motion.")
    parser.add_argument("--trim-min-run", type=int, default=2, help="Minimum consecutive diffs above threshold.")
    args = parser.parse_args()

    output_dir = Path(args.output)
    frames_dir = output_dir / "frames"
    grid_dir = output_dir / "grid"
    diff_dir = output_dir / "diff"
    diff_grid_dir = output_dir / "diff_grid"
    sprite_dir = output_dir / "sprite"

    for d in [frames_dir, grid_dir, diff_dir, diff_grid_dir, sprite_dir]:
        ensure_dir(d)

    if args.source == "macos":
        if not args.duration:
            raise SystemExit("--duration is required for macOS capture")
        frames = capture_macos_frames(frames_dir, args.fps, args.duration, args.window_id, args.region)
    elif args.source == "frames":
        if not args.frames_dir:
            raise SystemExit("--frames-dir is required when source=frames")
        frames = load_frames_from_dir(Path(args.frames_dir))
        # Copy into output frames dir for consistency
        for idx, (path, img) in enumerate(frames):
            out_path = frames_dir / f"frame_{idx:03d}.png"
            cv2.imwrite(str(out_path), img)
        frames = load_frames_from_dir(frames_dir)
    else:
        if not args.video:
            raise SystemExit("--video is required when source=video")
        frames = extract_frames_from_video(Path(args.video), frames_dir, args.fps, args.duration, args.start)

    frames, resized = normalize_frames(frames)
    if not frames:
        raise SystemExit("No frames found to analyze.")

    raw_frame_count = len(frames)
    trim_info = {"enabled": args.trim, "trimmed": False}
    trim_offset = 0
    if args.trim:
        diff_scores = compute_mean_abs_diffs(frames)
        window = find_trim_window(
            diff_scores,
            len(frames),
            args.trim_threshold,
            args.trim_relative,
            args.trim_padding,
            args.trim_min_run,
        )
        if window:
            trim_offset = window["start"]
            frames = frames[window["start"] : window["end"] + 1]
            trim_info = {
                "enabled": True,
                "trimmed": True,
                "start": window["start"],
                "end": window["end"],
                "threshold": window["threshold"],
                "relative": args.trim_relative,
                "max_diff": window["max_diff"],
                "segment": window["segment"],
                "padding": args.trim_padding,
            }
        else:
            trim_info = {
                "enabled": True,
                "trimmed": False,
                "threshold": args.trim_threshold,
                "relative": args.trim_relative,
                "max_diff": max(diff_scores) if diff_scores else 0.0,
            }

    frame_imgs = [img for _, img in frames]
    frame_paths = [frames_dir / f"frame_{idx:03d}.png" for idx in range(len(frame_imgs))]

    for idx, img in enumerate(frame_imgs):
        cv2.imwrite(str(frame_paths[idx]), img)

    if not args.no_grid:
        for idx, img in enumerate(frame_imgs):
            grid_img = add_grid_overlay(
                img,
                args.grid_cell,
                GRIDGPT_FONT if GRIDGPT_FONT.exists() else None,
                theme=args.grid_theme,
            )
            cv2.imwrite(str(grid_dir / f"frame_{idx:03d}.png"), grid_img)

    diff_scores = compute_mean_abs_diffs(list(zip(frame_paths, frame_imgs)))
    keyframes = pick_keyframes(len(frame_imgs), diff_scores)
    if args.all_pairs:
        pair_indices_for_output = set(range(max(0, len(frame_imgs) - 1)))
    else:
        pair_indices_for_output = {idx - 1 for idx in keyframes if idx > 0}

    pairwise = []
    # diff-only metrics

    for idx in range(len(frame_imgs) - 1):
        a = frame_imgs[idx]
        b = frame_imgs[idx + 1]
        gray_a = cv2.cvtColor(a, cv2.COLOR_BGR2GRAY)
        gray_b = cv2.cvtColor(b, cv2.COLOR_BGR2GRAY)

        diff, mean_abs, diff_mask, diff_bboxes = compute_diff(gray_a, gray_b)

        if idx in pair_indices_for_output:
            cv2.imwrite(str(diff_dir / f"diff_{idx}_{idx + 1}.png"), diff)

            if args.diff_grid:
                diff_color = cv2.cvtColor(diff, cv2.COLOR_GRAY2BGR)
                diff_grid = add_grid_overlay(
                    diff_color,
                    args.grid_cell,
                    GRIDGPT_FONT if GRIDGPT_FONT.exists() else None,
                    theme=args.grid_theme,
                )
                cv2.imwrite(str(diff_grid_dir / f"diff_grid_{idx}_{idx + 1}.png"), diff_grid)

            pairwise.append(
                {
                    "pair": [idx, idx + 1],
                    "mean_abs_diff": mean_abs,
                    "diff_bboxes": diff_bboxes,
                }
            )

    affine_matrix = None
    if len(frame_imgs) >= 2:
        affine_matrix = estimate_affine(
            cv2.cvtColor(frame_imgs[0], cv2.COLOR_BGR2GRAY),
            cv2.cvtColor(frame_imgs[-1], cv2.COLOR_BGR2GRAY),
        )
    affine_params = affine_to_params(affine_matrix) or {}

    color_delta, opacity_delta = (0.0, 0.0), 0.0
    if len(frame_imgs) >= 2:
        gray_first = cv2.cvtColor(frame_imgs[0], cv2.COLOR_BGR2GRAY)
        gray_last = cv2.cvtColor(frame_imgs[-1], cv2.COLOR_BGR2GRAY)
        _, _, final_mask, _ = compute_diff(gray_first, gray_last)
        color_delta, opacity_delta = compute_color_delta(frame_imgs[0], frame_imgs[-1], final_mask)

    motion = {
        "opacity_delta": opacity_delta,
        "color_delta": color_delta,
    }
    motion.update(affine_params)

    make_sprite_sheet(frame_imgs, keyframes, sprite_dir / "keyframes.jpg")

    summary = build_summary(motion, keyframes, diff_scores)

    metadata = {
        "source": args.source,
        "fps": args.fps,
        "duration": args.duration,
        "start": args.start,
        "raw_frame_count": raw_frame_count,
        "frame_count": len(frame_imgs),
        "resolution": {"width": frame_imgs[0].shape[1], "height": frame_imgs[0].shape[0]},
        "resized": resized,
        "trim": trim_info,
    }

    analysis = {
        "metadata": metadata,
        "frames": [
            {
                "index": idx,
                "timestamp": args.start + ((trim_offset + idx) / args.fps),
                "path": f"frames/frame_{idx:03d}.png",
            }
            for idx in range(len(frame_imgs))
        ],
        "pairwise_diffs": pairwise,
        "pairwise_rendered": sorted(pair_indices_for_output),
        "motion": motion,
        "key_frames": {
            "start": 0,
            "mid": len(frame_imgs) // 2,
            "end": len(frame_imgs) - 1,
            "top_delta": sorted(range(len(diff_scores)), key=lambda i: diff_scores[i], reverse=True)[:2],
        },
    }

    with (output_dir / "analysis.json").open("w", encoding="utf-8") as f:
        json.dump(analysis, f, indent=2)

    with (output_dir / "summary.md").open("w", encoding="utf-8") as f:
        f.write(summary + "\n")

    if args.report:
        generate_report(output_dir, summary)

    print(f"Wrote analysis to {output_dir}")


if __name__ == "__main__":
    main()
