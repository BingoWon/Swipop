# Supabase Configuration

## Directory Structure

```
Supabase/
├── config.sh          # Environment variables (gitignored, never commit!)
├── config.toml        # Local development config
├── README.md          # This file
├── schema/            # Single source of truth for database schema
│   ├── 01_tables.sql
│   ├── 02_rls.sql
│   ├── 03_functions.sql
│   ├── 04_triggers.sql
│   ├── 05_storage.sql
│   └── 06_rpc.sql
└── scripts/           # Automation scripts
    └── db-query.sh
```

## Schema Management

**Critical Rules:**
1. `schema/` is the **single source of truth**
2. All files in `schema/` must be **idempotent** (safe to run multiple times)
3. **DO NOT** create migration files - modify schema files directly
4. After any schema change, **immediately execute** in Supabase Dashboard

### How to Apply Schema Changes

Since our Supabase project has network restrictions blocking direct CLI connections,
use the **Supabase Dashboard SQL Editor**:

1. Go to https://supabase.com/dashboard/project/axzembhfbmavvklsqsjs/sql
2. Copy content from the modified schema file
3. Execute
4. Verify changes in Table Editor

### For New Environments

Execute files in order:
```
01_tables.sql → 02_rls.sql → 03_functions.sql → 04_triggers.sql → 05_storage.sql → 06_rpc.sql
```

## Security

- `config.sh` contains secrets and is gitignored
- Never commit API keys to the repository
- Use environment variables in CI/CD

## Required Environment Variables

Create `config.sh` with:
```bash
export SUPABASE_ACCESS_TOKEN="your_access_token"
export SUPABASE_PROJECT_REF="axzembhfbmavvklsqsjs"
export SUPABASE_DB_PASSWORD="your_db_password"
```

## Enable Direct Database Connection (Optional)

To allow CLI direct connections, disable network restrictions:

1. Go to Supabase Dashboard → Settings → Database
2. Under "Network Restrictions", add your IP or CIDR range
3. Or disable restrictions entirely for development

## Automation with GitHub Actions

For CI/CD automation without manual SQL execution, set up GitHub Actions
with Supabase CLI using `supabase db push` (requires network access).
