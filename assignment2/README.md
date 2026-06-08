# PlatEMO 实验脚本说明

本项目包含两个 MATLAB 脚本，用于批量运行 PlatEMO 实验并汇总结果：

- [run_platemo_experiments.m](run_platemo_experiments.m)：批量运行算法与测试问题，生成每次运行的 `.mat` 结果文件。
- [summarize_platemo_results.m](summarize_platemo_results.m)：读取 `.mat` 文件，汇总统计指标并导出 CSV 和图像。

## 运行前准备

1. 已安装 PlatEMO，并且 MATLAB 可以找到 `platemo.m`。
2. 将 PlatEMO 的主目录加入 MATLAB 路径，例如：

```matlab
addpath(genpath('D:\path\to\PlatEMO'))
```

3. 当前工程目录中包含这两个脚本，并保留 `results/` 目录用于保存汇总结果。

## 使用方法

### 1. 运行实验

在 MATLAB 中执行：

```matlab
run_platemo_experiments
```

该脚本会：

- 依次运行 5 个算法：NSGAIII、MOEAD、RVEA、SPEA2、NSGAII。
- 依次运行 2 个问题：DTLZ7 和 WFG4。
- 每个算法-问题组合重复 30 次。
- 保存每次运行的中间收敛信息与最终结果到 PlatEMO 的 `Data` 目录。

### 2. 汇总结果

在完成所有实验后，执行：

```matlab
summarize_platemo_results
```

该脚本会：

- 从 PlatEMO 的 `Data` 目录读取每次运行生成的 `.mat` 文件。
- 提取最终 `IGD`、`HV` 和运行时间。
- 生成汇总表、原始明细表，以及若干对比图。
- 将结果写入本项目的 `results/` 目录。

## 脚本输出说明

### `run_platemo_experiments.m` 的输出

每次运行会生成一个 `.mat` 文件，文件名中包含算法名、问题名、目标数、决策变量维度和运行编号。

### `summarize_platemo_results.m` 的输出

会生成以下文件：

- `results/raw_metrics.csv`：每次运行的原始指标明细。
- `results/summary_metrics.csv`：按算法与问题汇总后的均值和标准差。
- `results/Front_*.png`：代表性最终种群三维散点图。
- `results/Convergence_IGD_*.png`：IGD 收敛曲线。
- `results/Convergence_HV_*.png`：HV 收敛曲线。
- `results/Runtime_*.png`：平均运行时间对比图。

## 结果目录树

下面是脚本运行完成后，项目中结果文件的大致结构：

```text
assignment2/
├── run_platemo_experiments.m
├── summarize_platemo_results.m
├── README.md
├── results/
│   ├── raw_metrics.csv
│   ├── summary_metrics.csv
│   ├── Front_MedianIGD_<Algorithm>_<Problem>.png
│   ├── Front_BestIGD_<Algorithm>_<Problem>.png
│   ├── Convergence_IGD_<Problem>.png
│   ├── Convergence_HV_<Problem>.png
│   └── Runtime_<Problem>.png
└── PlatEMO/
    └── Data/
        └── <Algorithm>/
            └── <Algorithm>_<Problem>_M3_D<d>_<run>.mat
```

其中：

- `<Algorithm>` 可能是 `NSGAIII`、`MOEAD`、`RVEA`、`SPEA2`、`NSGAII`。
- `<Problem>` 可能是 `DTLZ7` 或 `WFG4`。
- `<d>` 表示该问题对应的决策变量维度。
- `<run>` 表示第几次重复实验。

## 参数说明

这两个脚本里的实验配置已经写死，便于统一复现实验：

- 目标数 `M = 3`
- 种群规模 `N = 91`
- 最大函数评估次数 `maxFE = 10010`
- 重复次数 `numRuns = 30`
- 保存检查点数 `numSaved = 50`
- 指标：`IGD`、`HV`

如果你需要改成别的实验设置，可以直接修改脚本顶部的参数。

## 注意事项

- `run_platemo_experiments.m` 会先检查 MATLAB 是否能找到 `platemo.m`，找不到就会报错。
- `summarize_platemo_results.m` 里的输出目录目前是写死的，如果你把项目移动到别的路径，需要同步修改 `outDir`。
- 建议先运行实验脚本，再运行汇总脚本，否则汇总时会提示缺少 `.mat` 文件。
