# Assignment1: GA on De Jong Functions

这个工程实现了一个可插拔算子版本的遗传算法（GA），用于优化两个经典测试函数（De Jong 1/2）。

如果你是第一次接手代码，建议阅读顺序：

1. `main.m`（入口与实验配置）
2. `genetic_algorithm.m`（主循环）
3. `arithmetic_crossover.m` / `sbx_crossover.m`（交叉算子）
4. `gaussian_mutation.m` / `polynomial_mutation.m`（变异算子）
5. `dejong1.m` / `dejong2.m`（目标函数）

## 1. 工程结构速览

- `main.m`
  作用：选择目标函数 + 选择算法组合 + 执行 30 次独立运行 + 统计与画图。

- `genetic_algorithm.m`
  作用：GA 主循环。通过函数句柄注入交叉和变异算子（`crossOp`、`mutOp`），不和具体算子耦合。

- `arithmetic_crossover.m`
  作用：基础算术交叉（whole arithmetic crossover）。

- `sbx_crossover.m`
  作用：SBX（Simulated Binary Crossover）交叉，含分布指数 `eta_c`。

- `gaussian_mutation.m`
  作用：高斯变异，扰动幅度固定为 `0.1`。

- `polynomial_mutation.m`
  作用：多项式变异（NSGA-II 常用形式），含分布指数 `eta_m`。

- `dejong1.m`
  作用：De Jong 1（Sphere）目标函数。

- `dejong2.m`
  作用：De Jong 2（Rosenbrock 形式）目标函数。

## 2. 调用关系（谁调用谁）

`main` -> `genetic_algorithm`

`genetic_algorithm` 在每代中调用：

- 目标函数：`dejong1` 或 `dejong2`
- 交叉算子：`arithmetic_crossover` 或 `sbx_crossover`
- 变异算子：`gaussian_mutation` 或 `polynomial_mutation`

核心重构点：

- 算法主干（选择/精英保留/迭代）固定在 `genetic_algorithm.m`
- 算子通过函数句柄从 `main.m` 注入
- 换算子不需要改 GA 主循环

## 3. 两种算法组合

在 `main(funcID, algoType)` 中：

- `algoType = 1`
  使用 Basic 组合：Arithmetic Crossover + Gaussian Mutation

- `algoType = 2`
  使用 Advanced 组合：SBX + Polynomial Mutation

默认：

- `funcID` 默认 1（De Jong 1）
- `algoType` 默认 2（Advanced）

## 4. 目标函数与取值范围

1. De Jong 1

$$f(x)=x_1^2+x_2^2$$

- 变量范围：$x_1,x_2\in[-5.12,5.12]$
- 全局最优：$(0,0)$，最优值为 $0$

2. De Jong 2

$$f(x)=100(x_1^2-x_2)^2+(1-x_1)^2$$

- 变量范围：$x_1,x_2\in[-2.048,2.048]$
- 全局最优：$(1,1)$，最优值为 $0$

## 5. 默认实验参数

来自 `main.m`：

- `numRuns = 30`
- `maxGen = 100`
- `popSize = 50`
- `pc = 0.8`
- `pm = 0.1`
- `eliteRate = 0.1`
- `eta_c = 10`（SBX 用）
- `eta_m = 10`（Polynomial mutation 用）

## 6. 快速运行

在 MATLAB 当前目录切到本工程后：

```matlab
% De Jong 1 + Basic
main(1, 1)

% De Jong 1 + Advanced
main(1, 2)

% De Jong 2 + Basic
main(2, 1)

% De Jong 2 + Advanced
main(2, 2)

% 默认：main(1,2)
main
```

## 7. 运行后会看到什么

控制台输出：

- 30 次独立运行最终最优值的均值（Mean）
- 30 次独立运行最终最优值的标准差（Std）

图像输出：

1. 单次进化曲线（第 5 次运行）
2. 第 1/10/50/100 代的箱线图（30 次运行分布）

## 8. 组内协作建议

- 想改算子：优先在对应算子文件修改，不要直接改 `genetic_algorithm.m` 主循环。
- 想加新算子：新增一个函数并保持参数风格与现有算子一致，然后在 `main.m` 增加分支注入。
- 想做对比实验：固定 `funcID`，只切换 `algoType`，保持其余参数不变。

---

如果后续要继续扩展（例如多维、更多 benchmark 函数、更多选择策略），当前“主循环 + 算子注入”的结构可以直接复用。
