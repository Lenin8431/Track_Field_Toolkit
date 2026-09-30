# 田径通用工具（Flutter / Android）

一款极简的田径训练工具，包含两个核心模块：

1. **跑圈计时**：开始 / 暂停 / 休息计时 / 计圈 / 结束，自动生成并保存完整训练记录。
2. **中距离比赛配速模拟器**：800m、1500m、3000m、5000m、10000m 目标完赛时间自动拆分分段用时与配速。

界面为高对比度配色、大字号、大按钮，适合户外阳光下查看。

## 一、在 GitHub 上自动生成 APK（推荐，无需本地环境）

项目已内置 GitHub Actions 工作流：`.github/workflows/build-apk.yml`。
Flutter 版本已固定（3.24.3），且**应用运行时不依赖任何第三方插件**（本地存储用 `dart:io` 直接写 JSON 文件），
避免 Android 插件与 compileSdk / AGP 版本冲突，保证云端构建稳定可复现。

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

- **跑道长度**：仅支持 200m / 300m / 400m 三种。
- **计划圈数**：支持小数。以 400m 跑道为例，800m 输入 2 圈，1500m 输入 3.75 圈；
  也可以直接点 800 / 1500 / 3000 / 5000 / 10000m 快捷按钮，自动换算圈数。
- **计时面板**：精确到 0.01 秒，基于 `Stopwatch` 单调时钟，暂停/休息不计入跑步时长。
- **开始 / 暂停**：可反复暂停继续。
- **休息计时**：点击后自动暂停跑步并独立累计休息时间；再次点击结束休息，
  如果休息前正在跑则自动继续；支持一场训练多次插入休息。
- **计圈**：记录当前这一段的用时（只含跑步时间，不含休息），
  **计时中和暂停状态都可以计圈**。
- **结束**：只补全“计划内还没记录完”的分段，不会凭空多出一圈。

分段命名规则：整圈显示为「第N圈」，最后不足一圈的部分显示为「最后Xm」。
例如 400m 跑道跑 1500m（3.75 圈），分段为
**第1圈、第2圈、第3圈、最后300m** 共 4 段，每段一个用时，最下面一行是合计总时间。

记录内容：总时长、跑步净时长、休息总时长、跑道长度、计划圈数、每一段用时与配速、总距离。
记录以 JSON 文件（`training_records_v1.json`）保存在应用私有目录
（`/data/user/0/com.track.toolkit/files/`），卸载应用时随数据一起清除；
在首页进入「历史训练记录」可查看详情、单条删除或清空。

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

## 六、应用名、桌面图标与版本号

- **应用名（桌面图标下方的文字）**：定义在 `android/app/src/main/res/values/strings.xml` 的 `app_name`，
  AndroidManifest 里 `<application>` 与 `<activity>` 都引用 `@string/app_name`。
  之前应用名只硬编码写在 AndroidManifest 中，一旦被 `flutter create` 之类的步骤覆盖或未被 ROM 识别，
  桌面就会显示空白名字，现已改为标准做法。
- **桌面图标**：`mipmap-anydpi-v26/ic_launcher.xml`（Android 8.0+ 自适应图标）
  + `mipmap-anydpi/ic_launcher.xml`（低版本回退矢量图标），图案为蓝色底 + 白色秒表。
- **版本号**：`android/app/build.gradle` 会在 pubspec 版本号后追加 beta 标记，
  当前对外版本为 `1.0.0（beta）`，versionCode = 2；首页底部也会显示该版本号。

改了 `applicationId` 时，记得同步修改 `lib/services/training_repository.dart` 里的存储路径常量。

> 提示：如果重新安装后桌面名字仍为空，请先卸载旧版本再安装新 APK——
> 大部分桌面（Launcher）会缓存同一包名的图标与名称。

## 七、本地验证结果

本项目已在本地用 Flutter 3.24.3 实际验证过：

```
flutter analyze   ->  No issues found!
flutter test      ->  All tests passed!（12 个测试）
```

并用 Android SDK 的 aapt2 校验过资源与清单：

```
aapt2 dump badging -> application-label:'田径通用工具'
                      application-icon: res/mipmap-anydpi-v26/ic_launcher.xml
```
