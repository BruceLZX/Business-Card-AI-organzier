# BusinessCardAIAssisstant

[English / 英文](README.md)

一个用于 iPhone 的名片与公司资料采集应用。通过拍照生成结构化“联系人/公司档案”，支持搜索、标签与双向关联，并可使用 AI 联网补全信息。

## 产品需求文档
- 详细用例见 `Product Requirement.md`（中文）。

## 核心功能
- 拍照或从图库添加图片（单个档案最多 10 张）。
- 联系人与公司详情页的模块化编辑与跳转关联。
- 目录页的字母索引与多条件筛选（联系人/公司均支持）。
- Tag pool 可搜索选择，AI 补全标签。
- AI 补全带分阶段进度、字段级对比与撤销。

## AI 补全概览
- 先用 mini 模型解析照片，再用 thinking 模型多阶段联网搜索。
- 补全过程显示全局进度，期间禁止所有交互。
- 更新字段高亮显示，并展示原有内容，可一键撤销。
- 不确定信息用黄色“可能不准确”标记。

## 技术栈
- SwiftUI + 本地存储。
- OpenAI Responses API（密钥配置在 `Secrets.xcconfig`）。

## 项目结构
- `BusinessCardAIAssisstant/` 应用源码
- `BusinessCardAIAssisstant/Services/` 拍照、OCR、补全、搜索
- `BusinessCardAIAssisstant/Storage/` 本地存储与图片管理
- `BusinessCardAIAssisstant/UI/` 页面与组件
- `BusinessCardAIAssisstant/Models/` 数据模型
- `BusinessCardAIAssisstant/App/` 应用入口与全局状态

## 本地配置
1. 创建 `BusinessCardAIAssisstant/Secrets.xcconfig`：
   ```
   OPENAI_API_KEY = your_key_here
   ```
2. 打开 `BusinessCardAIAssisstant.xcodeproj` 运行。

## AI 配置（本地、Git 忽略）
- 模型选择与 prompt 集中在 `BusinessCardAIAssisstant/App/AIConfig.swift`。
- 该文件已被 `.gitignore` 排除，不会提交到仓库。
- 每段 prompt 都有注释说明用途与调用位置。

## 当前进度
- 已完成：档案与目录基础流程、AI 补全流程与对比撤销。
- 进行中：按 `Product Requirement.md` 继续验证与优化细节。

## 下一步目标
- 开通收费功能（订阅或一次性解锁）。
- 文档可通过分享按钮分享给其他已安装该 App 的用户。
- 每个文档支持生成 PDF 报告，可分享或保存。
- 根据用户地区选择 AI 服务（如中国区使用其他 API）。

## 备注
- App icon 位于 `BusinessCardAIAssisstant/Assets.xcassets/AppIcon.appiconset`。
- 密钥不提交，`.gitignore` 已排除相关文件。
