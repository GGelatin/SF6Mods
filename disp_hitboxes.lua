local display_hitboxes = true
local display_hurtboxes = true
local display_pushboxes = true
local display_throwboxes = true
local display_throwhurtboxes = true
local display_proximityboxes = true
local display_uniqueboxes = true
local display_properties = true
local display_position = true
local hide_p2 = false
local changed
local gBattle

local reversePairs = function ( aTable )
	local keys = {}

	for k,v in pairs(aTable) do keys[#keys+1] = k end
	table.sort(keys, function (a, b) return a>b end)

	local n = 0

    return function ( )
        n = n + 1
        if n > #keys then return nil, nil end
        return keys[n], aTable[keys[n] ]
    end
end

function bitand(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = math.floor(a/2) -- shift right
      b = math.floor(b/2)
    end
    return result
end

local draw_boxes = function ( work, actParam )
    local col = actParam.Collision
    for j, rect in reversePairs(col.Infos._items) do
        if rect ~= nil then
			local posX = rect.OffsetX.v / 6553600.0
			local posY = rect.OffsetY.v / 6553600.0
			local sclX = rect.SizeX.v / 6553600.0 * 2
            local sclY = rect.SizeY.v / 6553600.0 * 2
			posX = posX - sclX / 2
			posY = posY - sclY / 2

			local screenTL = draw.world_to_screen(Vector3f.new(posX - sclX / 2, posY + sclY / 2, 0))
			local screenTR = draw.world_to_screen(Vector3f.new(posX + sclX / 2, posY + sclY / 2, 0))
			local screenBL = draw.world_to_screen(Vector3f.new(posX - sclX / 2, posY - sclY / 2, 0))
			local screenBR = draw.world_to_screen(Vector3f.new(posX + sclX / 2, posY - sclY / 2, 0))

			if screenTL and screenTR and screenBL and screenBR then
			
				local finalPosX = (screenTL.x + screenTR.x) / 2
				local finalPosY = (screenBL.y + screenTL.y) / 2
				local finalSclX = (screenTR.x - screenTL.x)
				local finalSclY = (screenTL.y - screenBL.y)
				
				-- If the rectangle has a HitPos field, draw it as a hitbox
				if rect:get_field("HitPos") ~= nil then
					-- TypeFlag > 0 indicates a regular hitbox
					if rect.TypeFlag > 0 and display_hitboxes then 
						draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF0040C0)
						draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x600040C0)
						-- Display hitbox properties (each at a unique height)
						-- CondFlag: 262144	(Can ONLY hit a juggled opponent)
						-- CondFlag: 512	(Can't hit behind the player)
						-- CondFlag: 256	(Can't hit in front of the player)
						-- CondFlag: 64		(Can't hit airborne)
						-- CondFlag: 32		(Can't hit crouching opponents)
						-- CondFlag: 16		(Can't hit standing opponent)
						if display_properties then
							if bitand(rect.CondFlag, 512) == 512 then
								draw.text("CantHitBack", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFFFF)
							end
							-- CantHitFront is mutually exclusive with CantHitBack (in theory), so it doesn't need a unique row height
							if bitand(rect.CondFlag, 256) == 256 then
								draw.text("CantHitFront", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFFFF)
							end
							if bitand(rect.CondFlag, 64) == 64 then
								draw.text("CantHitAir", finalPosX, finalPosY + (finalSclY / 2) - 10, 0xFFFFFFFF)
							end
							if bitand(rect.CondFlag, 32) == 32 then
								draw.text("CantHitCrouch", finalPosX, finalPosY + (finalSclY / 2) - 20, 0xFFFFFFFF)
							end
							if bitand(rect.CondFlag, 16) == 16 then
								draw.text("CantHitStanding", finalPosX, finalPosY + (finalSclY / 2) - 30, 0xFFFFFFFF)
							end
							if bitand(rect.CondFlag, 262144) == 262144 then 
								draw.text("JuggleOnly", finalPosX, finalPosY + (finalSclY / 2) - 40, 0xFFFFFFFF)
							end
						end
					-- Throws almost* universally have a TypeFlag of 0 and a PoseBit > 0 
					-- Except for JP's command grab projectile which has neither and must be caught with CondFlag of 0x2C0
					elseif ((rect.TypeFlag == 0 and rect.PoseBit > 0) or rect.CondFlag == 0x2C0) and display_throwboxes then
						draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFD080FF)
						draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60D080FF)
						-- Display throwbox properties (each at a unique height)
						if display_properties then
							if bitand(rect.CondFlag, 512) == 512 then
								draw.text("CantHitBack", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFFFF)
							end
							-- CantHitFront is mutually exclusive with CantHitBack (in theory), so it doesn't need a unique row height
							if bitand(rect.CondFlag, 256) == 256 then
								draw.text("CantHitFront", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFFFF)
							end
							if bitand(rect.CondFlag, 64) == 64 then
								draw.text("CantHitAir", finalPosX, finalPosY + (finalSclY / 2) - 10, 0xFFFFFFFF)
							end
							if bitand(rect.CondFlag, 32) == 32 then
								draw.text("CantHitCrouch", finalPosX, finalPosY + (finalSclY / 2) - 20, 0xFFFFFFFF)
							end
							if bitand(rect.CondFlag, 16) == 16 then
								draw.text("CantHitStanding", finalPosX, finalPosY + (finalSclY / 2) - 30, 0xFFFFFFFF)
							end
							if bitand(rect.CondFlag, 262144) == 262144 then 
								draw.text("JuggleOnly", finalPosX, finalPosY + (finalSclY / 2) - 40, 0xFFFFFFFF)
							end
						end
					-- Any remaining boxes are drawn as proximity boxes
					elseif display_proximityboxes then
						draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF5b5b5b)
						draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x405b5b5b)
					end
				-- If the box contains the Attr field, then it is a pushbox
				elseif rect:get_field("Attr") ~= nil then
					if display_pushboxes then
						draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FFFF)
						draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FFFF)
					end
				-- If the rectangle has a HitNo field, and is not already a hitbox, draw a hurtbox
				elseif rect:get_field("HitNo") ~= nil then
					if display_hurtboxes then
						-- Armor (Type: 1) & Parry (Type: 2) Boxes
						if rect.Type == 2 or rect.Type == 1 then			
							draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0080)
							draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x40FF0080)
						-- All other hurtboxes
						else
							draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FF00)
							draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FF00)
						end
						-- Display properties as text (each at a unique height)
						-- TypeFlag:	1	(Projectile Invuln)
						-- TypeFlag:	2	(Strike Invuln)
						-- Immune:		4	(Air Strike Invuln )
						-- Immune:		11	(Ground Strike Invuln)
						if rect.TypeFlag == 1 and display_properties then
							draw.text("Projectile Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFFFF)
						end
						if rect.TypeFlag == 2 and display_properties then
							draw.text("Full Strike Inv", finalPosX, finalPosY + (finalSclY / 2) - 10, 0xFFFFFFFF)
						end
						if rect.Immune == 4 and display_properties then
							draw.text("Air Strike Inv", finalPosX, finalPosY + (finalSclY / 2) - 20, 0xFFFFFFFF)
						end
						if rect.Immune == 11 and display_properties then
							draw.text("Ground Strike Inv", finalPosX, finalPosY + (finalSclY / 2) - 30, 0xFFFFFFFF)
						end
					end
				-- UniqueBoxes have a special field called KeyData
				elseif rect:get_field("KeyData") ~= nil and display_uniqueboxes then
					draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFEEFF00)
					draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60EEFF00)
				-- Any remaining rectangles are drawn as a grab box
				elseif rect:get_field("KeyData") == nil and display_throwhurtboxes then
					draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0000)
					draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60FF0000)
				end
			end
		end
	end
end

re.on_draw_ui(function()
    if imgui.tree_node("Hitbox Viewer") then
        changed, display_hitboxes = imgui.checkbox("Display Hitboxes", display_hitboxes)
        changed, display_hurtboxes = imgui.checkbox("Display Hurtboxes", display_hurtboxes)
        changed, display_pushboxes = imgui.checkbox("Display Pushboxes", display_pushboxes)
        changed, display_throwboxes = imgui.checkbox("Display Throw Boxes", display_throwboxes)
        changed, display_throwhurtboxes = imgui.checkbox("Display Throw Hurtboxes", display_throwhurtboxes)
        changed, display_proximityboxes = imgui.checkbox("Display Proximity Boxes", display_proximityboxes)
		changed, display_uniqueboxes = imgui.checkbox("Display Unique Boxes", display_uniqueboxes)
		changed, display_properties = imgui.checkbox("Display Properties", display_properties)
		changed, display_position = imgui.checkbox("Display Position", display_position)
        changed, hide_p2 = imgui.checkbox("Hide P2 Boxes", hide_p2)
        imgui.tree_pop()
    end
end)

re.on_frame(function()
    gBattle = sdk.find_type_definition("gBattle")
    if gBattle then
        local sWork = gBattle:get_field("Work"):get_data(nil)
        local cWork = sWork.Global_work
        for i, obj in pairs(cWork) do
            local actParam = obj.mpActParam
            if actParam and not obj:get_IsR0Die() then
                draw_boxes(obj, actParam)
            end
        end
        local sPlayer = gBattle:get_field("Player"):get_data(nil)
        local cPlayer = sPlayer.mcPlayer
        for i, player in pairs(cPlayer) do
            if hide_p2 and i % 2 > 0 then return end
            if i < 2 then
                local worldPos = draw.world_to_screen(Vector3f.new(player.pos.x.v / 6553600.0, player.pos.y.v / 6553600.0, 0))
                if worldPos and display_position then
					draw.filled_circle(worldPos.x, worldPos.y, 10, 0xFFFFFFFF, 10);
				end
            end    
            local actParam = player.mpActParam
            if actParam then
                draw_boxes(player, actParam)
            end
        end
    end
end)
