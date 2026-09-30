# 田径通用工具（Flutter / Android）

一款极简的田径训练工具，包含两个核心模块：

1. **跑圈计时**：开始 / 暂停 / 休息计时 / 计圈 / 结束，自动生成并保存完整训练记录。
2. **中距离比赛配速模拟器**：800m、1500m、3000m、5000m、10000m 目标完赛时间自动拆分分段用时与配速。

界面为高对比度配色、大字号、大按钮，适合户外阳光下查看。

## 一、在 GitHub 上自动生成 APK（推荐，无需本地环境）

项目已内置 GitHub Actions 工作流：`.github/workflows/build-apk.yml`。
Flutter 版本与依赖均已固定（Flutter 3.24.3 + shared_preferences 2.2.3），保证云端构建稳定可复现。

使用步骤：

1. 在 GitHub 新建一个仓库（公开或私有都可以）；
2. 把本项目**全部文件**上传/推送到仓库（注意 `.github` 目录要一起上传，它是隐藏目录）；
3. 打开仓库的 **Actions** 页面，工作流 `Build APK` 会自动开始运行；
   也可以手动触发：Actions → Build APK → Run workflow；
4. 等 3～6 分钟，构建成功后在该次运行页面底部 **Artifacts** 区域下载
   `track-field-toolkit-apk`，解压即可得到 `app-release.apk`；
5. 如果想要自动发布版本：给仓库打一个 `v1.0.0` 这样的标签（tag）再推送，
   APK 会自动挂到 Releases 里，可直接下载安装。

命令行推送示例：

```bash
git init
git add .
git commit -m "feat: 田径通用工具 Flutter 版"
git branch -M main
git remote add origin https://github.com/你的用户名/你的仓库名.git
git push -u origin main
```

> 说明：GitHub 会自动处理 Flutter SDK、Android SDK、Gradle 的下载，你只需要联网即可，
> 不需要在本机安装 Android Studio。

## 二、本地构建（可选）

```bash
flutter pub get
chmod +x android/gradlew   # Windows 可跳过
flutter build apk --release
```

产物路径：`build/app/outputs/flutter-apk/app-release.apk`。

也可以使用其他在线构建服务：Codemagic、AppCircle、Bitrise 等，
构建命令统一为 `flutter build apk --release`。

## 三、目录结构

```
track_field_toolkit_flutter/
├── .github/workflows/build-apk.yml   # GitHub Actions 自动打 APK
├── pubspec.yaml
├── analysis_options.yaml
├── android/                          # Android 壳工程（已写好，无需 flutter create）
├── lib/
│   ├── main.dart
│   ├── models/training_record.dart   # 训练记录数据模型
│   ├── services/training_repository.dart
│   ├── theme/app_theme.dart
│   ├── utils/time_format.dart
│   ├── utils/pace_plan.dart          # 配速拆分算法
│   ├── widgets/app_widgets.dart
│   └── screens/
│       ├── home_screen.dart
│       ├── timer_screen.dart
│       ├── pace_screen.dart
│       ├── history_screen.dart
│       └── record_detail_screen.dart
└── test/widget_test.dart
```

## 四、模块一：跑圈计时

- **单圈距离**：默认 400 米，可自由输入，另有 200 / 400 / 800 / 1000 米快捷选择。
- **计时面板**：精确到 0.01 秒，基于 `Stopwatch` 单调时钟，暂停/休息不计入跑步时长。
- **开始 / 暂停**：可反复暂停继续。
- **休息计时**：点击后自动暂停跑步并独立累计休息时间；再次点击结束休息，
  如果休息前正在跑则自动继续；支持一场训练多次插入休息。
- **计圈**：记录当前这一圈用时（只含跑步时间，不含休息）。
- **结束**：自动补全最后一圈，保存记录并清空面板。

记录内容：总时长、跑步净时长、休息总时长、每圈用时与配速、单圈距离、总圈数、总距离。
记录用 `shared_preferences` 保存在手机本地，在首页进入「历史训练记录」可查看详情、单条删除或清空。

## 五、模块二：中距离比赛配速模拟器

分段规则：

| 项目 | 分段 |
| --- | --- |
| 800m | 2 × 400m，可切换为 4 × 200m |
| 1500m | 3 × 400m + 最后 300m |
| 3000m | 7 × 400m + 最后 200m |
| 5000m | 12 × 400m + 最后 200m |
| 10000m | 24 × 400m + 最后 400m |

输入目标完赛时间（支持 `mm:ss`、`h:mm:ss`，如 `2:00`、`16:30`、`1:05:00`），
选择跑法风格（激进型 / 平均型 / 稳妥型），自动生成分段表：段次、距离、本段用时、累计用时、配速/km。

拆分算法：按跑法给每段分配速度系数（激进型前快后略慢、稳妥型前保守后加速、平均型恒定），
以「距离 ÷ 速度系数」为权重，把目标总时间等比分配到各分段，保证各段之和等于目标完赛时间。
