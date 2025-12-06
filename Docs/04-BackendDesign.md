# 后端服务设计

## 技术选型：Supabase

### 选择理由

- 开箱即用的 PostgreSQL 数据库
- 内置用户认证（支持 Google/Apple 登录）
- 实时订阅能力
- 文件存储服务
- 官方 Swift SDK（supabase-swift）
- 免费额度适合 MVP 阶段

### 已完成配置

- ✅ 通过 Swift Package Manager 安装 supabase-swift
- ❌ 禁止使用 CocoaPods

---

## 第一阶段：认证系统

### 支持的登录方式

| 登录方式 | 第一阶段 | 后续阶段 |
|---------|---------|---------|
| Apple 登录 | ✅ 支持 | ✅ |
| Google 登录 | ✅ 支持 | ✅ |
| 邮箱密码 | ❌ 不支持 | 待定 |
| 手机号 | ❌ 不支持 | 待定 |

### 选择理由

- Apple 登录：iOS 上架要求（如果支持第三方登录必须支持 Apple）
- Google 登录：覆盖更广泛用户群
- 延迟邮箱/手机号：降低第一阶段复杂度，避免处理验证码等逻辑

---

## 数据库设计

### 核心表结构

#### users（用户表）
```
users
├── id: UUID (主键, 关联 Supabase Auth)
├── username: String (唯一)
├── display_name: String
├── avatar_url: String
├── bio: String
├── created_at: Timestamp
└── updated_at: Timestamp
```

#### projects（作品表）
```
projects
├── id: UUID (主键)
├── user_id: UUID (外键 → users)
├── title: String
├── description: String
├── html_content: Text
├── css_content: Text
├── js_content: Text
├── thumbnail_url: String (作品预览图)
├── is_published: Boolean
├── view_count: Integer
├── like_count: Integer
├── comment_count: Integer
├── share_count: Integer
├── created_at: Timestamp
└── updated_at: Timestamp
```

#### likes（点赞表）
```
likes
├── id: UUID (主键)
├── user_id: UUID (外键 → users)
├── work_id: UUID (外键 → projects)
├── created_at: Timestamp
└── UNIQUE(user_id, work_id)
```

#### collections（收藏表）
```
collections
├── id: UUID (主键)
├── user_id: UUID (外键 → users)
├── work_id: UUID (外键 → projects)
├── created_at: Timestamp
└── UNIQUE(user_id, work_id)
```

#### comments（评论表）
```
comments
├── id: UUID (主键)
├── user_id: UUID (外键 → users)
├── work_id: UUID (外键 → projects)
├── content: String
├── parent_id: UUID (外键 → comments, 可空, 用于回复)
├── created_at: Timestamp
└── updated_at: Timestamp
```

#### follows（关注表）
```
follows
├── id: UUID (主键)
├── follower_id: UUID (外键 → users, 关注者)
├── following_id: UUID (外键 → users, 被关注者)
├── created_at: Timestamp
└── UNIQUE(follower_id, following_id)
```

---

## 存储设计

### Supabase Storage Buckets

| Bucket | 用途 | 访问权限 |
|--------|------|---------|
| avatars | 用户头像 | 公开读取 |
| thumbnails | 作品预览图 | 公开读取 |
| project-assets | 作品内资源(图片/音频等) | 公开读取 |

---

## API 设计思路

### 作品相关

- 获取推荐作品列表（分页）
- 获取关注用户的作品列表
- 获取单个作品详情
- 创建作品
- 更新作品
- 删除作品

### 互动相关

- 点赞/取消点赞
- 收藏/取消收藏
- 发表评论
- 删除评论
- 获取评论列表

### 用户相关

- 获取用户信息
- 更新用户信息
- 关注/取消关注
- 获取粉丝列表
- 获取关注列表
- 获取用户作品列表

---

## 安全考虑

### Row Level Security (RLS)

Supabase 强制启用 RLS，需要配置：

- 用户只能修改自己的作品
- 用户只能删除自己的评论
- 用户只能修改自己的个人信息
- 公开内容（已发布作品）所有人可读

### 内容审核

第一阶段简化处理：
- 依赖用户举报
- 人工审核

后续可考虑：
- 自动化内容审核
- AI 检测违规内容

