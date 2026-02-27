#!/usr/bin/env python3
import argparse
import time
from pathlib import Path
import subprocess

import cv2


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def capture_frame(sim_id: str, path: Path) -> bool:
    result = subprocess.run(
        ["xcrun", "simctl", "io", sim_id, "screenshot", "--type=png", str(path)],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode == 0


def mean_abs_diff(a, b) -> float:
    gray_a = cv2.cvtColor(a, cv2.COLOR_BGR2GRAY)
    gray_b = cv2.cvtColor(b, cv2.COLOR_BGR2GRAY)
    diff = cv2.absdiff(gray_a, gray_b)
    return float(diff.mean())


def main():
    parser = argparse.ArgumentParser(description="Capture simulator frames with motion gating.")
    parser.add_argument("--sim-id", required=True, help="Simulator device id.")
    parser.add_argument("--output-dir", required=True, help="Directory to write frames.")
    parser.add_argument("--fps", type=int, default=15)
    parser.add_argument("--frame-count", type=int, default=45)
    parser.add_argument("--gate-threshold", type=float, default=4.0, help="Mean diff to start capture.")
    parser.add_argument("--gate-consecutive", type=int, default=1, help="Consecutive diffs to trigger.")
    parser.add_argument("--gate-timeout", type=float, default=8.0, help="Seconds before forcing capture.")
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    ensure_dir(output_dir)
    scratch = output_dir / "_scratch.png"

    interval = 1.0 / max(1, args.fps)
    saved = 0
    prev_img = None
    consecutive = 0
    armed = False
    start_time = time.time()

    while saved < args.frame_count:
        ok = capture_frame(args.sim_id, scratch)
        if not ok:
            time.sleep(interval)
            continue

        img = cv2.imread(str(scratch))
        if img is None:
            time.sleep(interval)
            continue

        if prev_img is None:
            prev_img = img
            time.sleep(interval)
            continue

        diff_score = mean_abs_diff(prev_img, img)

        if not armed:
            if diff_score >= args.gate_threshold:
                consecutive += 1
            else:
                consecutive = 0

            if consecutive >= args.gate_consecutive:
                armed = True

            if (time.time() - start_time) >= args.gate_timeout:
                armed = True

        if armed:
            out_path = output_dir / f"frame_{saved:03d}.png"
            out_path.write_bytes(Path(scratch).read_bytes())
            saved += 1

        prev_img = img
        time.sleep(interval)


if __name__ == "__main__":
    main()
