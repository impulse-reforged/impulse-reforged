# Code Style Guide

This document describes the code formatting and style conventions used throughout the impulse-reforged framework. These conventions are enforced through code review and are not automatically formatted—consistency is achieved through developer discipline and peer review.

## General Philosophy

The framework prioritizes **readability**, **consistency**, and **diff-friendly** code. Style decisions favor clarity over brevity and minimize visual noise in diffs. Conventions accommodate Garry's Mod and Source Lua quirks while maintaining a clean, professional codebase.

## Indentation & Whitespace

### Indentation
- **Use 4 spaces per indentation level**—never use tabs.
- Consistent indentation is critical for readability in deeply nested structures (hooks, conditionals, table definitions).

### Line Endings
- All files use Unix-style line endings (`\n`), not Windows (`\r\n`).
- Avoid trailing whitespace at the end of lines.

### Blank Lines
- Use single blank lines to separate logical blocks of related code.
- Use two blank lines between major sections (e.g., between large function groups or between module initialization and hook definitions).
- Do not use multiple consecutive blank lines within a function body.

### Line Length
- Lines should generally be kept under 120 characters.
- Long expressions may exceed this if breaking them would harm readability.

## Naming Conventions

### File Names
All files follow the **realm prefix** convention—critical for automatic inclusion:
- `sv_*.lua` – Server-only files, never sent to clients
- `cl_*.lua` – Client files, sent to and executed on clients
- `sh_*.lua` – Shared files, executed on both client and server
- `shared.lua` – Standard Garry's Mod convention (shared)
- `init.lua` – Server entry point
- `cl_init.lua` – Client entry point

**Example structure:**
```
plugins/myplugin/
  sh_config.lua      -- Shared configuration
  sv_hooks.lua       -- Server-only hooks
  derma/cl_*panelname*.lua  -- Client UI panel, if more, split up into multiple files
```

### Variables & Locals
- **Local variables** use `camelCase`: `local playerHealth`, `local isAdmin`
- **Global variables** (module tables) use `PascalCase`: `impulse.Inventory`, `SCHEMA`, `PLAYER`
- **Meta tables** use uppercase `PLAYER`, `ENTITY`, `WEAPON` (returned from `FindMetaTable`)
- **Temporary table definitions** use uppercase: `local ITEM = {}`, `local TEAM = {}`

### Functions
- **Function names** use `camelCase`: `function myFunction()`, `function OnUse()`
- **Hook callbacks** follow Garry's Mod conventions: `function GM:Initialize()`, `function ENTITY:Initialize()`
- **Namespace methods** use `PascalCase`: `impulse.Inventory:RegisterItem()`, `impulse.Database:Connect()`

### Constants & Enums
- **Framework-level constants** use `UPPER_SNAKE_CASE`: `INVENTORY_PLAYER`, `INVENTORY_STORAGE`
- **Team/class enums** use `UPPER_SNAKE_CASE`: `CLASS_SECURITY_OFFICER`, `RANK_SECURITY_SERGEANT`
- These are typically defined at file scope in schema files

### Modules & Namespaces
The framework uses table-based modules under the `impulse.*` namespace:
```lua
impulse.Inventory = impulse.Inventory or {}
impulse.Database = impulse.Database or {}
impulse.Hooks = impulse.Hooks or {}
```

**Initialization pattern:**
```lua
impulse.MyModule = impulse.MyModule or {
    Data = {},
    Config = {}
}
```

## File Structure

### Typical File Order
1. **Requires/Includes** – None (Garry's Mod handles this automatically via realm prefixes)
2. **Lua Standard Library** – Any base library extensions
3. **Module Declaration** – `local ITEM = {}` or `impulse.MyModule = impulse.MyModule or {}`
4. **Configuration/Data** – Constants, default tables, enums
5. **Function Definitions** – All custom functions
6. **Hook Registration** – `hook.Add()` calls at the end
7. **Module Export** – Registration via `impulse.Inventory:RegisterItem()` or similar

### Realm Awareness in Files
When a file needs to handle both client and server logic:
```lua
if ( SERVER ) then
    -- Server-only code
elseif ( CLIENT ) then
    -- Client-only code
else
    -- Shared code
end
```

Prefer splitting into separate `sv_`, `cl_`, and `sh_` files when logic significantly diverges.

### Plugin & Schema Layout
```
plugins/myplugin/
  sh_config.lua          -- Configuration tables
  sv_hooks.lua           -- Server-side hooks
  cl_ui.lua              -- Client-side UI
  entities/
    some_entity.lua      -- Custom entity
  weapons/
    some_weapon.lua      -- Custom weapon

schema/
  sh_schema.lua          -- Schema metadata
  sh_teams.lua           -- Team definitions
  sh_config.lua          -- Configuration
  scripts/               -- Whatever scripts you might want without making a plugin, such as quick utility functions or overrides
  items/
    sh_item_name.lua     -- Individual item
  buyables/
    sh_category.lua      -- Buyable definitions
  vendors/
    sh_vendor.lua        -- Vendor setup
```

## Functions & Control Flow

### Function Declaration
Standard function syntax:
```lua
function MyFunction(param1, param2)
    -- body
end

local function PrivateFunction()
    -- body
end

function ITEM:OnUse(client)
    -- method body
end
```

### Early Returns
Prefer early returns to reduce nesting and improve readability:
```lua
function ProcessPlayer(client)
    if ( !IsValid(client) ) then return end
    if ( client:IsBot() ) then return end
    if ( !client:IsAdmin() ) then return end

    -- main logic here
end
```

**Not:**
```lua
function ProcessPlayer(client)
    if IsValid(client) then
        if !client:IsBot() then
            if client:IsAdmin() then
                -- main logic here
            end
        end
    end
end
```

### Conditional Formatting
- Use parentheses around conditions in `if/elseif/while` statements for clarity:
  ```lua
  if ( IsValid(entity) and entity:GetHealth() > 0 ) then
      -- do something
  end
  ```
- Prefer `and` / `or` over `&&` / `||`
- Use `!` for negation (preferred) over `not` in conditional contexts
- Ternary conditionals are acceptable for simple assignments:
  ```lua
  local result = IsValid(entity) and entity:GetHealth() or 0
  ```

### Loop Formatting
- **For loops:** Standard Lua convention
  ```lua
  for k, v in pairs(table) do
      -- body
  end

  for i = 1, 10 do
      -- body
  end
  ```
- **Iteration:** Use `ipairs` for arrays, `pairs` for tables
- **Breaking out:** Use early returns in functions; use `break` for loops

## Tables

### Table Literals
- **Inline** for small, simple tables:
  ```lua
  local config = { enabled = true, timeout = 30 }
  ```
- **Multiline** for complex or configurable data:
  ```lua
  local ITEM = {
      UniqueID = "food_apple",
      Name = "Apple",
      Weight = 0.2,
      CanStack = true
  }
  ```

### Table Properties
Assign properties on separate lines when defining tables used for configuration:
```lua
local ITEM = {}

ITEM.UniqueID = "food_apple"
ITEM.Name = "Apple"
ITEM.Desc = "A crisp, fresh apple."
ITEM.Model = Model("models/path/to/model.mdl")
ITEM.Weight = 0.2
ITEM.CanStack = true
```

This pattern is preferred for schema items because it:
- Allows easy line-by-line diffing
- Makes additions/removals non-invasive
- Improves git blame readability

### Trailing Commas
- **Do not use trailing commas** in multiline tables:
  ```lua
  local data = {
      key1 = "value1",
      key2 = "value2"  -- no comma here
  }
  ```

### Table Alignment
- Do not align `=` signs or values across multiple lines—maintain left-aligned keys:
  ```lua
  local ITEM = {}
  ITEM.UniqueID = "food_apple"
  ITEM.Name = "Apple"
  ITEM.Weight = 0.2
  ```

## Comments & Documentation

### When to Comment
- **Required:** Complex algorithms, non-obvious logic, framework hooks, security-sensitive code
- **Discouraged:** Self-documenting code, simple variable assignments, obvious control flow

### Comment Style
- **Single-line comments** for brief explanations:
  ```lua
  -- Check if player has permission
  if ( !client:IsAdmin() ) then return end
  ```
- **Block comments** for multi-paragraph explanations:
  ```lua
  --[[--
  This function processes player inventory changes and syncs
  data to the database. It handles stacking, weight calculations,
  and client notifications.
  ]]
  function PLAYER:SyncInventory()
  ```

### Documentation Comments (LDoc Format)
Public APIs use LDoc-compatible documentation:
```lua
--- Registers a new inventory item
-- @realm shared
-- @param item Item data table
-- @usage impulse.Inventory:RegisterItem(ITEM)
-- @internal
function impulse.Inventory:RegisterItem(item)
```

### Inline Comments
- Place on the same line as code when explaining a specific line:
  ```lua
  local timeout = 30 -- cooldown in seconds
  ```
- Use sparingly; prefer self-documenting code

### TODOs & FIXMEs
```lua
-- TODO: implement player rank system
-- FIXME: this crashes on invalid models
```

Keep these minimal and actionable. Remove before commits when possible.

## Hooks, Networking, and Callbacks

### Hook Registration
Use standard Garry's Mod `hook.Add()` syntax:
```lua
hook.Add("PlayerSpawn", "MyPlugin_PlayerSpawn", function(client)
    -- callback body
end)
```

**Naming convention:** `HookName_UniqueCallbackID`

### Custom Hooks (Framework)
The framework provides custom hook routing via `impulse.Hooks`:
```lua
-- Register a hook group (in init)
impulse.Hooks:Register("SCHEMA")

-- Define hooks in SCHEMA table
function SCHEMA:OnPlayerLoadout(client)
    return true -- return non-nil to override behavior
end
```

Hooks check `SCHEMA` hooks first, then `PLUGIN` hooks, then standard GMod hooks.

### Net Messages
- **Registration (server):**
  ```lua
  util.AddNetworkString("myCustomMessage")
  ```
- **Sending (server):**
  ```lua
  net.Start("myCustomMessage")
      net.WriteString(data)
      net.WriteInt(value, 32)
  net.Send(client)
  ```
- **Receiving (client):**
  ```lua
  net.Receive("myCustomMessage", function(len)
      local data = net.ReadString()
      local value = net.ReadInt(32)
  end)
  ```

**Naming convention:** Use camelCase for message names; prefix with realm indicator if helpful (e.g., `impulsePlayGesture`, `impulseChatText`).

### Callback Parameters
- Use descriptive parameter names in callbacks:
  ```lua
  net.Receive("myMessage", function(len, client)
      -- client parameter only available on server
  end)

  hook.Add("PlayerDeath", "unique_id", function(victim, inflictor, attacker)
      -- standard GMod parameters
  end)
  ```

## Error Handling & Assertions

### Validation
Defensive checks are preferred over assertions:
```lua
if ( !IsValid(entity) ) then
    return false
end

if ( !client:IsAdmin() ) then
    return client:Notify("Admin only!")
end
```

### Error Reporting
Use `error()` for fatal, unrecoverable conditions:
```lua
if ( !impulse.Database.Type[fieldType] ) then
    error(string.format("invalid type '%s'", fieldType))
    return
end
```

### Logging
The framework provides `impulse.Logs` for debug output:
```lua
logs:Database("loading tables...")
```

Use logging for important state changes, connection events, and troubleshooting information.

## Examples

### Item Definition (Complete)
```lua
local ITEM = {}

ITEM.UniqueID = "food_apple"
ITEM.Name = "Apple"
ITEM.Desc = "A crisp, fresh apple."
ITEM.Category = "Food"
ITEM.Model = Model("models/path/to/apple.mdl")
ITEM.FOV = 16
ITEM.Weight = 0.2
ITEM.NoCenter = true

ITEM.Droppable = true
ITEM.DropOnDeath = false

ITEM.Illegal = false
ITEM.CanStack = true

ITEM.UseName = "Eat"
ITEM.UseWorkBarTime = 2
ITEM.UseWorkBarName = "Eating..."
ITEM.UseWorkBarSound = "impulse/eat.wav"

ITEM.Food = 20

function ITEM:OnUse(client)
    client:FeedHunger(self.Food)
    return true -- item consumed
end

impulse.Inventory:RegisterItem(ITEM)
```

### Hook Implementation
```lua
-- Schema hook that overrides player spawn
function SCHEMA:PlayerSpawn(client)
    if !client:IsAlive() then return end

    client:SetArmor(client:GetMaxArmor())
    client:SetHealth(client:GetMaxHealth())

    return true -- return non-nil to suppress other hooks
end
```

### Module Extension (Meta Table)
```lua
local PLAYER = FindMetaTable("Entity")

--- Sends a chat message to the player
-- @realm shared
-- @tab package Chat message elements
-- @usage client:AddChatText(Color(255, 0, 0), "Hello")
function PLAYER:AddChatText(...)
    local package = {...}

    if ( SERVER ) then
        net.Start("impulseChatText")
            net.WriteTable(package)
        net.Send(self)
    else
        chat.AddText(unpack(package))
    end
end
```

### Utility Function
```lua
--- Checks if a location is empty and safe for spawning
-- @realm shared
-- @vec pos Position to check
-- @treturn bool True if empty
function impulse.Util:IsEmpty(pos, ignore)
    if ( isentity(pos) ) then
        pos = pos:GetPos()
    elseif ( istable(pos) and pos.x and pos.y and pos.z ) then
        pos = Vector(pos.x, pos.y, pos.z)
    elseif ( !isvector(pos) ) then
        ErrorNoHalt("impulse.Util:IsEmpty called with invalid position type\n")
        return false
    end

    ignore = ignore or {}

    local point = util.PointContents(pos)
    local a = point != CONTENTS_SOLID and point != CONTENTS_MOVEABLE and point != CONTENTS_LADDER
    if ( !a ) then return false end

    for _, entity in ipairs(ents.FindInSphere(pos, 35)) do
        if ( ( entity:IsNPC() or entity:IsPlayer() ) and !table.HasValue(ignore, entity) ) then
            return false
        end
    end

    return true
end
```

### Configuration Table
```lua
impulse.Config.OOCLimit = 5
impulse.Config.OOCLimitVIP = 10
impulse.Config.OOCTimeout = 30 -- seconds
impulse.Config.TalkDistance = 256 -- units
```

## Summary

Following these conventions ensures:
- **New contributors** write code that matches the framework on the first attempt
- **Code review** focuses on logic and architecture, not style formatting
- **Diffs remain clean** and focused on actual changes
- **Cross-team consistency** simplifies maintenance and debugging
- **Lua and Garry's Mod idioms** are respected while maintaining clarity

When in doubt, follow the existing codebase patterns and ask for feedback during review.
