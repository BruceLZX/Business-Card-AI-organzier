<div align="center">

<img src="BusinessCardAIAssisstant/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" height="120" alt="BusinessCardAIAssistant Logo" />

# BusinessCardAIAssistant
### 一次拍照，永久结构化。联系人 ↔ 公司始终关联。

**面向高频社交/商务人士的 AI 名片中枢。**  
把名片与宣传页变成**“活的档案”**：联系人、公司、链接、标签，以及保持关联的 AI 补全摘要。

[English](README.md) · [产品需求（中文）](Product%20Requirement.md) · [Product Requirements (EN)](Product%20Requirement.en.md) · [License](LICENSE)

<br/>

<img alt="Stars" src="https://img.shields.io/github/stars/BruceLZX/Business-Card-AI-organzier?style=social">
<img alt="Forks" src="https://img.shields.io/github/forks/BruceLZX/Business-Card-AI-organzier?style=social">
<br/>
<img alt="Last Commit" src="https://img.shields.io/github/last-commit/BruceLZX/Business-Card-AI-organzier">
<img alt="Issues" src="https://img.shields.io/github/issues/BruceLZX/Business-Card-AI-organzier">
<img alt="License" src="https://img.shields.io/github/license/BruceLZX/Business-Card-AI-organzier">
<img alt="Swift" src="https://img.shields.io/badge/Swift-SwiftUI-orange">
<img alt="Platform" src="https://img.shields.io/badge/Platform-iOS-lightgrey">

<br/><br/>

> 如果你相册里塞满了名片照片，但通讯录/CRM 还是空的，这个就是为你做的。

<!-- 可选：之后加一个 demo gif（强烈推荐） -->
<!-- <img src="assets/demo.gif" width="820" alt="Demo" /> -->

</div>

---

## 为什么要做这个
名片很容易**收集**，但很难**使用**：
- 相册越堆越多 → 零结构 → 零跟进
- 传统 CRM 太重 → 摩擦太大 → 直接弃用

**BusinessCardAIAssistant** 介于两者之间：
- 像相机一样轻量
- 像 CRM 一样结构化
- 像真实人脉一样可关联

---

## 它哪里不一样

### ✅ 活档案，不是静态扫描
联系人与公司是**一等公民的文档**，且持续关联：
- 人 ↔ 公司始终连接
- 相关实体之间快速跳转
- 为规模化设计：目录 + 筛选 + 字母索引

### ✅ 先视觉解析，失败再 OCR
支持多张照片采集（正反面/多角度/宣传页）：
- 优先视觉解析
- 失败时 OCR 兜底，提升鲁棒性

### ✅ AI 补全可追责（杜绝“黑盒改动”）
每个变更都透明可见：
- 字段级高亮
- 原值与新值并排展示
- **每个字段一键撤销**

### ✅ 语言显示策略（EN/中文）
按系统语言显示最合适的名称；当语言不一致时，用原名作为上下文补充。

---

## 功能亮点

**核心功能**
- 单文档多图采集（名片 + 宣传页/资料）
- 创建/编辑联系人与公司档案
- 联系人 ↔ 公司交叉关联（仅选择已有项）
- 备注 + 标签 + 可点击链接
- 目录：搜索 + 筛选 + A–Z 字母索引

**为效率而设计**
- 详情页模块化编辑（一次只改一个模块）
- 关联列表固定高度可滚动，快速关联/解除关联
- 删除/解除等破坏性操作均需确认

**为信任而设计**
- 仅高亮“本次补全”发生变化的字段
- 字段级撤销，而不是“整次回滚”
- 不确定信息明确标注

---

## 工作方式（快速了解）
1) 拍摄名片/宣传页/二维码
2) AI 结构化解析（视觉优先，OCR 兜底）
3) AI 补全与合并去重
4) 你决定是否保留（字段级撤销）

---

## 文档（权威规格）
本项目以 PRD 作为“行为单一真相源”（source of truth）：
- **中文：**[Product Requirement.md](Product%20Requirement.md)
- **EN：**[Product Requirement.en.md](Product%20Requirement.en.md)

---

## 路线图
- [ ] App 内存占用展示
- [ ] 用户自管 API Key / 分阶段模型配置 + 校验
- [ ] 文档分享：导入确认 + 重复/冲突处理
- [ ] 单文档 PDF 导出
- [ ] 付费分发（无 IAP 流程）

---

## 参与贡献
欢迎提交 PR 与 Issue。

推荐贡献方向：
- UI 细节与 SwiftUI 组件打磨（详情页模块、导航体验）
- 解析鲁棒性（多图/边缘输入）
- 补全可靠性（合并去重质量、不确定性标注）
- 本地存储与搜索性能（索引、过滤）

---

## 许可证
见 [LICENSE](LICENSE)。

---

## 支持
如果你也认可“名片拍一次、信息永远结构化”的体验，欢迎点个 **Star** ⭐
Star 会提升可见度，也更容易吸引贡献者。
