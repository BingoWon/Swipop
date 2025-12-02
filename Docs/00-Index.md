# Swipop 产品设计文档

> 前端领域的抖音 —— 让每个人都能通过代码创作展示自己的作品

---

## 文档目录

| 文档 | 说明 |
|-----|------|
| [01-ProductVision](./01-ProductVision.md) | 产品愿景、定位、目标用户 |
| [02-TechnicalDecisions](./02-TechnicalDecisions.md) | 技术架构决策及理由 |
| [03-InteractionDesign](./03-InteractionDesign.md) | 交互设计、界面布局 |
| [04-BackendDesign](./04-BackendDesign.md) | 后端服务、数据库设计 |
| [05-FeatureRoadmap](./05-FeatureRoadmap.md) | 功能路线图、开发计划 |
| [06-GlossaryAndQA](./06-GlossaryAndQA.md) | 术语表、常见问题 |
| [07-DevelopmentTasks](./07-DevelopmentTasks.md) | 开发任务清单 |

---

## 快速概览

### 是什么

Swipop 是一个前端作品分享平台，用户可以：
- 通过 AI 辅助创建前端作品（HTML/CSS/JS）
- 像刷抖音一样浏览他人作品
- 与作品进行交互（不只是观看）
- 点赞、收藏、评论、分享

### 为什么

- AI 让普通人也能创作前端作品
- 前端作品可交互，比视频更有趣
- 不需要露脸，降低创作心理门槛
- 响应式设计适配各种设备

### 怎么做

- iOS 原生 App (SwiftUI)
- WebView 渲染作品
- Supabase 后端
- 纯 HTML/CSS/JS，无需编译

---

## 核心决策速查

| 决策项 | 结论 |
|-------|------|
| 前端框架 | ❌ 不使用 React/Next.js |
| 包管理 | ❌ 不使用 NPM |
| 编译 | ❌ 无编译过程 |
| 第三方库 | ✅ CDN 引入 |
| 作品切换 | ✅ 按钮（非滑动） |
| iOS 包管理 | ✅ SPM (禁止 CocoaPods) |
| 后端 | ✅ Supabase |
| 第一阶段登录 | ✅ Google + Apple |

---

## 第一阶段目标

1. ✅ Apple/Google 登录
2. ✅ 作品浏览（WebView）
3. ✅ 点赞/收藏
4. ✅ 基础创作功能
5. ✅ 个人中心

---

## 项目信息

- **项目名称**：Swipop
- **平台**：iOS
- **开发语言**：Swift / SwiftUI
- **后端**：Supabase
- **状态**：设计阶段

