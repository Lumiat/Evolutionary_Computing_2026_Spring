"""Visualize the customized GA timetable and 30-run robustness results.

Usage examples:
    python visualize_timetable_custom.py
    python visualize_timetable_custom.py best_schedule.csv
    python visualize_timetable_custom.py ga_30run_results/selected_schedule.csv --results-dir ga_30run_results

Expected outputs:
    figures/weekly_timetable.png
    figures/weekly_timetable.pdf
    figures/ga_convergence_selected.png              # selected single-run curve
    figures/ga_convergence_30runs.png                # average / best / worst curves
    figures/ga_boxplot_final_penalty.png             # robustness boxplot
    figures/ga_final_penalty_by_run.png              # final penalty scatter/line by run

This script expects the CSV produced by ga_timetable_solver_custom.m. It keeps
backward compatibility with a single-run best_schedule.csv and ga_history.csv.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Dict, Iterable, Optional, Tuple

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import font_manager
from matplotlib.patches import Patch, Rectangle

DAYS_EN = ["Mon", "Tue", "Wed", "Thu", "Fri"]
DAYS_CN = ["星期一", "星期二", "星期三", "星期四", "星期五"]
DAY_TO_INDEX = {d: i for i, d in enumerate(DAYS_EN)}
DAY_TO_INDEX.update({d: i for i, d in enumerate(DAYS_CN)})

SECTION_TIMES = {
    1: ("第一节", "08:15-09:00"),
    2: ("第二节", "09:10-09:55"),
    3: ("第三节", "10:15-11:00"),
    4: ("第四节", "11:10-11:55"),
    5: ("第五节", "13:50-14:35"),
    6: ("第六节", "14:45-15:30"),
    7: ("第七节", "15:40-16:25"),
    8: ("第八节", "16:45-17:30"),
    9: ("第九节", "17:40-18:25"),
    10: ("第十节", "19:20-20:05"),
    11: ("第十一节", "20:15-21:00"),
    12: ("第十二节", "21:10-21:55"),
}

BIG_SECTION_GROUPS = [
    (1, 2, "第一\n大节"),
    (3, 4, "第二\n大节"),
    (5, 7, "第三\n大节"),
    (8, 9, "第四\n大节"),
    (10, 12, "第五\n大节"),
]

# Visual style close to the user's reference screenshot.
BG_MORNING = "#d9f7e5"
BG_AFTERNOON = "#f9ead9"
BG_EVENING = "#dbe8f8"
GRID_COLOR = "#d0d0d0"
HEADER_BG = "#f4f4f4"
LEFT_BG = "#eef7f2"

COURSE_COLORS: Dict[str, str] = {
    "系统结构": "#55a867",
    "微积分": "#e28f88",
    "编译原理": "#55bf8a",
    "系统结构课程设计": "#93a4d9",
    "编译原理课程设计": "#ff9568",
    "模式识别": "#9b6ba3",
    "进化计算": "#d9b300",
}

FALLBACK_COLORS = [
    "#55a867", "#e28f88", "#55bf8a", "#ff9568", "#9b6ba3",
    "#d9b300", "#6aaed6", "#c77c7c", "#8fc46b", "#b58ad7",
]


def setup_matplotlib_font() -> None:
    """Set common CJK-capable fonts.

    You may specify a font file path with the environment variable TIMETABLE_FONT,
    for example:
        TIMETABLE_FONT=/path/to/NotoSansCJK-Regular.ttc python visualize_timetable_custom.py
    """
    font_path = os.environ.get("TIMETABLE_FONT")
    if font_path and Path(font_path).exists():
        font_manager.fontManager.addfont(font_path)
        font_name = font_manager.FontProperties(fname=font_path).get_name()
        plt.rcParams["font.sans-serif"] = [font_name, "DejaVu Sans"]
    else:
        plt.rcParams["font.sans-serif"] = [
            "Microsoft YaHei",
            "SimHei",
            "Noto Sans CJK SC",
            "Source Han Sans SC",
            "WenQuanYi Micro Hei",
            "Arial Unicode MS",
            "DejaVu Sans",
        ]
    plt.rcParams["axes.unicode_minus"] = False


def main() -> None:
    setup_matplotlib_font()
    args = parse_args()

    results_dir = Path(args.results_dir)
    csv_path = resolve_schedule_path(args.schedule_csv, results_dir)
    if not csv_path.exists():
        raise FileNotFoundError(f"Cannot find schedule file: {csv_path}")

    out_dir = Path(args.output_dir)
    out_dir.mkdir(exist_ok=True)

    df = read_schedule(csv_path)
    plot_weekly_timetable(df, out_dir)

    selected_history = resolve_selected_history_path(csv_path, results_dir)
    if selected_history and selected_history.exists():
        plot_selected_convergence(selected_history, out_dir)

    history_path = resolve_multi_history_path(results_dir)
    summary_path = resolve_summary_path(results_dir)
    if history_path and history_path.exists():
        summary = read_csv_with_fallback(summary_path) if summary_path and summary_path.exists() else None
        plot_multi_run_convergence(history_path, summary, out_dir)
    if summary_path and summary_path.exists():
        summary = read_csv_with_fallback(summary_path)
        plot_robustness_boxplot(summary, out_dir)
        plot_final_penalty_by_run(summary, out_dir)
        print_summary(summary)

    print(f"Figures written to: {out_dir.resolve()}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Visualize GA timetable and 30-run robustness results.")
    parser.add_argument(
        "schedule_csv",
        nargs="?",
        default=None,
        help="Schedule CSV to visualize. Defaults to ga_30run_results/selected_schedule.csv if it exists, otherwise best_schedule.csv.",
    )
    parser.add_argument(
        "--results-dir",
        default="ga_30run_results",
        help="Folder containing summary.csv and all_runs_history.csv from the 30-run MATLAB experiment.",
    )
    parser.add_argument(
        "--output-dir",
        default="figures",
        help="Output folder for generated figures.",
    )
    return parser.parse_args()


def resolve_schedule_path(user_arg: Optional[str], results_dir: Path) -> Path:
    if user_arg:
        return Path(user_arg)
    selected = results_dir / "selected_schedule.csv"
    if selected.exists():
        return selected
    return Path("best_schedule.csv")


def resolve_selected_history_path(schedule_csv: Path, results_dir: Path) -> Optional[Path]:
    candidates = [
        schedule_csv.with_name("selected_history.csv"),
        results_dir / "selected_history.csv",
        schedule_csv.with_name("ga_history.csv"),
        Path("ga_history.csv"),
    ]
    for path in candidates:
        if path.exists():
            return path
    return None


def resolve_multi_history_path(results_dir: Path) -> Optional[Path]:
    candidates = [
        results_dir / "all_runs_history.csv",
        Path("ga_30run_history.csv"),
    ]
    for path in candidates:
        if path.exists():
            return path
    return None


def resolve_summary_path(results_dir: Path) -> Optional[Path]:
    candidates = [
        results_dir / "summary.csv",
        Path("ga_30run_summary.csv"),
    ]
    for path in candidates:
        if path.exists():
            return path
    return None


def read_csv_with_fallback(path: Path) -> pd.DataFrame:
    try:
        return pd.read_csv(path, encoding="utf-8-sig")
    except UnicodeDecodeError:
        return pd.read_csv(path, encoding="gbk")


def read_schedule(csv_path: Path) -> pd.DataFrame:
    df = read_csv_with_fallback(csv_path)

    required = {"CourseName", "Day", "StartSection", "DurationSections", "Professor", "Room"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"Schedule CSV is missing required columns: {sorted(missing)}")

    # Backward compatibility.
    if "DayCN" not in df.columns:
        df["DayCN"] = df["Day"].map({en: cn for en, cn in zip(DAYS_EN, DAYS_CN)}).fillna(df["Day"])
    if "CourseBase" not in df.columns:
        df["CourseBase"] = df["CourseName"].astype(str).str.replace(r"_(理论|实验)_\d+$", "", regex=True)
    if "CourseType" not in df.columns:
        df["CourseType"] = "课程"
    if "Campus" not in df.columns:
        if "CampusID" in df.columns:
            df["Campus"] = df["CampusID"].map({1: "望江校区", 2: "江安校区"}).fillna("校区")
        else:
            df["Campus"] = "校区"
    if "Building" not in df.columns:
        df["Building"] = "教学楼"
    if "Enrollment" not in df.columns:
        df["Enrollment"] = ""
    if "EndSection" not in df.columns:
        df["EndSection"] = df["StartSection"] + df["DurationSections"] - 1

    df["StartSection"] = df["StartSection"].astype(int)
    df["EndSection"] = df["EndSection"].astype(int)
    df["DurationSections"] = df["DurationSections"].astype(int)
    return df.sort_values(["Day", "StartSection", "Room"]).reset_index(drop=True)


def day_index(row: pd.Series) -> int:
    day = row.get("DayCN", row.get("Day"))
    if day in DAY_TO_INDEX:
        return DAY_TO_INDEX[day]
    day = row.get("Day")
    if day in DAY_TO_INDEX:
        return DAY_TO_INDEX[day]
    raise ValueError(f"Unknown day value: {day}")


def background_color(section: int) -> str:
    if section <= 4:
        return BG_MORNING
    if section <= 9:
        return BG_AFTERNOON
    return BG_EVENING


def course_color(course_base: str, idx: int) -> str:
    if course_base in COURSE_COLORS:
        return COURSE_COLORS[course_base]
    return FALLBACK_COLORS[idx % len(FALLBACK_COLORS)]


def plot_weekly_timetable(df: pd.DataFrame, out_dir: Path) -> None:
    fig, ax = plt.subplots(figsize=(18, 9.8))
    ax.set_xlim(-1.85, 5.0)
    ax.set_ylim(12.9, -0.85)
    ax.axis("off")

    # Header row.
    ax.add_patch(Rectangle((-1.85, -0.85), 1.85, 0.85, facecolor=HEADER_BG, edgecolor=GRID_COLOR, linewidth=1.0))
    ax.text(-1.55, -0.42, "节次", va="center", ha="center", fontsize=11, fontweight="bold", color="#555555")
    for i, day_cn in enumerate(DAYS_CN):
        ax.add_patch(Rectangle((i, -0.85), 1.0, 0.85, facecolor=HEADER_BG, edgecolor=GRID_COLOR, linewidth=1.0))
        ax.text(i + 0.5, -0.42, day_cn, va="center", ha="center", fontsize=11, fontweight="bold", color="#555555")

    # Left side big-section labels.
    for start, end, label in BIG_SECTION_GROUPS:
        y = start - 1
        height = end - start + 1
        ax.add_patch(Rectangle((-1.85, y), 0.42, height, facecolor=LEFT_BG, edgecolor=GRID_COLOR, linewidth=0.8))
        ax.text(-1.64, y + height / 2, label, va="center", ha="center", fontsize=10, fontweight="bold")

    # Section labels and day cell backgrounds.
    for section in range(1, 13):
        y = section - 1
        sec_name, sec_time = SECTION_TIMES[section]
        bg = background_color(section)

        ax.add_patch(Rectangle((-1.43, y), 1.43, 1.0, facecolor=bg, edgecolor=GRID_COLOR, linewidth=0.8))
        ax.text(-0.72, y + 0.5, f"{sec_name}\n{sec_time}", va="center", ha="center", fontsize=8.6, fontweight="bold")

        for day in range(5):
            ax.add_patch(Rectangle((day, y), 1.0, 1.0, facecolor=bg, edgecolor=GRID_COLOR, linewidth=0.8))

    # Course blocks.
    base_to_color: Dict[str, str] = {}
    for _, row in df.iterrows():
        d = day_index(row)
        y = int(row["StartSection"]) - 1
        h = int(row["DurationSections"])
        base = str(row.get("CourseBase", row["CourseName"]))
        if base not in base_to_color:
            base_to_color[base] = course_color(base, len(base_to_color))
        color = base_to_color[base]

        x = d + 0.015
        width = 0.97
        ax.add_patch(
            Rectangle(
                (x, y + 0.02),
                width,
                h - 0.04,
                facecolor=color,
                edgecolor="white",
                linewidth=1.2,
                alpha=0.96,
                zorder=3,
            )
        )

        label = build_course_label(row)
        ax.text(
            x + 0.025,
            y + 0.12,
            label,
            va="top",
            ha="left",
            fontsize=8.2 if h <= 2 else 8.7,
            color="white",
            fontweight="bold",
            linespacing=1.25,
            zorder=4,
            clip_on=True,
        )

    # Legend.
    handles = [Patch(facecolor=c, label=b) for b, c in base_to_color.items()]
    if handles:
        ax.legend(
            handles=handles,
            loc="upper center",
            bbox_to_anchor=(0.5, -0.045),
            ncol=min(4, len(handles)),
            frameon=False,
            fontsize=9,
        )

    ax.set_title("GA 自动排课结果：每周课程表", fontsize=16, fontweight="bold", pad=16)
    fig.tight_layout(rect=[0.01, 0.04, 0.99, 0.97])
    fig.savefig(out_dir / "weekly_timetable.png", dpi=240)
    fig.savefig(out_dir / "weekly_timetable.pdf")
    plt.close(fig)


def build_course_label(row: pd.Series) -> str:
    course = str(row["CourseName"])
    professor = str(row["Professor"])
    start_sec = int(row["StartSection"])
    end_sec = int(row["EndSection"])
    campus = str(row.get("Campus", ""))
    building = str(row.get("Building", ""))
    room = str(row.get("Room", ""))
    enrollment = row.get("Enrollment", "")

    try:
        enrollment_text = f"{int(enrollment)}人"
    except Exception:
        enrollment_text = ""

    location = f"{campus}{building}{room}"
    if len(location) > 18:
        location = f"{campus}-{room}"

    lines = [
        course,
        professor,
        f"第{start_sec}-{end_sec}节" + (f" | {enrollment_text}" if enrollment_text else ""),
        location,
    ]
    return "\n".join(lines)


def plot_selected_convergence(history_path: Path, out_dir: Path) -> None:
    history = read_csv_with_fallback(history_path)
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.plot(history["Generation"], history["BestPenalty"], label="Selected run best penalty")
    ax.plot(history["Generation"], history["MeanPenalty"], label="Selected run mean penalty")
    if "BestHardPenalty" in history.columns:
        ax.plot(history["Generation"], history["BestHardPenalty"], label="Selected run best hard penalty")
    ax.set_xlabel("Generation")
    ax.set_ylabel("Penalty")
    ax.set_title("GA 单次选中运行收敛曲线")
    ax.legend()
    ax.grid(linestyle="--", linewidth=0.5)
    fig.tight_layout()
    fig.savefig(out_dir / "ga_convergence_selected.png", dpi=220)
    plt.close(fig)


def build_padded_curve_matrix(history: pd.DataFrame, value_col: str = "BestPenalty") -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    if "Run" not in history.columns:
        raise ValueError("Multi-run history must contain a 'Run' column.")
    max_gen = int(history["Generation"].max())
    generations = np.arange(1, max_gen + 1)
    runs = np.array(sorted(history["Run"].unique()))
    curves = np.zeros((len(runs), max_gen), dtype=float)

    for row_idx, run in enumerate(runs):
        sub = history[history["Run"] == run].sort_values("Generation")
        series = sub.set_index("Generation")[value_col].reindex(generations)
        series = series.ffill().bfill()
        curves[row_idx, :] = series.to_numpy(dtype=float)
    return runs, generations, curves


def final_penalty_by_run_from_history(history: pd.DataFrame) -> pd.Series:
    final_rows = history.sort_values(["Run", "Generation"]).groupby("Run").tail(1)
    return final_rows.set_index("Run")["BestPenalty"]


def choose_best_and_worst_runs(history: pd.DataFrame, summary: Optional[pd.DataFrame]) -> Tuple[int, int]:
    if summary is not None and {"Run", "BestPenalty"}.issubset(summary.columns):
        final = summary.set_index("Run")["BestPenalty"]
    else:
        final = final_penalty_by_run_from_history(history)
    best_run = int(final.idxmin())
    worst_run = int(final.idxmax())
    return best_run, worst_run


def plot_multi_run_convergence(history_path: Path, summary: Optional[pd.DataFrame], out_dir: Path) -> None:
    history = read_csv_with_fallback(history_path)
    required = {"Run", "Generation", "BestPenalty"}
    missing = required - set(history.columns)
    if missing:
        raise ValueError(f"All-runs history is missing columns: {sorted(missing)}")

    runs, generations, curves = build_padded_curve_matrix(history, "BestPenalty")
    average_curve = curves.mean(axis=0)
    best_run, worst_run = choose_best_and_worst_runs(history, summary)

    run_to_row = {int(run): idx for idx, run in enumerate(runs)}
    best_curve = curves[run_to_row[best_run], :]
    worst_curve = curves[run_to_row[worst_run], :]

    fig, ax = plt.subplots(figsize=(10, 5.8))
    ax.plot(generations, average_curve, label="Average convergence over 30 runs", linewidth=2.2)
    ax.plot(generations, best_curve, label=f"Best run convergence (Run {best_run:02d})", linewidth=1.8)
    ax.plot(generations, worst_curve, label=f"Worst run convergence (Run {worst_run:02d})", linewidth=1.8)
    ax.set_xlabel("Generation")
    ax.set_ylabel("Best penalty")
    ax.set_title("GA 30 次独立运行收敛曲线对比")
    ax.legend()
    ax.grid(linestyle="--", linewidth=0.5)
    fig.tight_layout()
    fig.savefig(out_dir / "ga_convergence_30runs.png", dpi=240)
    plt.close(fig)


def plot_robustness_boxplot(summary: pd.DataFrame, out_dir: Path) -> None:
    required = {"BestPenalty", "HardPenalty", "SoftPenalty"}
    missing = required - set(summary.columns)
    if missing:
        raise ValueError(f"Summary is missing columns: {sorted(missing)}")

    data = [
        summary["BestPenalty"].to_numpy(dtype=float),
        summary["HardPenalty"].to_numpy(dtype=float),
        summary["SoftPenalty"].to_numpy(dtype=float),
    ]
    fig, ax = plt.subplots(figsize=(8.5, 5.6))
    ax.boxplot(data, labels=["Total penalty", "Hard penalty", "Soft penalty"], showmeans=True)
    ax.set_ylabel("Final penalty")
    ax.set_title("GA 30 次独立运行最终结果箱线图")
    ax.grid(axis="y", linestyle="--", linewidth=0.5)
    fig.tight_layout()
    fig.savefig(out_dir / "ga_boxplot_final_penalty.png", dpi=240)
    plt.close(fig)


def plot_final_penalty_by_run(summary: pd.DataFrame, out_dir: Path) -> None:
    if not {"Run", "BestPenalty"}.issubset(summary.columns):
        return
    fig, ax = plt.subplots(figsize=(10, 5.2))
    ax.plot(summary["Run"], summary["BestPenalty"], marker="o", label="Final best penalty")
    if "HardPenalty" in summary.columns:
        ax.plot(summary["Run"], summary["HardPenalty"], marker="s", label="Final hard penalty")
    ax.set_xlabel("Run")
    ax.set_ylabel("Penalty")
    ax.set_title("GA 30 次独立运行最终 penalty 分布")
    ax.set_xticks(summary["Run"].astype(int).tolist())
    ax.legend()
    ax.grid(linestyle="--", linewidth=0.5)
    fig.tight_layout()
    fig.savefig(out_dir / "ga_final_penalty_by_run.png", dpi=240)
    plt.close(fig)


def print_summary(summary: pd.DataFrame) -> None:
    if "BestPenalty" not in summary.columns:
        return
    feasible_text = ""
    if "Feasible" in summary.columns:
        feasible_count = int(summary["Feasible"].astype(bool).sum())
        feasible_text = f", feasible={feasible_count}/{len(summary)}"
    print(
        "30-run robustness summary: "
        f"mean={summary['BestPenalty'].mean():.2f}, "
        f"std={summary['BestPenalty'].std():.2f}, "
        f"min={summary['BestPenalty'].min():.2f}, "
        f"max={summary['BestPenalty'].max():.2f}"
        f"{feasible_text}"
    )


if __name__ == "__main__":
    main()
