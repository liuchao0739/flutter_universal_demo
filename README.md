# Flutter Super App Platform（超级应用平台）

## 功能与特性
- 🏗️ **模块化架构**：核心框架层 + 业务模块层 + 服务层
- 🛒 **电商模块**：商品展示、购物车、订单管理
- 💬 **IM 模块**：即时通讯、音视频通话
- 🎬 **视频模块**：短视频、直播、播放器
- 🔧 **工具模块**：WebView、扫码、分享、地图
- 💼 **行业扩展**：办公、生活服务、金融、教育
- 🎨 **主题切换**：深色/浅色模式 + 多语言支持
- 📱 **跨平台**：支持 iOS、Android、鸿蒙

## 项目结构
```
lib/
  main.dart                # 应用入口
  config/                  # 配置文件（主题、语言、环境变量）
  core/                    # 核心框架层（路由、状态、网络、存储、崩溃）
  modules/                 # 功能模块（mall/im/video/tools/industry/common/superapp）
  services/                # 业务服务层（导航、支付、分享、扫码等）
  ui/                      # 通用组件库
  bridge/                  # 原生桥接层
android/ ios/ ohos/        # 各端原生配置与权限
assets/images/             # 资源文件
```

## 快速开始
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run   # 选择目标设备 (iOS/Android/鸿蒙)
```

## 关键依赖
- 路由：auto_route
- 状态管理：flutter_riverpod
- 网络：dio
- 存储：hive / hive_flutter
- 权限：permission_handler
- 功能：amap_flutter_map, qr_code_scanner, share_plus, screenshot, carousel_slider

## 快速开始
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run   # 选择目标设备 (iOS/Android/鸿蒙)
```

## 关键依赖
- 路由：auto_route
- 状态管理：flutter_riverpod
- 网络：dio
- 存储：hive / hive_flutter
- 权限：permission_handler
- 功能：amap_flutter_map, qr_code_scanner, share_plus, screenshot, carousel_slider

## 项目架构
详见 `项目目录结构说明.md`，包含完整的模块化架构说明和开发规范。
