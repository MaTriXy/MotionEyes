#!/usr/bin/env python3
import argparse
import html
import json
from datetime import datetime
from pathlib import Path


def load_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def load_json(path: Path):
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def image_list(dir_path: Path):
    if not dir_path.exists():
        return []
    return sorted([p.name for p in dir_path.iterdir() if p.suffix.lower() in {".png", ".jpg", ".jpeg"}])


def format_float(value, digits=3):
    try:
        return f"{float(value):.{digits}f}"
    except (TypeError, ValueError):
        return "-"


def format_color_delta(delta):
    if not isinstance(delta, dict):
        return "-"
    return f"h {format_float(delta.get('h'))}, s {format_float(delta.get('s'))}, v {format_float(delta.get('v'))}"


def render_gallery(title, name, subdir, items, open_by_default=False):
    if not items:
        return ""
    imgs = "\n".join(
        f'<img src="scenarios/{name}/{subdir}/{item}" alt="{html.escape(title)} {html.escape(item)}" />'
        for item in items
    )
    open_attr = " open" if open_by_default else ""
    return f"""
<details{open_attr}>
  <summary>{html.escape(title)}</summary>
  <div class="grid">
    {imgs}
  </div>
</details>
"""


def render_keyframes(name, key_indices):
    if not key_indices:
        return ""
    imgs = "\n".join(
        f'<img src="scenarios/{name}/frames/frame_{idx:03d}.png" alt="Key frame {idx}" />'
        for idx in key_indices
    )
    return f"""
<div class="grid keyframes">
  {imgs}
</div>
"""


def render_scenario(root: Path, name: str) -> str:
    scenario_dir = root / "scenarios" / name
    analysis = load_json(scenario_dir / "analysis.json")
    summary = load_text(scenario_dir / "summary.md").strip()

    meta = analysis.get("metadata", {})
    motion = analysis.get("motion", {})
    key_frames = analysis.get("key_frames", {})

    frames = image_list(scenario_dir / "frames")
    grid = image_list(scenario_dir / "grid")
    diff = image_list(scenario_dir / "diff")
    diff_grid = image_list(scenario_dir / "diff_grid")
    sprite = image_list(scenario_dir / "sprite")

    key_indices = []
    for key in ["start", "mid", "end"]:
        if isinstance(key_frames.get(key), int):
            key_indices.append(key_frames[key])
    for idx in key_frames.get("top_delta", []) or []:
        if isinstance(idx, int):
            key_indices.append(idx + 1)
    key_indices = sorted({idx for idx in key_indices if 0 <= idx < len(frames)})

    analysis_json = html.escape(json.dumps(analysis, indent=2))
    summary_text = html.escape(summary) if summary else "No summary generated."

    trim_meta = meta.get("trim", {}) if isinstance(meta.get("trim", {}), dict) else {}
    trim_range = "-"
    if trim_meta.get("trimmed"):
        trim_range = f"{trim_meta.get('start', '-')}-{trim_meta.get('end', '-')}"
    trim_threshold = trim_meta.get("threshold", "-")

    metadata_table = f"""
    <table class="kv">
      <tr><th>FPS</th><td>{html.escape(str(meta.get('fps', '-')))}</td></tr>
      <tr><th>Frames</th><td>{html.escape(str(meta.get('frame_count', '-')))}</td></tr>
      <tr><th>Raw Frames</th><td>{html.escape(str(meta.get('raw_frame_count', '-')))}</td></tr>
      <tr><th>Duration</th><td>{html.escape(str(meta.get('duration', '-')))}</td></tr>
      <tr><th>Start</th><td>{html.escape(str(meta.get('start', '-')))}</td></tr>
      <tr><th>Resolution</th><td>{html.escape(str(meta.get('resolution', '-')))}</td></tr>
      <tr><th>Resized</th><td>{html.escape(str(meta.get('resized', '-')))}</td></tr>
      <tr><th>Trimmed</th><td>{html.escape(str(trim_meta.get('trimmed', '-')))}</td></tr>
      <tr><th>Trim Range</th><td>{html.escape(str(trim_range))}</td></tr>
      <tr><th>Trim Threshold</th><td>{html.escape(str(trim_threshold))}</td></tr>
    </table>
    """

    motion_table = f"""
    <table class="kv">
      <tr><th>Translation DX</th><td>{format_float(motion.get('affine_dx'))}</td></tr>
      <tr><th>Translation DY</th><td>{format_float(motion.get('affine_dy'))}</td></tr>
      <tr><th>Rotation (deg)</th><td>{format_float(motion.get('rotation_deg'))}</td></tr>
      <tr><th>Scale Ratio</th><td>{format_float(motion.get('scale_ratio'))}</td></tr>
      <tr><th>Opacity Delta</th><td>{format_float(motion.get('opacity_delta'))}</td></tr>
      <tr><th>Color Delta</th><td>{format_color_delta(motion.get('color_delta'))}</td></tr>
    </table>
    """

    key_frame_list = ", ".join(str(idx) for idx in key_indices) if key_indices else "n/a"

    return f"""
<section class="scenario" id="scenario-{name}">
  <div class="scenario-header">
    <h2>{html.escape(name.title())}</h2>
    <span class="badge">key frames: {html.escape(key_frame_list)}</span>
  </div>
  <div class="meta">
    <div class="card">
      <h3>Summary</h3>
      <pre>{summary_text}</pre>
    </div>
    <div class="card">
      <h3>Metadata</h3>
      {metadata_table}
    </div>
    <div class="card">
      <h3>Motion Metrics</h3>
      {motion_table}
    </div>
  </div>

  <section class="subsection">
    <h3>Key Frames</h3>
    {render_keyframes(name, key_indices)}
  </section>

    <section class="subsection">
    <h3>Galleries</h3>
    {render_gallery("All Frames", name, "frames", frames)}
    {render_gallery("Grid Overlay", name, "grid", grid)}
    {render_gallery("Diff Images", name, "diff", diff)}
    {render_gallery("Diff + Grid", name, "diff_grid", diff_grid)}
    {render_gallery("Sprite Sheet", name, "sprite", sprite, open_by_default=True)}
  </section>

  <details class="json-block">
    <summary>Analysis JSON</summary>
    <pre>{analysis_json}</pre>
  </details>
</section>
"""


def render_overview(root: Path, scenarios) -> str:
    rows = []
    for name in scenarios:
        analysis = load_json(root / "scenarios" / name / "analysis.json")
        summary = load_text(root / "scenarios" / name / "summary.md").strip()
        meta = analysis.get("metadata", {})
        motion = analysis.get("motion", {})
        rows.append(
            f"""
            <tr>
              <td><a href="#scenario-{html.escape(name)}">{html.escape(name.title())}</a></td>
              <td>{html.escape(str(meta.get('frame_count', '-')))}</td>
              <td>{html.escape(str(meta.get('fps', '-')))}</td>
              <td>{html.escape(str(meta.get('resolution', '-')))}</td>
              <td>{format_float(motion.get('affine_dx'))}</td>
              <td>{format_float(motion.get('affine_dy'))}</td>
              <td>{format_float(motion.get('rotation_deg'))}</td>
              <td>{format_float(motion.get('scale_ratio'))}</td>
              <td>{format_float(motion.get('opacity_delta'))}</td>
              <td class="summary-cell">{html.escape(summary)}</td>
            </tr>
            """
        )
    table_rows = "\n".join(rows) if rows else "<tr><td colspan='10'>No scenarios found.</td></tr>"
    toc_links = " ".join(
        f'<a href="#scenario-{html.escape(name)}">{html.escape(name.title())}</a>' for name in scenarios
    )

    generated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return f"""
<section class="overview">
  <div class="overview-header">
    <div>
      <h2>Run Overview</h2>
      <p class="muted">Generated {html.escape(generated_at)}.</p>
    </div>
    <nav class="toc">{toc_links}</nav>
  </div>
  <div class="overview-table">
    <table>
      <thead>
        <tr>
          <th>Scenario</th>
          <th>Frames</th>
          <th>FPS</th>
          <th>Resolution</th>
          <th>DX</th>
          <th>DY</th>
          <th>Rotation</th>
          <th>Scale</th>
          <th>Opacity</th>
          <th>Summary</th>
        </tr>
      </thead>
      <tbody>
        {table_rows}
      </tbody>
    </table>
  </div>
</section>
"""


def build_report(root: Path, scenarios):
    overview = render_overview(root, scenarios)
    sections = "\n".join(render_scenario(root, name) for name in scenarios)

    html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>MotionEyes Visual Analysis Report</title>
<style>
:root {{ color-scheme: light; }}
body {{ font-family: ui-sans-serif, system-ui; background: #f2f3f7; color: #1e1f24; margin: 0; padding: 24px; }}
header {{ margin-bottom: 24px; }}
h1 {{ margin: 0 0 8px; font-size: 30px; }}
h2 {{ margin: 0 0 12px; }}
h3 {{ margin: 0 0 10px; }}
.muted {{ color: #5a6270; font-size: 14px; }}
.badge {{ background: #eef1f7; padding: 4px 10px; border-radius: 999px; font-size: 12px; }}
.overview {{ background: #ffffff; padding: 20px; border-radius: 14px; margin-bottom: 24px; box-shadow: 0 6px 18px rgba(0,0,0,0.08); }}
.overview-header {{ display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 12px; }}
.toc a {{ margin-right: 12px; text-decoration: none; color: #1e1f24; font-weight: 600; }}
.overview-table {{ overflow-x: auto; margin-top: 12px; }}
table {{ border-collapse: collapse; width: 100%; }}
th, td {{ border: 1px solid #e1e3ea; padding: 8px 10px; text-align: left; font-size: 13px; }}
th {{ background: #f5f6fb; font-weight: 600; }}
.summary-cell {{ max-width: 320px; }}
.scenario {{ background: #ffffff; padding: 20px; border-radius: 14px; margin-bottom: 28px; box-shadow: 0 6px 18px rgba(0,0,0,0.08); }}
.scenario-header {{ display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 16px; }}
.meta {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; }}
.card {{ background: #f9f9fc; border-radius: 12px; padding: 14px; border: 1px solid #e5e7ef; }}
pre {{ background: #111318; color: #e3e6ee; padding: 12px; border-radius: 8px; overflow: auto; max-height: 320px; }}
.grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; }}
.grid img {{ width: 100%; border-radius: 8px; border: 1px solid #d2d4dc; background: #fff; }}
.keyframes img {{ border: 2px solid #3b82f6; }}
.subsection {{ margin-top: 18px; }}
details {{ margin-top: 12px; }}
summary {{ cursor: pointer; font-weight: 600; }}
.kv th {{ width: 140px; }}
.json-block pre {{ margin-top: 10px; }}
</style>
</head>
<body>
<header>
  <h1>MotionEyes Visual Analysis Report</h1>
  <p class="muted">Organized by scenario with key frames, metrics, and full galleries.</p>
</header>
{overview}
{sections}
</body>
</html>
"""

    (root / "index.html").write_text(html, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Build a master HTML report from scenario outputs.")
    parser.add_argument("--output", type=str, required=True, help="Root report directory.")
    parser.add_argument(
        "--scenarios",
        type=str,
        default="opacity,offset,geometry,scroll",
        help="Comma-separated scenario names.",
    )
    args = parser.parse_args()

    root = Path(args.output)
    scenarios = [s.strip() for s in args.scenarios.split(",") if s.strip()]
    build_report(root, scenarios)
    print(f"Wrote master report to {root / 'index.html'}")


if __name__ == "__main__":
    main()
