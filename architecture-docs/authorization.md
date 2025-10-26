# Authorization System v2: Policy Engine

## Evolution: From Fragile to Future-Proof

### The Problem (v0 - Initial Implementation)

**Hard-coded role lists everywhere:**
```python
# In every handler - FRAGILE!
check_team_role(table, user_id, team_id, [
    'team-owner', 
    'team-coach', 
    'team-player', 
    'team-assistant', 
    'team-scorekeeper', 
    'team-viewer'
])
```

**Issues:**
- ❌ Adding new roles requires updating every handler
- ❌ Easy to forget a role in some places
- ❌ Inconsistent across codebase
- ❌ Not future-proof
- ❌ Handlers know too much about authorization logic

---

### The Fix (v1 - Permission Constants)

**Step 1: Simple membership check for read operations**
```python
# For "view" operations - any team member can access
check_team_membership(table, user_id, team_id)
```

**Step 2: Centralized permission constants**
```python
# In authorization.py
MANAGE_ROSTER_ROLES = ['team-owner', 'team-coach']
MANAGE_TEAM_ROLES = ['team-owner', 'team-coach']
DELETE_TEAM_ROLES = ['team-owner']

# In handlers
check_team_role(table, user_id, team_id, MANAGE_ROSTER_ROLES)
```

**Improvements:**
- ✅ Centralized role definitions
- ✅ Consistent across handlers
- ✅ Easier to update permissions
- ⚠️ **Still requires handlers to import and know about role constants**

---

### The Evolution (v2 - Policy Engine)

**Central policy map:**
```python
# In authorization.py
POLICY_MAP = {
    'manage_roster': MANAGE_ROSTER_ROLES,
    'manage_team': MANAGE_TEAM_ROLES,
    'delete_team': DELETE_TEAM_ROLES,
}
```

**Single authorization function:**
```python
def authorize(table, user_id, team_id, action):
    """
    Check if user can perform a specific action on a team.
    
    Handlers just ask: "can this user do X?"
    They don't need to know WHO can do X.
    """
    required_roles = POLICY_MAP.get(action)
    if not required_roles:
        raise PermissionError(f"Invalid action: {action}")
    
    return _check_team_role(table, user_id, team_id, required_roles)
```

**Handler usage - CLEAN!**
```python
# In add_player.py
from utils.authorization import authorize  # ← Just one import!

try:
    authorize(table, user_id, team_id, action='manage_roster')
except PermissionError as e:
    return create_response(403, {'error': str(e)})
```

---

## Benefits of v2 Policy Engine

### 1. **Zero Knowledge Handlers**
Handlers don't know or care about roles. They just ask: "can this user do X?"

**Before (v1):**
```python
from utils.authorization import check_team_role, MANAGE_ROSTER_ROLES

check_team_role(table, user_id, team_id, MANAGE_ROSTER_ROLES)
```

**After (v2):**
```python
from utils.authorization import authorize

authorize(table, user_id, team_id, action='manage_roster')
```

### 2. **Single Source of Truth**
All authorization logic lives in one place: `POLICY_MAP`

```python
# Want to add team-assistant to roster management?
# Just update ONE line:
MANAGE_ROSTER_ROLES = ['team-owner', 'team-coach', 'team-assistant']

# All handlers automatically get the new permission!
```

### 3. **Future-Proof**
Adding new roles or actions is trivial:

```python
# Add a new role
RECORD_STATS_ROLES = ['team-owner', 'team-coach', 'team-scorekeeper']

# Add to policy map
POLICY_MAP = {
    'manage_roster': MANAGE_ROSTER_ROLES,
    'manage_team': MANAGE_TEAM_ROLES,
    'delete_team': DELETE_TEAM_ROLES,
    'record_stats': RECORD_STATS_ROLES,  # ← New action!
}

# Handlers just use it
authorize(table, user_id, team_id, action='record_stats')
```

### 4. **Self-Documenting**
The policy map serves as documentation:

```python
# Anyone can see all available actions and who can perform them
POLICY_MAP = {
    'manage_roster': ['team-owner', 'team-coach'],
    'manage_team': ['team-owner', 'team-coach'],
    'delete_team': ['team-owner'],
    # ... more actions
}
```

### 5. **Error Prevention**
Invalid actions are caught immediately:

```python
authorize(table, user_id, team_id, action='invalid_action')
# PermissionError: Invalid action: invalid_action
# Logs all valid actions for debugging
```

---

## Implementation Details

### File: `src/utils/authorization.py`

**Public API:**
```python
# Primary function (v2 Policy Engine)
authorize(table, user_id, team_id, action)

# Simple membership check (for read operations)
check_team_membership(table, user_id, team_id)

# Extract user ID from JWT
get_user_id_from_event(event)

# Backward compatibility (prefer authorize())
check_team_role(table, user_id, team_id, required_roles)
```

**Internal Implementation:**
```python
# Permission constants
MANAGE_ROSTER_ROLES = ['team-owner', 'team-coach']
MANAGE_TEAM_ROLES = ['team-owner', 'team-coach']
DELETE_TEAM_ROLES = ['team-owner']

# Central policy map
POLICY_MAP = {
    'manage_roster': MANAGE_ROSTER_ROLES,
    'manage_team': MANAGE_TEAM_ROLES,
    'delete_team': DELETE_TEAM_ROLES,
}

# Private helper (used by authorize())
_check_team_role(table, user_id, team_id, required_roles)
```

---

## Current Usage Across Codebase

### Player Handlers (Roster Management)

**Read Operations (any team member):**
- `src/players/get/handler.py` → `check_team_membership()`
- `src/players/list/handler.py` → `check_team_membership()`

**Write Operations (owner/coach only):**
- `src/players/add/handler.py` → `authorize(..., action='manage_roster')`
- `src/players/update/handler.py` → `authorize(..., action='manage_roster')`
- `src/players/remove/handler.py` → `authorize(..., action='manage_roster')`

### Team Handlers

**Team Management:**
- `src/teams/update/handler.py` → `authorize(..., action='manage_team')`

**Team Deletion:**
- `src/teams/delete/handler.py` → `authorize(..., action='delete_team')`

---

## Adding New Actions (Example)

### Scenario: Add "Record Stats" Permission

**Step 1: Define roles**
```python
# In authorization.py
RECORD_STATS_ROLES = ['team-owner', 'team-coach', 'team-scorekeeper']
```

**Step 2: Add to policy map**
```python
POLICY_MAP = {
    'manage_roster': MANAGE_ROSTER_ROLES,
    'manage_team': MANAGE_TEAM_ROLES,
    'delete_team': DELETE_TEAM_ROLES,
    'record_stats': RECORD_STATS_ROLES,  # ← New!
}
```

**Step 3: Use in handler**
```python
# In record_atbat.py
from utils.authorization import authorize

try:
    authorize(table, user_id, team_id, action='record_stats')
except PermissionError as e:
    return create_response(403, {'error': str(e)})
```

**Done!** No other files need to change.

---

## Testing

All authorization tests pass with the new system:

```bash
# Test player operations
make test-players <userId>

# Test team operations
make test-teams <userId>
```

---

## Future Enhancements

### 1. **Dynamic Policies (Database-Driven)**
```python
# Load policies from DynamoDB instead of hardcoding
POLICY_MAP = load_policies_from_db()
```

### 2. **Custom Roles**
```python
# Allow teams to define custom roles
authorize(table, user_id, team_id, action='manage_roster', 
          custom_roles=team.custom_roles)
```

### 3. **Audit Logging**
```python
# Log all authorization decisions
authorize(..., audit=True)
# Creates AUDIT#AUTH#<timestamp> record
```

### 4. **Permission Caching**
```python
# Cache user permissions in JWT claims
# Reduces DynamoDB lookups
```

---

## Key Takeaways

✅ **Handlers are dumb** - They just ask "can I do X?"  
✅ **Policy is centralized** - One place to change permissions  
✅ **Future-proof** - Add roles/actions without touching handlers  
✅ **Self-documenting** - Policy map shows all permissions  
✅ **Error-safe** - Invalid actions caught immediately  
✅ **Testable** - Easy to mock and test  

---

## Migration Notes

**v0 → v1 (Completed):**
- ✅ Added `check_team_membership()` for read operations
- ✅ Created permission constants (`MANAGE_ROSTER_ROLES`, etc.)
- ✅ Updated all handlers to use constants

**v1 → v2 (Completed):**
- ✅ Created `POLICY_MAP` central registry
- ✅ Added `authorize()` function
- ✅ Updated all handlers to use `authorize()`
- ✅ Kept `check_team_role()` for backward compatibility
- ✅ Deployed to AWS (15 Lambda functions updated)

**Next Steps:**
- Consider moving to database-driven policies
- Add audit logging for compliance
- Implement permission caching for performance

---

## See Also

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete system design
- **[DATA_MODEL.md](./DATA_MODEL.md)** - Current implementation
- **[src/utils/authorization.py](./src/utils/authorization.py)** - Authorization implementation

