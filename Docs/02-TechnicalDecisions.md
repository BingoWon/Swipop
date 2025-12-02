# 技术架构决策

## 核心技术决策

### 决策一：纯三件套，不使用框架

**结论**：作品仅支持 HTML + CSS + JavaScript，不支持 React、Next.js 等框架。

**理由**：

| 考量 | 使用框架 | 纯三件套 |
|-----|---------|---------|
| 编译需求 | 必须编译 | 无需编译 |
| 环境依赖 | 需要 Node.js 环境 | 无依赖 |
| 部署复杂度 | 需要构建流程 | 直接存储/渲染 |
| 服务器成本 | 需要编译服务 | 仅需存储 |
| 用户门槛 | 需理解项目结构 | 三个文件即可 |

**关键洞察**：
- React/Next.js 编译后本质上也是 HTML/CSS/JS
- 框架带来的路由管理对单页作品无意义
- 用户不是开发者，不应处理任何技术细节

---

### 决策二：不使用 NPM，通过 CDN 引入库

**结论**：禁止 NPM 包管理，所有第三方库通过 CDN 链接引入。

**实现方式**：

```html
<!-- 示例：通过 CDN 引入 Three.js -->
<script src="https://cdn.jsdelivr.net/npm/three@latest/build/three.min.js"></script>

<!-- 示例：通过 CDN 引入 D3.js -->
<script src="https://cdn.jsdelivr.net/npm/d3@latest/dist/d3.min.js"></script>
```

**可用的丰富库生态**：
- **3D 效果**：Three.js、Babylon.js
- **数据可视化**：D3.js、Chart.js、ECharts
- **动画**：GSAP、Anime.js、Lottie
- **物理引擎**：Matter.js、Cannon.js
- **粒子效果**：Particles.js
- **音频**：Tone.js、Howler.js

**核心优势**：
- 无需编译流程
- 无需包管理
- 无需处理依赖冲突
- 用户只需在 HTML 中加一行 script 标签

---

### 决策三：彻底移除编译过程

**结论**：整个平台不涉及任何编译环节。

**流程对比**：

```
❌ 传统框架流程：
用户代码 → NPM 安装 → 编译构建 → 部署 → 访问

✅ Swipop 流程：
用户代码 → 直接存储 → 直接渲染
```

**好处**：
- 极大简化后端架构
- 无需维护编译服务器
- 无需处理编译错误
- 作品秒级发布
- 降低运营成本

---

### 决策四：作品存储与渲染方案

**存储方案**：
- 作品源码（HTML/CSS/JS）直接存储在 Supabase 数据库
- 可选：大型资源（图片/音频）存储在 Supabase Storage

**渲染方案**：
- iOS 端使用 WKWebView 渲染作品
- 从数据库获取源码，本地组装成完整 HTML
- WebView 直接加载渲染

**数据结构示意**：
```
works 表
├── id: UUID
├── user_id: UUID
├── title: String
├── html_content: Text
├── css_content: Text
├── js_content: Text
├── created_at: Timestamp
├── likes_count: Integer
└── ...
```

---

## 放弃的方案

### 方案 A：Cloudflare Pages 部署每个作品

**放弃原因**：
- 每个作品一个 Pages 项目，规模化后管理困难
- 几百万作品 = 几百万个项目，不合理
- 增加了不必要的复杂度

### 方案 B：服务端编译

**放弃原因**：
- 需要维护编译环境（Node.js、NPM）
- 编译可能失败，错误处理复杂
- 增加服务器成本和延迟
- 用户体验下降（等待编译）

### 方案 C：用户本地编译后上传

**放弃原因**：
- 违背"用户不是开发者"的核心理念
- 用户不应该知道什么是编译
- 极大提高使用门槛

---

## 技术栈总结

| 层面 | 技术选型 |
|-----|---------|
| iOS 客户端 | SwiftUI + WKWebView |
| 包管理 | Swift Package Manager (禁止 CocoaPods) |
| 后端服务 | Supabase |
| 数据库 | Supabase PostgreSQL |
| 存储 | Supabase Storage |
| 认证 | Supabase Auth (Google/Apple 登录) |
| 作品技术栈 | 纯 HTML + CSS + JavaScript |
| 第三方库 | CDN 引入 (jsdelivr/unpkg/cdnjs) |

