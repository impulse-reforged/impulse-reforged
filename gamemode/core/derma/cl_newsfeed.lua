local logs = impulse.Logs

/*
local PANEL = {}

function PANEL:Init()
    self:SetCursor("hand")

    self.news = {}
    self.materials = {}

    http.Fetch(impulse.Config.WordPressURL .. "/wp-json/wp/v2/posts?per_page = 4", function(body)
        if ( IsValid(self) ) then
            self:SetupNews(util.JSONToTable(body))
        end
    end, function(error)
        if ( IsValid(self) ) then
            self:Remove()
            logs:Error("Failed to load newsfeed. Error: " .. error)
        end
    end)
end

function PANEL:SetupNews(newsData)
    if ( !newsData ) then
        return logs:Error("Failed to load newsfeed.")
    end

    for v, postData in pairs(newsData) do
        if postData.type == "post" and postData.status == "publish" then
            local image
            if postData.better_featured_image and postData.better_featured_image.media_type == "image" then
                if postData.better_featured_image.media_details.sizes.medium_large then
                    image = postData.better_featured_image.media_details.sizes.medium_large.source_url
                elseif postData.better_featured_image.media_details.sizes.medium then
                    image = postData.better_featured_image.media_details.sizes.medium.source_url
                end
            end

            table.insert(self.news, {postData.id, postData.title.rendered, postData.link, image or impulse.Config.DefaultWordPressImage})
        end
    end

    local firstPost

    for v, postData in pairs(self.news) do
        local postParent = vgui.Create("DPanel", self)
        postParent:DockMargin(0, 0, 0, 0)
        postParent:DockPadding(0, 0, 0, 0)
        postParent:Dock(FILL)
        postParent:SetPaintBackground(true)
        postParent:SetBackgroundColor(Color(20, 20, 20, 255))
        postParent:SetCursor("hand")

        if v == 1 then
            firstPost = postParent
            self.selected = postParent
        end

        if postData[4] then
            local postBackground = vgui.Create("HTML", postParent)
            postBackground:SetPos(-10, -10)
            postBackground:SetSize(self:GetWide() + 20, self:GetTall() + 10)
            postBackground:SetCursor("hand")
            postBackground:SetHTML([[<style type = "text/css">
                body {
                    overflow:hidden;
                }
                </style>
                <img src = "]] .. postData[4] .. [[" style = "width:100%;height:100%;">]])
        end

        local postInfoBackground = vgui.Create("DPanel", postParent)
        postInfoBackground:SetPos(0, self:GetTall() - 60)
        postInfoBackground:SetSize(self:GetWide(), 60)
        postInfoBackground:SetBackgroundColor(Color(10, 10, 10, 190))
        postInfoBackground:SetCursor("hand")

        local title = vgui.Create("DLabel", postParent)
        title:SetPos(10, self:GetTall() - 50)
        title:SetText(postData[2])
        title:SetFont("Impulse-Elements18-Shadow")
        title:SizeToContents()

        local readMore = vgui.Create("DLabel", postParent)
        readMore:SetPos(10, self:GetTall() - 30)
        readMore:SetText("Click to read more...")
        readMore:SetFont("Impulse-Elements18-Shadow")
        readMore:SizeToContents()

        local postButton = vgui.Create("DPanel", postParent)
        postButton:Dock(FILL)
        postButton:SetPaintBackground(false)
        postButton:SetCursor("hand")
        function postButton:OnMousePressed()
            gui.OpenURL(postData[3])
        end

        local selectBtn = vgui.Create("DButton", self)
        selectBtn:SetText("")
        selectBtn:SetSize(16, 16)
        selectBtn:SetPos((self:GetWide() - 100) + (v * 20), self:GetTall() - 18)
        selectBtn.post = postParent
        selectBtn:SetColor(color_white)

        function selectBtn:Think()
            self:MoveToFront()
        end

        local panel = self
        local btnCol = Color(60, 60, 60, 140)
        function selectBtn:Paint(w,h)
            if panel.selected == self.post then
                draw.RoundedBox(0, 0, 0, w, h, impulse.Config.MainColour)
            else
                draw.RoundedBox(0, 0, 0, w, h, btnCol)
            end
        end

        function selectBtn:DoClick()
            self.post:MoveToFront()
            panel.selected = self.post
        end

        firstPost:MoveToFront()
    end
end

local gradient = Material("vgui/gradient-l")
local outlineCol = Color(190, 190, 190, 240)
local darkCol = Color(30, 30, 30, 200)

function PANEL:Paint(w, h)
    surface.SetDrawColor(outlineCol)
    surface.DrawOutlinedRect(0, 0, w, h)

    surface.SetDrawColor(darkCol)
    surface.SetMaterial(gradient)
    surface.DrawTexturedRect(1, 1, w - 1, h - 2)
end

vgui.Register("impulseNewsfeed", PANEL, "DPanel")
*/

-- LEGACY ^

local PANEL = {}

function PANEL:Init()
    self:SetCursor("hand")
    self:Setup()
end

function PANEL:Setup()
    self.container = self:Add("DPanel")
    self.container:Dock(FILL)
    self.container.Paint = function(this, width, height)
        local image = self.image or "impulse-reforged/impulse-reforged-blue-banner-opaque.png"
        if ( string.StartsWith(image, "http") ) then
            return
        end

        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(Material(image, "smooth"))
        surface.DrawTexturedRect(0, 0, width, height)
    end

    self.text = self.container:Add("DPanel")
    self.text:Dock(BOTTOM)
    self.text:SetTall(60)
    self.text.Paint = function(this, width, height)
        surface.SetDrawColor(10, 10, 10, 190)
        surface.DrawRect(0, 0, width, height)
    end

    self.buttons = self:Add("DPanel")
    self.buttons:Dock(BOTTOM)
    self.buttons:SetTall(20)
    self.buttons.Paint = nil

    if ( impulse.Config.WordPressURL != "" ) then
        self.news = {}
        self.materials = {}

        http.Fetch(impulse.Config.WordPressURL .. "/wp-json/wp/v2/posts?per_page=4", function(body)
            if ( IsValid(self) ) then
                self:SetupNews(util.JSONToTable(body))
            end
        end, function(error)
            if ( IsValid(self) ) then
                self:Remove()
                logs:Error("Failed to load newsfeed. Error: " .. error)
            end
        end)
    elseif ( !table.IsEmpty(impulse.Config.SchemaChangelogs) ) then
        local changelog = {}
        -- Get the latest changelog
        for _, data in pairs(impulse.Config.SchemaChangelogs) do
            if ( data.Version == impulse.Config.SchemaVersion ) then
                changelog = data
                break
            end
        end

        for i = 1, #impulse.Config.SchemaChangelogs do
            local button = self.buttons:Add("DButton")
            button:Dock(RIGHT)
            button:DockMargin(2, 2, 0, 2)
            button:SetText("")
            button:SetWide(16)
            button.DoClick = function()
                self.text:Clear()
                self:SetupChangelogs(impulse.Config.SchemaChangelogs[i])
            end
            button.Paint = function(this, width, height)
                if ( impulse.Config.SchemaChangelogs[i].Version == self.version ) then
                    draw.RoundedBox(4, 0, 0, width, height, impulse.Config.MainColour)
                else
                    draw.RoundedBox(4, 0, 0, width, height, Color(60, 60, 60, 140))
                end
            end
        end

        self:SetupChangelogs(changelog)
    else
        self:Remove()
    end
end

function PANEL:SetupNews(data)
end

function PANEL:SetupChangelogs(changelog)
    self.version = changelog.Version or "1.0"

    local parent = self:GetParent()

    local title = self.text:Add("DLabel")
    title:Dock(TOP)
    title:DockMargin(0, 5, 10, 0)
    title:SetFont("Impulse-Elements24")
    title:SetText(changelog.Title or "Changelog")
    title:SizeToContents()
    title:SetContentAlignment(6)

    local descriptionWrapped = impulse.Util:WrapText(changelog.Description or "No description available.", parent:GetWide() - 20, "Impulse-Elements14")
    for _, line in pairs(descriptionWrapped) do
        local descriptionLine = self.text:Add("DLabel")
        descriptionLine:Dock(TOP)
        descriptionLine:DockMargin(10, 0, 10, 0)
        descriptionLine:SetFont("Impulse-Elements14")
        descriptionLine:SetText(line)
        descriptionLine:SizeToContents()
        descriptionLine:SetContentAlignment(6)
    end

    self.image = changelog.Image or "impulse-reforged/impulse-reforged-blue-banner-opaque.png"

    if ( string.StartsWith(self.image, "http") ) then
        http.Fetch(self.image, function(body)
            if ( !IsValid(self) ) then return end

            local image = self.container:Add("DHTML")
            image:Dock(FILL)
            image:SetHTML([[<style type = "text/css">
                body {
                    overflow:hidden;
                    margin:0;
                    padding:0;
                }
                </style>
                <img src = "]] .. self.image .. [[" style = "width:100%;height:100%;">]])
        end)
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("impulseNewsfeed", PANEL, "DPanel")
