# PlatEMO 实验脚本说明

本项目提供两套 MATLAB 实验脚本，分别用于 $M=3$ 和 $M=5$ 的多目标优化实验：

- [run_platemo_experiments_m3.m](run_platemo_experiments_m3.m)：运行 $M=3$ 的实验。
- [summarize_platemo_results_m3.m](summarize_platemo_results_m3.m)：汇总 $M=3$ 的结果。
- [run_platemo_experiments_m5.m](run_platemo_experiments_m5.m)：运行 $M=5$ 的实验。
- [summarize_platemo_results_m5.m](summarize_platemo_results_m5.m)：汇总 $M=5$ 的结果。

这两套脚本都基于 PlatEMO，需要先把 PlatEMO 主目录加入 MATLAB 路径。

## 运行前准备

1. 安装 PlatEMO，并确认 MATLAB 能找到 `platemo.m`。
2. 将 PlatEMO 加入路径，例如：

```matlab
addpath(genpath('D:\path\to\PlatEMO'))
```

3. 打开本项目目录，确保脚本和输出目录都在当前工程中。

## 如何在 MATLAB 中运行

### 运行 $M=3$ 实验

在 MATLAB 命令行执行：

```matlab
run_platemo_experiments_m3
summarize_platemo_results_m3
```

### 运行 $M=5$ 实验

在 MATLAB 命令行执行：

```matlab
run_platemo_experiments_m5
summarize_platemo_results_m5
```

建议先运行对应的 `run_...` 脚本，再运行对应的 `summarize_...` 脚本。后者会读取前者生成的 `.mat` 文件并输出 CSV 和图像。

## 脚本会生成什么结果

### `run_platemo_experiments_*.m`

该脚本会对每个算法、每个问题、每次重复运行生成一个 `.mat` 文件，文件保存在 PlatEMO 的 `Data/` 目录下。文件名中包含：

- 算法名
- 问题名
- 目标数 $M$
- 决策变量维度 $D$
- 运行编号 `run`

### `summarize_platemo_results_*.m`

该脚本会从 `Data/` 读取 `.mat` 文件，提取最终 `IGD`、`HV` 和运行时间，并输出：

- 原始每次运行的明细 CSV
- 按算法与问题汇总的 CSV
- 收敛曲线图
- 代表性最终解集图
- 平均运行时间对比图

## 结果目录树

脚本运行后，项目中的结果结构大致如下：

```text
assignment2/
├── run_platemo_experiments_m3.m
├── summarize_platemo_results_m3.m
├── run_platemo_experiments_m5.m
├── summarize_platemo_results_m5.m
├── README.md
├── results_m3/
│   ├── raw_metrics_M3.csv
│   ├── summary_metrics_M3.csv
│   ├── Front_MedianIGD_<Algorithm>_<Problem>_M3.png
│   ├── Front_BestIGD_<Algorithm>_<Problem>_M3.png
│   ├── Convergence_IGD_<Problem>_M3.png
│   ├── Convergence_HV_<Problem>_M3.png
│   └── Runtime_<Problem>_M3.png
├── results_m5/
│   ├── raw_metrics_M5.csv
│   ├── summary_metrics_M5.csv
│   ├── Parallel_MedianIGD_<Algorithm>_<Problem>_M5.png
│   ├── Parallel_BestIGD_<Algorithm>_<Problem>_M5.png
│   ├── Convergence_IGD_<Problem>_M5.png
│   ├── Convergence_HV_<Problem>_M5.png
│   └── Runtime_<Problem>_M5.png
└── PlatEMO/
    └── Data/
        └── <Algorithm>/
            └── <Algorithm>_<Problem>_M<M>_D<D>_<run>.mat
```

说明：

- `results_m3/` 保存 $M=3$ 的汇总结果。
- `results_m5/` 保存 $M=5$ 的汇总结果。
- `Front_...` 图用于 $M=3$ 的三维散点图展示。
- `Parallel_...` 图用于 $M=5$ 的平行坐标图展示。

## 当前脚本使用的算法和问题

### $M=3$

- 算法：NSGAIII、MOEAD、RVEA、SPEA2、SMSEMOA
- 问题：DTLZ1、DTLZ2、DTLZ3、DTLZ4、DTLZ7、WFG4

### $M=5$

- 算法：NSGAIII、MOEAD、RVEA、SPEA2、SMSEMOA
- 问题：DTLZ1、DTLZ2、DTLZ3、DTLZ4、DTLZ7、WFG4

两套脚本都对每个算法-问题组合重复运行 30 次，并记录 `IGD`、`HV` 和运行时间。

## 如果只想跑部分算法或部分问题，要改哪里

如果你只想完成部分算法或者部分问题的求解，直接修改对应脚本顶部的配置数组即可，主要改这几处：

### 1. 选择要跑的算法

在 [run_platemo_experiments_m3.m](run_platemo_experiments_m3.m) 和 [run_platemo_experiments_m5.m](run_platemo_experiments_m5.m) 中，找到这一行：

```matlab
algorithms = {@NSGAIII, @MOEAD, @RVEA, @SPEA2, @SMSEMOA};
```

把不需要的算法从这个数组里删掉即可。比如只跑前两个算法：

```matlab
algorithms = {@NSGAIII, @MOEAD};
```

### 2. 选择要跑的问题

找到这一行：

```matlab
problems = {@DTLZ1, @DTLZ2, @DTLZ3, @DTLZ4, @DTLZ7, @WFG4};
```

删除不需要的问题即可。例如只跑 DTLZ1 和 WFG4：

```matlab
problems = {@DTLZ1, @WFG4};
```

### 3. 同步修改问题维度

问题数组下面有一个对应的维度数组：

```matlab
problemD = [...];
```

这个数组必须和 `problems` 一一对应。比如只保留两个问题时，`problemD` 也要只保留两个值。

### 4. 如果想改重复次数或保存检查点

你还可以修改：

- `numRuns`：重复实验次数
- `numSaved`：保存收敛曲线检查点数量
- `M`：目标个数
- `N`：种群规模
- `generations` 或 `maxFEs`：每个问题的评估上限

### 5. 汇总脚本也要保持一致

如果你改了 `run_...` 脚本里的算法、问题或 $M$，对应的 `summarize_...` 脚本也要同步改相同的数组和参数，否则它会去 `Data/` 目录里找不存在的 `.mat` 文件。

## 参数说明

### M=3 脚本

- 目标数：`M = 3`
- 种群规模：`N = 91`
- 重复次数：`numRuns = 30`
- 保存检查点：`numSaved = 50`
- 指标：`IGD`、`HV`

### M=5 脚本

- 目标数：`M = 5`
- 种群规模：`N = 210`
- 重复次数：`numRuns = 30`
- 保存检查点：`numSaved = 50`
- 指标：`IGD`、`HV`

## 注意事项

- 脚本运行前必须保证 PlatEMO 已加入 MATLAB 路径，否则会报找不到 `platemo.m`。
- `summarize_platemo_results_m3.m` 的输出目录是 `results_m3/`，`summarize_platemo_results_m5.m` 的输出目录是 `results_m5/`。
- 如果你改动了算法列表、问题列表或 $M$，请同步检查输出目录和文件命名是否仍然匹配。
