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

## 目录
- [为什么要做这个](#为什么要做这个)
- [它哪里不一样](#它哪里不一样)
- [功能概览](#功能概览)
- [AI 补全（分阶段 & 可追责）](#ai-补全分阶段--可追责)
- [语言显示（EN/中文）](#语言显示-en中文)
- [本地优先 & 隐私](#本地优先--隐私)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [路线图](#路线图)
- [文档（权威规格）](#文档权威规格)
- [参与贡献](#参与贡献)
- [许可证](#许可证)
- [支持](#支持)

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

## 功能概览

**核心功能**
- 单文档多图采集（名片 + 宣传页/资料）
- 创建/编辑联系人与公司档案
- 联系人 ↔ 公司交叉关联（仅选择已有项）
- 目录：搜索 + 筛选 + A–Z 字母索引
- 备注 + 标签 + 可点击链接（电话/邮箱/网站/LinkedIn）

**为效率而设计**
- 详情页模块化编辑（一次只改一个模块）
- 关联列表固定高度可滚动，快速关联/解除关联
- 删除/解除等破坏性操作均需确认

**为信任而设计**
- 仅高亮“本次补全”发生变化的字段
- 高亮在离开页面或手动编辑保存后清除
- 字段级撤销，而不是“整次回滚”

---

## AI 补全（分阶段 & 可追责）

**阶段**
1) 照片分析（mini model）  
2) 联网检索（thinking model，多轮检索）  
3) 合并 + 去重 + 输出  

**交互规则**
- 进度只在阶段完成后推进（不做假进度条）
- 补全过程中该文档禁止编辑
- 如果没有找到有效信息：显示 **“No information found online.”**

**质量与安全**
- 与已知信息交叉验证，降低错配
- 不确定信息用 **[Possibly inaccurate]** 标注
- 优先官方来源（官网 / LinkedIn / 个人站点）
- 涉华策略：先搜中文来源，再补国际来源

---

## 语言显示（EN/中文）
- 默认跟随系统语言
- 目标语言缺失时：回退到已有语言，并后台补齐翻译
- 翻译触发：创建/编辑保存/补全完成；结果缓存，仅在源字段变化后重译
- 标签**不翻译**（按系统语言生成；专有名词保留）

---

## 本地优先 & 隐私
- 文档与照片存储在**本地**
- 仅当你主动触发解析/补全/翻译时才会产生网络请求
- 核心功能不依赖自建服务器（设计如此）

> 若未来加入云同步或分析，请保持 opt-in，并在文档中清晰说明。

---

## 快速开始

### 1) 配置 API Key（仅本地）
新建 `BusinessCardAIAssisstant/Secrets.xcconfig`：

```txt
OPENAI_API_KEY = your_key_here
```

### 2) 运行
打开 `BusinessCardAIAssisstant.xcodeproj` 并运行。

**备注**
- 模型与 prompts 位于 `BusinessCardAIAssisstant/App/AIConfig.swift`
- 该文件被 gitignore（不提交），用于保持 key 与 prompt 变体的本地安全

---

## 项目结构
```
BusinessCardAIAssisstant/
  App/          # 入口、设置、全局状态、多语言 strings
  UI/           # 页面与可复用组件
  Models/       # 数据模型与筛选器
  Services/     # 解析、补全、翻译、检索
  Storage/      # 本地持久化与照片存储
  Resources/    # 资源文件
  Assets.xcassets/
```

---

## 路线图
- [ ] App 内存占用展示
- [ ] 用户自管 API Key / 分阶段模型配置 + 校验
- [ ] 文档分享：导入确认 + 重复/冲突处理
- [ ] 单文档 PDF 导出
- [ ] 付费分发（无 IAP 流程）

---

## 文档（权威规格）
本项目以 PRD 作为“行为单一真相源”（source of truth）：
- **中文：**[Product Requirement.md](Product%20Requirement.md)
- **EN:** [Product Requirement.en.md](Product%20Requirement.en.md)

参与贡献时，请对齐 PRD 中的规则（语言显示、标签规则、补全高亮/撤销、关联交互等）。

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
