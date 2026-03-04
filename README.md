# InsuranceCommissionPal

保险佣金宝 - 提供中国大陆保险公司主流保险产品的佣金查询

## 功能特点

- 支持多家保险公司选择（中国人寿、平安保险、太平洋保险、友邦保险、太平人寿、新华保险）
- 根据选择的保险公司动态显示对应的保险产品
- 快速计算税前首年佣金
- 简洁直观的单页应用设计

## 技术栈

- **UI框架**: SwiftUI
- **编程语言**: Swift 5.0
- **最低iOS版本**: iOS 15.0+
- **目标iOS版本**: iOS 26.0+

## 快速开始

### 环境要求

- Xcode 15.0+
- iOS Simulator 或真机

### 克隆项目

```bash
git clone https://github.com/duetg/InsuranceCommissionPal.git
cd InsuranceCommissionPal
```

### 运行项目

1. 在 Xcode 中打开 `InsuranceCommissionPal.xcodeproj`
2. 选择目标设备或模拟器
3. 按 `Cmd + R` 运行

## 使用说明

1. **选择保险公司** - 从下拉列表中选择保险公司
2. **选择保险产品** - 根据所选公司显示对应的产品列表
3. **输入首年保费** - 输入保费金额
4. **计算佣金** - 点击按钮获取税前首年佣金

## 项目结构

```
InsuranceCommissionPal/
├── Sources/
│   └── InsuranceCommissionPalApp.swift    # 主应用入口
├── Resources/
│   └── Info.plist                          # 应用配置
├── project.yml                             # XcodeGen配置
└── SPEC.md                                 # 需求规范文档
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
