function CLAMP(x, a, b)
	if (x < a) then
		return a
	end
	if (x > b) then
		return b
	end
	return x
end

---comment
---@param t number
---@return number
function SMOOTHSTEP(t)
	return t * t * (3 - 2 * t)
end

---@param x number
---@return number
function SMOOTHERSTEP(x)
	return x * x * x * (x * (6 * x - 15) + 10);
end

local tile_size_full = 256
local tile_visible_size = 256 / 3
local camera_x = tile_visible_size *220
local camera_y = tile_visible_size *600

---@class TileEdge
---@field edge_start number
---@field edge_end number
---@field height_change number

---@class Tile
---@field id number
---@field material string
---@field left TileEdge
---@field right TileEdge
---@field up TileEdge
---@field down TileEdge

---@type TileEdge
local base_connection = {
	edge_start = 1,
	edge_end = 1,
	height_change = 1
}

---@type Tile
local tile = {
	id = 1,
	material = "GRASS",
	left = base_connection,
	right = base_connection,
	up = base_connection,
	down = base_connection
}

---@type Tile[]
local tiles = {tile}

local current_tile = 1

local screen_x = 1280
local screen_y = 720
local zoom = 2

local screen_cx = screen_x / 2
local screen_cy = screen_y / 2

local camera_shift_x = 0
local camera_shift_y = 0

---@class MovingThing
---@field x number
---@field y number
---@field direction number
---@field speed number
---@field is_ai boolean
---@field size number
---@field scale number
---@field path_length number
---@field progress number
---@field dead boolean

---@type MovingThing[]
local moving_things = {}


function love.load()
	love.window.setMode( 1280, 720, {msaa = 16} )

	do
		---@type MovingThing
		PLAYER = {
			x = camera_x,
			y = camera_y,
			direction = 0,
			speed = 0,
			is_ai = false,
			size = 240,
			scale = 0.5,
			path_length = 0,
			progress = 0,
			dead = false
		}
		table.insert(moving_things, PLAYER)
	end

	for i = 0, 10 do
		---@type MovingThing
		local thing = {
			x = camera_x,
			y = camera_y,
			direction = 0.2,
			speed = 50,
			is_ai = true,
			size = 256,
			scale = 0.2,
			path_length = 0,
			progress = 0,
			dead = false
		}
		table.insert(moving_things, thing)
	end
end

---@class BladeVortexProjectile
---@field angle number
---@field radius number

---@type BladeVortexProjectile[]
local knives = {}

local timer = 0

function love.update(dt)
	timer = timer + dt

	camera_shift_x = PLAYER.x - camera_x
	camera_shift_y = PLAYER.y - camera_y

	local decay = math.exp(-dt * 100)
	camera_x = camera_x + camera_shift_x * decay
	camera_shift_x = camera_shift_x *(1 - decay)
	camera_y = camera_y + camera_shift_y * decay
	camera_shift_y = camera_shift_y *(1 - decay)

	PLAYER.speed = PLAYER.speed * (1 - math.exp(-dt * 2000))

	camera_x = camera_x + dt
	camera_y = camera_y + dt



	if (PLAYER.progress -dt <= 0 and PLAYER.progress > 0) then
		PLAYER.progress = 0
		---@type BladeVortexProjectile
		local knive = {
			angle = 0,
			radius = 0
		}
		table.insert(knives, knive)
	else
		PLAYER.progress = PLAYER.progress - dt
	end

	for index, value in ipairs(knives) do
		local desired_angle = 2 * math.pi / #knives * index + timer * 5
		local desired_radius = 50 + math.sqrt(#knives) * 10

		value.angle = (1 - decay) * value.angle + decay * desired_angle
		value.radius = (1 - decay) * value.radius + decay * desired_radius
	end

	for index, value in ipairs(moving_things) do
		if (value.is_ai) then
			value.direction = value.direction + love.math.random() * dt
		end

		local dx = value.speed * math.cos(value.direction)
		local dy = value.speed * math.sin(value.direction)

		value.x = value.x + dx * dt
		value.y = value.y + dy * dt
		value.path_length = value.path_length + value.speed * dt
	end

	table.sort(moving_things, function (a, b)
		return a.y < b.y
	end)

	for _, value in ipairs(knives) do
		local x = PLAYER.x + math.cos(value.angle) * value.radius
		local y = PLAYER.y + math.sin(value.angle) * value.radius

		for _, target in ipairs(moving_things) do
			if (target.is_ai and not target.dead) then
				if math.abs(x - target.x) + math.abs(y - target.y) < 10 then
					target.dead = true
				end
			end
		end
	end
end

local crossroad = love.graphics.newImage("grass_block.png")
local center_to_right = love.graphics.newImage("grass_block.png")
local bg_image = love.graphics.newImage("cloud.png")
local block_00 = love.graphics.newImage("grass_block_00.png")
local block_11 = love.graphics.newImage("grass_block_11.png")
local tree = love.graphics.newImage("tree.png")
local bush = love.graphics.newImage("bush.png")
local grass = love.graphics.newImage("grass.png")
local block = love.graphics.newImage("grass_block.png")
local water_block = love.graphics.newImage("water_block.png")
local earth_block = love.graphics.newImage("earth_block.png")

local moving_thing = love.graphics.newImage("ball.png")

local map_land = love.image.newImageData("map_land.png")

local current_height = 1

local map_x = map_land:getWidth()
local map_y = map_land:getHeight()

SPRITE_ROGUE_MOVE_FORWARD_1 = love.graphics.newImage("rogue/forward-1.png")
SPRITE_ROGUE_MOVE_FORWARD_2 = love.graphics.newImage("rogue/forward-2.png")
SPRITE_ROGUE_MOVE_FORWARD_LEFT_1 = love.graphics.newImage("rogue/forward-left-1.png")
SPRITE_ROGUE_MOVE_FORWARD_LEFT_2 = love.graphics.newImage("rogue/forward-left-2.png")
SPRITE_ROGUE_MOVE_LEFT_1 = love.graphics.newImage("rogue/left-1.png")
SPRITE_ROGUE_MOVE_LEFT_2 = love.graphics.newImage("rogue/left-2.png")
SPRITE_ROGUE_MOVE_BACK_LEFT_1 = love.graphics.newImage("rogue/back-left-1.png")
SPRITE_ROGUE_MOVE_BACK_LEFT_2 = love.graphics.newImage("rogue/back-left-2.png")
SPRITE_ROGUE_MOVE_BACK_1 = love.graphics.newImage("rogue/back-1.png")
SPRITE_ROGUE_MOVE_BACK_2 = love.graphics.newImage("rogue/back-2.png")
SPRITE_ROGUE_ATTACK = love.graphics.newImage("rogue/attack.png")


local function draw_tile(x, y)
	if (x < 0) then return end
	if (y < 0) then return end
	if (x >= map_x) then return end
	if (y >= map_y) then return end
	local land_r, _, _, _ = map_land:getPixel(x, y)
	local tile_x_shift = x * tile_visible_size - camera_x
	local tile_y_shift = y * tile_visible_size - camera_y
	if land_r == 0 then
		love.graphics.draw(earth_block, screen_cx + tile_x_shift * zoom, screen_cy + tile_y_shift * zoom, 0, zoom, zoom)
	else
		love.graphics.draw(water_block, screen_cx + tile_x_shift * zoom, screen_cy + tile_y_shift * zoom, 0, zoom, zoom)
	end
end

local function draw_grass(x, y)
	if (x < 0) then return end
	if (y < 0) then return end
	if (x >= map_x) then return end
	if (y >= map_y) then return end
	local land_r, _, _, _ = map_land:getPixel(x, y)
	if land_r ~= 0 then return end

	do
		local tile_x_shift = (x + love.math.random() - 0.5) * tile_visible_size - camera_x
		local tile_y_shift = y * tile_visible_size - camera_y
		if (love.math.random() < 0.7) then
			love.graphics.draw(
				grass,
				screen_cx + tile_x_shift * zoom,
				screen_cy + tile_y_shift * zoom,
				0,
				zoom,
				zoom
			)
		end
	end
end

local function draw_trees(x, y)
	if (x < 0) then return end
	if (y < 0) then return end
	if (x >= map_x) then return end
	if (y >= map_y) then return end
	local land_r, _, _, _ = map_land:getPixel(x, y)
	if land_r ~= 0 then return end

	love.math.setRandomSeed(bit.bxor(x * 3, y * 3))

	do
		local tile_x_shift = (x + love.math.random() - 0.5) * tile_visible_size - camera_x
		local tile_y_shift = (y - 0.5) * tile_visible_size - camera_y
		if (love.math.random() < 0.1) then
			love.graphics.draw(
				bush,
				screen_cx + tile_x_shift * zoom,
				screen_cy + tile_y_shift * zoom,
				0,
				zoom,
				zoom
			)
		end
	end

	do
		local tile_x_shift = (x + love.math.random() - 0.5) * tile_visible_size - camera_x
		local tile_y_shift = (y - 0.5) * tile_visible_size - camera_y
		if (love.math.random() < 0.05) then
			love.graphics.draw(
				tree,
				screen_cx + tile_x_shift * zoom,
				screen_cy + tile_y_shift * zoom,
				0,
				zoom,
				zoom
			)
		end
	end
end

local function draw_trees_between(up, bottom)
	local camera_tile_x = math.floor(camera_x / tile_visible_size)
	local camera_tile_y = math.floor(camera_y / tile_visible_size)

	for i = camera_tile_x - 9, camera_tile_x + 8 do
		for j = math.max(camera_tile_y - 8, math.floor(up) - 1), math.min(camera_tile_y + 8, math.floor(bottom) + 1) do
			for z = 0, 3 do
				if
					(j + z / 3+ 0.5) > up
					and (j + z / 3 + 0.5) < bottom
				then
					draw_trees(i, j + z /3)
				end
			end
		end
	end
end


local function draw_things()
	local camera_tile_x = math.floor(camera_x / tile_visible_size)
	local camera_tile_y = math.floor(camera_y / tile_visible_size)

	--- tiles are under everything
	for i = camera_tile_x - 9, camera_tile_x + 8 do
		for j = camera_tile_y - 8, camera_tile_y + 8 do
			draw_tile(i, j)
		end
	end

	for i = camera_tile_x - 9, camera_tile_x + 8 do
		for j = camera_tile_y - 8, camera_tile_y + 8 do
			love.math.setRandomSeed(bit.bxor(i, j + 31524232))
			for z = 0, 3 do
				draw_grass(i, j + z /3)
			end
		end
	end


	local prev_y = 0 / tile_visible_size
	for index, value in ipairs(moving_things) do
		local next_y = value.y / tile_visible_size - 0.5
		draw_trees_between(prev_y, next_y)
		prev_y = next_y
		local x_shift = value.x - camera_x
		local y_shift = value.y - camera_y
		if (value.is_ai and not value.dead) then
			love.graphics.draw(
				moving_thing,
				screen_cx + (x_shift - value.size * value.scale / 2) * zoom,
				screen_cy + (y_shift  - value.size * value.scale)* zoom,
				0,
				zoom * value.scale,
				zoom * value.scale
			)
		end

		local x = value.x - camera_x + screen_cx
		local y = value.y - camera_y + screen_cy
		local dx = math.cos(value.direction)
		local dy = math.sin(value.direction)
		local step = math.floor((value.path_length % 30) / 15)

		if (not value.is_ai) then
			if value.progress and value.progress > 0 then
				if math.cos(value.direction) >= 0 then
						love.graphics.draw(
							SPRITE_ROGUE_ATTACK,
							x - 30, y - 60, 0, 0.25, 0.25
						)
					else
						love.graphics.draw(
							SPRITE_ROGUE_ATTACK,
							x + 30, y - 60, 0, -0.25, 0.25
						)
					end
			elseif dx > math.abs(dy) * 2 then
				-- right
				if step == 0 then
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_LEFT_1,
						60 + x - 30, y - 60, 0, -0.25, 0.25
					)
				else
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_LEFT_2,
						60 + x - 30, y - 60, 0, -0.25, 0.25
					)
				end
			elseif -dx > math.abs(dy) * 2 then
				-- left
				if step == 0 then
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_LEFT_1,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				else
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_LEFT_2,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				end
			elseif dy > 2 * math.abs(dx) then
				-- forward
				if step == 0 then
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_FORWARD_1,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				else
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_FORWARD_2,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				end
			elseif -dy > 2 * math.abs(dx) then
				-- back
				if step == 0 then
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_BACK_1,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				else
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_BACK_2,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				end
			elseif 2 * dy > math.abs(dx) and dx < 0 then
				-- forward left
				if step == 0 then
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_FORWARD_LEFT_1,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				else
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_FORWARD_LEFT_2,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				end
			elseif 2 * dy > math.abs(dx) and dx > 0 then
				-- forward right
				if step == 0 then
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_FORWARD_LEFT_1,
						60 + x - 30, y - 60, 0, -0.25, 0.25
					)
				else
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_FORWARD_LEFT_2,
						60 + x - 30, y - 60, 0, -0.25, 0.25
					)
				end
			elseif -2 * dy > math.abs(dx) and dx > 0 then
				-- back right
				if step == 0 then
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_BACK_LEFT_1,
						60 + x - 30, y - 60, 0, -0.25, 0.25
					)
				else
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_BACK_LEFT_2,
						60 + x - 30, y - 60, 0, -0.25, 0.25
					)
				end
			elseif -2 * dy > math.abs(dx) and dx < 0 then
				-- back left
				if step == 0 then
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_BACK_LEFT_1,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				else
					love.graphics.draw(
						SPRITE_ROGUE_MOVE_BACK_LEFT_2,
						x - 30, y - 60, 0, 0.25, 0.25
					)
				end
			end
		end
	end
	draw_trees_between(prev_y, map_y)

	for index, value in ipairs(knives) do
		local x = PLAYER.x + math.cos(value.angle) * value.radius - camera_x + screen_cx
		local y = PLAYER.y + math.sin(value.angle) * value.radius - camera_y + screen_cy

		love.graphics.circle("fill", x, y, 5)
	end
end






function love.draw()
	love.graphics.clear(0.7, 0.82, 0.86, 1.0)

	draw_things()

	--[[

	--]]

	--[[
	for height_level = 0, 10 do
		for i = -10, 10 do
			for j = -10, 10 do
				local random_shift_x = love.math.random(256)
				local random_shift_y = love.math.random(256)
				local scale = 1 / (current_height + 2 - height_level / 10)

				love.graphics.draw(
					bg_image,
					screen_cx - (camera_x + 1.3 * i * 256 + random_shift_x)* scale,
					screen_cy - (camera_y + 1.3 * j * 256 + random_shift_y)* scale,
					0,
					scale,
					scale
				)
			end
		end
	end

	local local_tile = tiles[current_tile]
	love.graphics.draw(center_to_right, screen_cx -camera_x, screen_cy-camera_y)
	love.graphics.draw(block_11, screen_cx -camera_x, screen_cy-camera_y + 256 / 3)
	love.graphics.draw(crossroad, screen_cx -camera_x + 256 / 3, screen_cy-camera_y)
	love.graphics.draw(crossroad, screen_cx -camera_x + 256 / 3, screen_cy-camera_y + 256 / 3)
	love.graphics.draw(block_00, screen_cx -camera_x + 256 / 3 + 256 / 3, screen_cy-camera_y)
	love.graphics.draw(crossroad, screen_cx -camera_x + 256 / 3 + 256 / 3, screen_cy-camera_y + 256 / 3)
	love.graphics.draw(crossroad, screen_cx -camera_x + 256 / 3 + 256 / 3 + 256 / 3, screen_cy-camera_y + 256 / 3)


	love.graphics.draw(grass, screen_cx -camera_x + 500 / 3 / 2, screen_cy-camera_y + 50 / 3 / 2)
	love.graphics.draw(grass, screen_cx -camera_x + 1200 / 3 / 2, screen_cy-camera_y + 256 / 3)

	love.graphics.draw(bush, screen_cx -camera_x + 12 / 3 / 2, screen_cy-camera_y + 30 / 3 / 2)
	love.graphics.draw(tree, screen_cx -camera_x + 256 / 3 / 2, screen_cy-camera_y + 256 / 3 / 2)
	love.graphics.draw(bush, screen_cx -camera_x + 136 / 3 / 2, screen_cy-camera_y + 406 / 3 / 2)
	love.graphics.draw(bush, screen_cx -camera_x + 656 / 3 / 2, screen_cy-camera_y + 306 / 3 / 2)
	love.graphics.draw(tree, screen_cx -camera_x + 885 / 3 / 2, screen_cy-camera_y + 657 / 3 / 2)
	--]]
end

function love.mousepressed(x, y, button, istouch, presses)
	local shift_x = camera_x + x - screen_cx - PLAYER.x
	local shift_y = camera_y + y - screen_cy - PLAYER.y

	PLAYER.direction = math.atan2(shift_y, shift_x)
	PLAYER.speed = 100
end

function love.keypressed(key, scancode, isrepeat)
	if key == "q" then
		PLAYER.progress = 0.5
	end
end