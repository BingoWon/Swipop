#!/bin/bash
# Execute SQL file against Supabase
# Usage: ./Supabase/run_sql.sh <sql_file>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <sql_file>"
    exit 1
fi

SQL_FILE="$1"

if [ ! -f "$SQL_FILE" ]; then
    echo "Error: File not found: $SQL_FILE"
    exit 1
fi

echo "Executing: $SQL_FILE"

SQL=$(cat "$SQL_FILE" | jq -Rs .)
RESULT=$(curl -s -X POST "https://api.supabase.com/v1/projects/$SUPABASE_PROJECT_REF/database/query" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\": $SQL}")

if echo "$RESULT" | grep -q "error"; then
    echo "Error: $RESULT"
    exit 1
else
    echo "Success!"
    echo "$RESULT" | jq .
fi

