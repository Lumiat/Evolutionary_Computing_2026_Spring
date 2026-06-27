# GA 自动排课：30 次独立运行与鲁棒性可视化版本

## 1. MATLAB 求解

将 `ga_timetable_solver_custom.m` 放在 MATLAB 当前工作目录，运行：

```matlab
ga_timetable_solver_custom
```

该版本会独立运行 GA 30 次。主要输出包括：

```text
best_schedule.csv                 # 30 次运行中最终 penalty 最低的那一次课表，用于直接可视化
ga_history.csv                    # 被选中运行的收敛历史
ga_30run_summary.csv              # 30 次运行的最终结果汇总
ga_30run_history.csv              # 30 次运行的逐代收敛历史
best_penalty_report.txt           # 被选中运行的惩罚项报告

ga_30run_results/
  summary.csv
  all_runs_history.csv
  selected_schedule.csv
  selected_history.csv
  selected_penalty_report.txt
  runs/run_01/...
  ...
  runs/run_30/...
```

其中 `SelectedForVisualization = true` 的运行会被复制为 `best_schedule.csv`，作为最终课表展示。

## 2. Python 可视化

安装依赖：

```bash
pip install pandas matplotlib numpy
```

运行：

```bash
python visualize_timetable_custom.py
```

默认会读取：

```text
ga_30run_results/selected_schedule.csv
```

如果该文件不存在，则回退读取：

```text
best_schedule.csv
```

生成图片：

```text
figures/weekly_timetable.png
figures/weekly_timetable.pdf
figures/ga_convergence_selected.png
figures/ga_convergence_30runs.png
figures/ga_boxplot_final_penalty.png
figures/ga_final_penalty_by_run.png
```

其中：

- `weekly_timetable.png`：某一次被选中运行生成的最终课程表；
- `ga_convergence_30runs.png`：30 次运行的平均收敛曲线、最好运行收敛曲线、最差运行收敛曲线；
- `ga_boxplot_final_penalty.png`：30 次运行最终结果的箱线图；
- `ga_final_penalty_by_run.png`：每一次运行最终 penalty 的分布。

如果中文字体显示为方框，可以指定字体：

```bash
TIMETABLE_FONT=/path/to/your/chinese_font.ttf python visualize_timetable_custom.py
```
