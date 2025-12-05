# Swipop Database Schema

## Structure

```
Supabase/
├── schema/              ← 唯一事实来源，可直接执行
│   ├── 01_tables.sql    # 表结构 + 索引
│   ├── 02_rls.sql       # Row Level Security 策略
│   ├── 03_functions.sql # PostgreSQL 函数
│   ├── 04_triggers.sql  # 数据库触发器
│   ├── 05_storage.sql   # 存储桶 + 策略
│   └── 06_rpc.sql       # RPC 函数（客户端调用）
│
└── migrations/          ← 一次性脚本，执行后删除
    └── (临时文件)
```

## 核心原则

### schema/ 是唯一事实来源

- 所有 SQL 文件都是 **幂等的**（可重复执行）
- 使用 `CREATE TABLE IF NOT EXISTS`、`CREATE OR REPLACE FUNCTION`、`DROP POLICY IF EXISTS` 等
- 新环境初始化：按顺序执行 01 → 06
- 任何变更：直接修改 schema/ 中的文件

### migrations/ 是一次性的

- 只用于 **临时的数据修复脚本**
- **执行完毕后必须删除**
- **禁止**在 migrations/ 中存放永久性 schema 定义
- AI 智能体和开发者应 **只参考 schema/**

## 执行顺序

```bash
# 新环境初始化
01_tables.sql      # 先建表
02_rls.sql         # 再设权限
03_functions.sql   # 再建函数
04_triggers.sql    # 再建触发器（依赖函数）
05_storage.sql     # 存储配置
06_rpc.sql         # RPC 函数
```

## 变更流程

1. **修改 schema/** 中对应的文件
2. **在 Supabase SQL Editor 执行**修改的文件
3. **提交代码**
4. 如需一次性数据修复，在 migrations/ 创建临时脚本，执行后删除

## 设计决策

### 反范式计数器
`works` 表存储 `like_count`、`collect_count` 等，通过触发器自动更新，避免 COUNT 查询。

### 用户同步
`auth.users` 插入时自动创建 `public.users`，包含自动生成的 username。

### 通知系统
点赞/评论/关注/收藏时通过触发器自动创建 `activities` 记录。

### Feed RPC
`get_feed_with_interactions()` 一次查询返回作品 + 当前用户交互状态，消除 N+1 问题。

