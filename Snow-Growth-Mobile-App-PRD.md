# Snow Growth 移动端 App 需求文档（PRD v1.0）
---

## 一、项目概述

| 项目 | 说明 |
|------|------|
| 应用名称 | Snow Growth |
| 应用类型 | 品牌门户 + 通用工具箱 |
| 核心定位 | Home 优先展示 Snow Growth 品牌与服务；Tools 提供 3 个高频通用工具 |
| 目标用户 | 需要日常计算的大众用户；Home 同时服务 Snow Growth 的券商/金融科技/资管受众 |
| 首期范围 | Home + Tools + 3 个工具（Percentage / Unit Converter / Tip）+ About |


## 二、信息架构与导航

底部三 Tab：**Home / Tools / About**（常驻）。

```
                       +-----------------+
                       |   App Launch    |
                       +--------+--------+
                                |
          +---------------------+---------------------+
          |                     |                     |
   +------v------+       +------+------+       +------v------+
   |  Home Tab   |<----->|  Tools Tab  |<----->| About Tab   |
   | Brand Info  | tabs  |  Tool List  | tabs  | Brand+Legal |
   +-------------+       +------+------+       +-------------+
                                |
                 +--------------+--------------+
                 |              |              |
                 v              v              v
          +-----------+  +-----------+  +-----------+
          |Percentage |  |   Unit    |  |   Tip     |
          |Calculator |  | Converter |  |Calculator |
          +-----------+  +-----------+  +-----------+
```

- **Home**：Snow Growth 品牌信息（Hero / Solutions / 案例 / CTA），顶部醒目「Tools」入口。
- **Tools**：3 个工具列表。
- **About**：品牌详情 + 合规免责 + 联系方式。
- 工具详情页顶部 `<` 返回 Tools。

## 三、页面线框图

### 3.1 Home（品牌优先）

```
+--------------------------------------+
| 9:41                [wifi] [bat 100%]|
+--------------------------------------+
| [Snow Growth]                    [=] |
+--------------------------------------+
|                                      |
|  Financial Marketing That            |
|  Builds Compounding Growth           |  <- Hero H1
|                                      |
|  We help brokers, fintech and        |  <- Subheading
|  asset managers acquire high-        |
|  intent customers.                   |
|                                      |
|  [ Request a Growth Audit        ]   |  <- Primary CTA
|                                      |
+--------------------------------------+
| TOOLS                       [ See >] |  <- 醒目工具入口
+--------------------------------------+
| +--------------------------------+   |
| | [%]  Percentage Calculator  >  |   |
| | [U]   Unit Converter        >  |   |
| | [$]  Tip Calculator         >  |   |
| +--------------------------------+   |
+--------------------------------------+
| SOLUTIONS                            |
| Snowball Acquisition Engine          |
| Institutional Authority              |
| Trading Engagement                   |
+--------------------------------------+
| FEATURED CASE                        |
| GCC Market Expansion                 |
| +45% active traders*                 |
| *campaign period, results vary       |
+--------------------------------------+
|  [Home]      [Tools]      [About]    |
+--------------------------------------+
```

**Home 需求说明**
- Hero 用官网 H1 与副标；主 CTA `Request a Growth Audit`。
- 「Tools」入口置于首屏可见区，搜索工具进来的用户 1 下直达。
- Solutions 三服务、Featured Case 带脚注（results vary）。

---

### 3.2 Tools（工具列表）

```
+--------------------------------------+
| 9:41                [wifi] [bat 100%]|
+--------------------------------------+
| Tools                                |
+--------------------------------------+
| [ Search tools...              [Q] ] |
+--------------------------------------+
| CALCULATORS                          |
| +--------------------------------+   |
| | [%]  Percentage Calculator   > |   |
| |      Percent of / change       |   |
| +--------------------------------+   |
| | [$]  Tip Calculator          > |   |
| |      Split the bill           |   |
| +--------------------------------+   |
| CONVERTERS                           |
| +--------------------------------+   |
| | [U]  Unit Converter          > |   |
| |      Length, weight, temp      |   |
| +--------------------------------+   |
+--------------------------------------+
|  [Home]      [Tools]      [About]    |
+--------------------------------------+
```

**Tools 需求说明**
- 顶部搜索框（结构预留，便于后续扩展）。
- 工具按 CALCULATORS / CONVERTERS 分组；卡片含图标、名称、一句话描述、右箭头。

---

### 3.3 Percentage Calculator（百分比计算器）

```
+--------------------------------------+
| 9:41                [wifi] [bat 100%]|
+--------------------------------------+
| [<]   Percentage Calculator     [...] |
+--------------------------------------+
|  Mode:                               |
|  ( What is X% of Y )                 |
|  ( X is what % of Y )                |
|  ( % Change from X to Y )            |
|                                      |
|  Value X                             |
|  [ 25 ]                              |
|                                      |
|  Value Y                             |
|  [ 200 ]                             |
|                                      |
+--------------------------------------+
| =================================== |
|  Result                              |
|  25% of 200 = 50                     |
| =================================== |
+--------------------------------------+
|  [Home]      [Tools]      [About]    |
+--------------------------------------+
```

**需求说明**：三种模式切换；输入即算。
- What is X% of Y → `(X/100) * Y`
- X is what % of Y → `(X/Y) * 100`
- % change → `((Y-X)/X) * 100`

---

### 3.4 Unit Converter（单位换算）

```
+--------------------------------------+
| 9:41                [wifi] [bat 100%]|
+--------------------------------------+
| [<]    Unit Converter           [...] |
+--------------------------------------+
|  Category                            |
|  ( Length )( Weight )( Temp )( More) |
|                                      |
|  From              To                |
|  [ 100   ]         [ ?   ]           |
|  [ Meter v ]       [ Feet v ]        |
|                                      |
+--------------------------------------+
| =================================== |
|  100 m = 328.08 ft                   |
| =================================== |
+--------------------------------------+
|  [Home]      [Tools]      [About]    |
+--------------------------------------+
```

**需求说明**
- 分类：Length / Weight / Temperature / Area / Volume / Speed / Data。
- From/To 单位可切换，数值双向输入（任一侧改都同步）。
- 温度用公式换算（C/F/K），其他用标准系数。

---

### 3.5 Tip Calculator（小费计算器）

```
+--------------------------------------+
| 9:41                [wifi] [bat 100%]|
+--------------------------------------+
| [<]    Tip Calculator           [...] |
+--------------------------------------+
|  Bill Amount                         |
|  [ $ 85.00                ]          |
|                                      |
|  Tip %                               |
|  [=====O========] 15%                |
|                                      |
|  Split between                       |
|  [ - ] 4 [ + ]                       |
|                                      |
+--------------------------------------+
| =================================== |
|  Tip           $ 12.75               |
|  Total         $ 97.75               |
|  Per person    $ 24.44               |
| =================================== |
+--------------------------------------+
|  [Home]      [Tools]      [About]    |
+--------------------------------------+
```

**需求说明**
- 输入：账单金额、小费比例（滑块，常 0–30%）、分摊人数。
- 输出：小费额、总额、人均。
- 滑块与数字双向联动。

---

### 3.6 About（品牌 + 合规）

```
+--------------------------------------+
| 9:41                [wifi] [bat 100%]|
+--------------------------------------+
| About                                |
+--------------------------------------+
|        Snow Growth                   |
|                                      |
|  A specialized financial growth      |
|  agency for brokers, fintech         |
|  companies and asset managers.       |
|                                      |
+--------------------------------------+
| SOLUTIONS                            |
| Snowball Acquisition Engine          |
| Institutional Authority              |
| Trading Engagement                   |
+--------------------------------------+
| CONTACT                              |
| [ Request a Growth Audit        ]    |
| support@snowgrowth.com               |
+--------------------------------------+
| LEGAL                                |
| Utility tools for reference only.    |
| Not financial, investment or         |
| marketing advice.                    |
|                                      |
| [ Privacy ] [ Terms ] [ Risk ]       |
| (c) 2026 Snow Growth                 |
+--------------------------------------+
|  [Home]      [Tools]      [About]    |
+--------------------------------------+
```

**About 需求说明**
- 品牌一句话定位 + 三服务 + 联系方式 + `Request a Growth Audit`。
- 合规免责 + Privacy / Terms / Risk Disclosure 入口。

## 四、功能需求清单

| 编号 | 功能 | 说明 |
|------|------|------|
| M-01 | 底部 Tab 导航 | Home / Tools / About 常驻 |
| M-02 | 主题切换 | 浅 / 深（跟随系统） |
| M-03 | Percentage Calculator | 三模式，实时计算 |
| M-04 | Unit Converter | 多分类，双向输入 |
| M-05 | Tip Calculator | 滑块 + 分摊，实时计算 |
| M-06 | 工具搜索 | Tools 页过滤（预留扩展） |
| M-07 | 数据本地暂存 | 记忆上次输入 |
| M-08 | About 页 | 品牌 + 联系 + 合规 |
| M-09 | 隐私政策 / 条款页 | 商店必需 |
