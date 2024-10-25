-- luacheck: ignore 111

--- Hooks that can be used in a Plugin or a Schema for the client
-- @hooks Client

--- Called before the inventory item menu has been populated
-- @realm client
-- @param card The card panel that is used to display the item. You can use this to get the item data by calling card.Item
-- @treturn bool Should we allow the dropdown menu to be populated?
-- @usage hook.Add("PrePopulateInventoryItemMenu", "MyUniqueHookID", function(card)
-- 	    return LocalPlayer():IsAdmin() -- Only allow admins to interact with the item
-- end)
function PrePopulateInventoryItemMenu(card)
end

--- Called after the inventory item menu has been populated
-- @realm client
-- @param card The card panel that is used to display the item. You can use this to get the item data by calling card.Item
-- @param popup The dropdown menu that is used to show you actions you can do with the item, such as dropping it
-- @usage hook.Add("PostPopulateInventoryItemMenu", "MyUniqueHookID", function(card, popup)
-- 	    popup:AddOption("My Custom Action", function()
-- 	        print("You clicked the custom action!")
-- 	    end)
-- end)
function PostPopulateInventoryItemMenu(card, popup)
end

--- Returns a custom death sound to override the default impulse one
-- @realm client
-- @treturn string Sound path
function GetDeathSound()
end

--- Called when you can define settings, all settings you want to define should be done inside this hook
-- @realm client
-- @see Setting
function DefineSettings()
end

--- Called when the menu is active and MenuMessages are ready to be created
-- @realm client
-- @see MenuMessage
function CreateMenuMessages()
end

--- Called when the menu is active and MenuMessages are ready to be displayed
-- @realm client
-- @internal
-- @see MenuMessage
function DisplayMenuMessages()
end

--- Called when the local player is sent to jail, provides jail sentence data
-- @realm client
-- @int endTime When the jail sentence will end
-- @param jailData Data regarding the sentence including crimes commited
function PlayerGetJailData()
end

--- Called after a chat class message is sent
-- @realm client
-- @treturn bool Should we draw the HUD box?
function ShouldDrawHUDBox()
end

--- Called every tick, use this to check for key presses to open user interface elements (input.IsKeyDown)
-- @realm client
function CheckMenuInput()
end