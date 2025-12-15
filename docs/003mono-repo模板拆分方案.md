---

## 推荐 mono-repo 结构

```
flutter-enterprise-template/
│
├── apps/
│   └── demo_app/                  # 可运行 Demo App
│       └── lib/
│
├── packages/
│   ├── core/
│   │   ├── config/                # Theme / Language / Env
│   │   ├── router/
│   │   └── app_shell.dart
│   │
│   ├── services/
│   │   ├── api/
│   │   ├── crash/
│   │   ├── analytics/
│   │   ├── storage/
│   │   └── payment/
│   │
│   ├── features/
│   │   ├── auth/
│   │   ├── map/
│   │   ├── scan/
│   │   ├── share/
│   │   └── settings/
│   │
│   └── widgets/
│       └── common_ui/
│
├── scripts/
│   └── generate_demo.sh
│
└── docs/
    ├── ARCHITECTURE.md
    ├── DEVELOPMENT_GUIDE.md
    └── MODULE_GUIDE.md
```

---

## mono-repo 拆分原则（非常重要）

### 1️⃣ apps 层

* 只负责 **组装**
* 不写业务逻辑
* 像“外壳”

### 2️⃣ packages 层

* 所有可复用能力
* 可以被多个 App 使用
* 可单独发包（私有 pub）

### 3️⃣ features ≠ services

* feature：业务模块（UI + 状态）
* service：底层能力（SDK / 数据）

---