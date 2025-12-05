# Swipop Database Schema

> **Single Source of Truth** for the current database design.  
> For historical changes, see `../migrations/`.

## Overview

Swipop is a social platform for frontend creators to share and discover interactive web creations (HTML/CSS/JS).

## Entity Relationship Diagram

```mermaid
erDiagram
    users ||--o{ works : creates
    users ||--o{ likes : gives
    users ||--o{ collections : saves
    users ||--o{ comments : writes
    users ||--o{ follows : follows
    users ||--o{ activities : receives
    
    works ||--o{ likes : receives
    works ||--o{ collections : in
    works ||--o{ comments : has
    works ||--o{ activities : triggers
    
    comments ||--o{ comments : replies_to
    comments ||--o{ activities : triggers

    users {
        uuid id PK "References auth.users"
        text username UK "Auto-generated, unique"
        text display_name
        text avatar_url
        text bio
        jsonb links "Social links array"
        timestamptz created_at
        timestamptz updated_at
    }
    
    works {
        uuid id PK
        uuid user_id FK
        text title
        text description
        text html_content
        text css_content
        text js_content
        text thumbnail_url
        real thumbnail_aspect_ratio "0.75 ~ 1.33"
        text[] tags
        jsonb chat_messages "AI conversation history"
        boolean is_published
        integer view_count
        integer like_count "Denormalized counter"
        integer collect_count "Denormalized counter"
        integer comment_count "Denormalized counter"
        integer share_count
        timestamptz created_at
        timestamptz updated_at
    }
    
    likes {
        uuid id PK
        uuid user_id FK
        uuid work_id FK
        timestamptz created_at
        constraint "UNIQUE(user_id, work_id)"
    }
    
    collections {
        uuid id PK
        uuid user_id FK
        uuid work_id FK
        timestamptz created_at
        constraint "UNIQUE(user_id, work_id)"
    }
    
    comments {
        uuid id PK
        uuid user_id FK
        uuid work_id FK
        text content
        uuid parent_id FK "Self-reference for replies"
        timestamptz created_at
        timestamptz updated_at
    }
    
    follows {
        uuid id PK
        uuid follower_id FK
        uuid following_id FK
        timestamptz created_at
        constraint "UNIQUE(follower_id, following_id)"
        constraint "follower_id != following_id"
    }
    
    activities {
        uuid id PK
        uuid user_id FK "Notification recipient"
        uuid actor_id FK "User who triggered action"
        text type "like|comment|follow|collect"
        uuid work_id FK "Optional"
        uuid comment_id FK "Optional"
        boolean is_read
        timestamptz created_at
    }
```

## Design Decisions

### 1. Denormalized Counters

`works` table stores `like_count`, `collect_count`, `comment_count` directly instead of computing via COUNT().

**Why?**
- Feed queries are read-heavy (100:1 ratio)
- Counters updated via triggers on INSERT/DELETE
- Eliminates expensive JOIN/COUNT operations

### 2. User Profile Sync

`public.users` is automatically created when a user signs up via Supabase Auth.

**Flow:**
```
auth.users INSERT → handle_new_user() trigger → public.users INSERT
```

**Username generation:**
- Derived from OAuth display_name
- Sanitized: lowercase, spaces→underscores, alphanumeric only
- Collision handling: appends random suffix

### 3. Activity Notifications

Activities are created automatically via triggers:
- Like → `create_like_activity()`
- Collect → `create_collect_activity()`
- Comment → `create_comment_activity()`
- Follow → `create_follow_activity()`

**Self-action filtering:** No notification if user acts on their own content.

### 4. Feed with Interactions RPC

`get_feed_with_interactions(user_id, limit, offset)` returns:
- All work fields
- `is_liked`, `is_collected` booleans for current user
- Flattened creator info

**Why RPC instead of regular query?**
- Single query vs N+1 (was: 1 feed + 2N interaction checks)
- Reduces network round-trips
- Pre-computed interaction state prevents UI flashing

### 5. Thumbnail Storage

- Bucket: `thumbnails` (public read)
- Path: `{user_id}/{work_id}.jpg`
- Aspect ratio: stored in `works.thumbnail_aspect_ratio` for layout before image loads
- Transformation: Supabase Image Transformation for responsive sizes

## File Structure

| File | Purpose |
|------|---------|
| `01_tables.sql` | All table definitions with indexes |
| `02_rls.sql` | Row Level Security policies |
| `03_functions.sql` | PostgreSQL functions |
| `04_triggers.sql` | Database triggers |
| `05_storage.sql` | Storage buckets and policies |
| `06_rpc.sql` | RPC functions for client |

## Quick Reference

### Tables
- `users` - User profiles (synced from auth.users)
- `works` - Frontend creations (HTML/CSS/JS)
- `likes` - User likes on works
- `collections` - User saved works
- `comments` - Comments on works (supports threading)
- `follows` - User follow relationships
- `activities` - Notification records
- `api_keys` - AI service API key pool
- `chat_sessions` - AI chat logging

### Key Constraints
- Users cannot follow themselves: `CHECK (follower_id != following_id)`
- Unique like/collect per user-work: `UNIQUE(user_id, work_id)`
- Cascading deletes: All foreign keys use `ON DELETE CASCADE`

### Indexes
- `idx_works_user_id` - User's works lookup
- `idx_works_is_published` - Published works filter
- `idx_works_created_at` - Feed ordering
- `idx_works_tags` - Tag search (GIN index)
- `idx_activities_user_id` - User notifications
- `idx_activities_is_read` - Unread notifications (partial index)

