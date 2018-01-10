-- Version: Unspeakable Crawling Skully

if Texter == nil then
    Texter = {}
end
CustomTexter = {}
CustomTexter._Fonts = {}

------------------ User config zone -------------------
CustomTexter.FONT_FOLDERS_TO_LOAD = {"TexterFonts", "Scripts", "%."}   -- All file will be "dofile" under those foler name, the root dir must be written regex form %.
CustomTexter.DISPLAY_MESSAGES     = false              -- Should show the startup message [true: show, false: don't show]
CustomTexter.FONT_SEARCH_DEPTH    = 3                 -- How deep should texter search the font folder [0: only the root folder]
---------------- User config zone ends ----------------

function CustomTexter.Init(register)
	Texter._Fontmatrix = {}
	CustomTexter._Fonts = {}
	-- Please don't let Texter too far away from font file :)
	local fontFiles = CustomTexter.LoadAllFontsInFolder(".", CustomTexter.FONT_FOLDERS_TO_LOAD, CustomTexter.FONT_SEARCH_DEPTH)
	local msg = ""
	if(Texter._Fontmatrix ~= nil) then
		for fontName in pairs(Texter._Fontmatrix) do
			table.insert(CustomTexter._Fonts, fontName)
		end
		msg = "Texter: "..#fontFiles.." font file(s) loaded, "..#CustomTexter._Fonts.." font(s) available in total."
	else
		msg = "Texter: No font found."
	end
	if( CustomTexter.DISPLAY_MESSAGES ) then
		tpt.log(msg)
	end
end

-- Internal methods
function CustomTexter._IsFolder(path)
	local _isFolder = false
	if(path ~= nil) then
		-- API bug, fixed(ver 86.0)
		-- if( fs.isDirectory(path)  ) then
				-- _isFolder = true
		-- end
		if( fs.isDirectory(path) == fs.isDirectory(".") ) then
			_isFolder = true
		end
	end
	return _isFolder
end
function CustomTexter._GetFontHeight(fontName)
	local height = 0
	if( Texter._Fontmatrix ~= nil and Texter._Fontmatrix[fontName] ~=nil and Texter._Fontmatrix[fontName].height ~= nil  ) then
		height = Texter._Fontmatrix[fontName].height
	else
		height = 7 -- 7 is a lucky number
	end
	return height
end
function CustomTexter._FindAllFile(rootPath, foldersToLoad, depth)
	if(  rootPath == nil  ) then
		rootPath = "."
	end
	if(  depth == nil  ) then
		depth = 1
	end
	local files = {}
	local isTargetFolder = false
	for i, folderName in ipairs(foldersToLoad) do 
		if( string.match(rootPath, "\\?"..folderName.."$") ~= nil ) then
			isTargetFolder = true
			break
		end
	end
	if( isTargetFolder ) then  -- If not the folder we want, ignore it
		files = fs.list(rootPath)
	end
	
	-- Trim match array
	local index = 1 -- Lua fool
	for i=1, #files do
		if( files[index] == "Texter.lua" 
		  or string.match(files[index], "%.texterfont$") == nil
		  or CustomTexter._IsFolder(rootPath.."\\"..files[index]) ) then
			table.remove(files, index)
		else
			files[index] = rootPath.."\\"..files[index] -- full path
			index = index + 1
		end
	end
	
	-- Check subs
	if(  depth > 0  ) then
		local subs = fs.list(rootPath)
		local subFiles = nil
		for i=1, #subs do
			if( CustomTexter._IsFolder(rootPath.."\\"..subs[i]) ) then
				subFiles = CustomTexter._FindAllFile(rootPath.."\\"..subs[i], foldersToLoad, depth - 1)
				CustomTexter._AppendArray(files, subFiles)
			end
		end
	end
	return files
end
function CustomTexter._AppendArray(oriArray, arrayToAppend) -- Append an array to the original array
	if(  oriArray~= nil and arrayToAppend ~= nil and #arrayToAppend>0  ) then
		for i=1, #arrayToAppend do
			table.insert(oriArray, arrayToAppend[i])
		end
	end
	return oriArray
end

-- APIs
function CustomTexter.LoadAllFontsInFolder(rootPath, foldersToLoad, depth) -- Load all fonts in target folder(s)
	local fonts = CustomTexter._FindAllFile(rootPath, foldersToLoad, depth)
	table.insert(fonts, './TexterFonts/5px&7px.texterfont')
	if(  fonts ~= nil  ) then
		for i=1, #fonts do
			dofile(fonts[i])
		end
	end
	return fonts
end
function CustomTexter.Tchar(char, x, y, ptype, mode, fontName, dcolor) -- Draw a single character
	local mtx     = {}
	local letter  = {}
	local PTYPE_MASK  = 0xFF
	local DCOLOR_MASH = 0xFFFFFFFF
	local DCOLOR_OFFSET = 8
	local margin_L = 0 -- margin left
	local margin_R = 0 -- margin right
	local margin_T = 0 -- margin top
	-- if given font not available, use the first available one
	if( fontName == nil or Texter._Fontmatrix[fontName] == nil  ) then
		for font in pairs(Texter._Fontmatrix) do
			fontName = font
			break
		end
	end
	-- if still not available, break
	if( fontName == nil  ) then return 0 end
	
	-- get character data
	letter = Texter._Fontmatrix[fontName][char]
	if( letter == nil  ) then
		letter = Texter._Fontmatrix[fontName]["nil"]
	end
	if( letter == nil  ) then return 0 end -- ["nil"] not defined
	mtx = letter.Mtx
	if( mtx == nil  ) then mtx = {} end
	if( letter.Margin ~= nil  ) then
		if(letter.Margin.Left  ~= nil)then margin_L = letter.Margin.Left  end
		if(letter.Margin.Right ~= nil)then margin_R = letter.Margin.Right end
		if(letter.Margin.Top   ~= nil)then margin_T = letter.Margin.Top   end
	end
	
	local width  = 0
	for i=1, #mtx do --mtx height
		if(#mtx[i] > width)then width = #mtx[i] end
		for j=1, width do
            if bit.band(mode, 4) == 0 then
                local particle = mtx[i][j]
                if( particle~=0  ) then
                    local success = false
                    local p = {}
                    p.ptype  = bit.band(particle                , PTYPE_MASK )
                    -- dcolor shim
                    p.dcolor = dcolor
                    -- bit.band(particle/2^DCOLOR_OFFSET, DCOLOR_MASH) -- bit.rshift can only handle 5 bits :(
                    if( ptype == 0 or ptype == "0" ) then
                        pcall(tpt.delete, x+j-1+margin_L, y+i-1+margin_T) 
                    else
                        -- mode 0 use the given type
                        --     +1 use the font ptype only
                        --     +2 use the font dcolor only
                        if( bit.band(mode, 1) ~= 1 ) then
                            p.ptype = ptype
                        end
                        -- tpt.log("particle is "..particle..", ptype is "..ptype..", to draw is "..p.ptype)-- debug
                        local partID = sim.partID(x+j-1+margin_L, y+i-1+margin_T)
                        if partID == nil then
                            partID = sim.partCreate(-1, x+j-1+margin_L, y+i-1+margin_T, elements['DEFAULT_PT_'..p.ptype])
                        end
                        if( bit.band(mode, 2) == 2 ) then -- Paint it even when failed to create. Because there might be existed particle
                            -- tpt.log("Try to draw dcolor: "..p.dcolor.." ( 0x"..string.format("%X", p.dcolor).." )") --debug
                            sim.partProperty(partID, sim.FIELD_DCOLOUR, p.dcolor)
                            -- pcall(tpt.set_property, "dcolor", p.dcolor, x+j-1+margin_L, y+i-1+margin_T, 1, 1)
                        end
                    end
                end
            end
		end
	end
	width = width + margin_L + margin_R
	return width
end
function CustomTexter.Tstr(str, x, y, ptype, mode, hspacing, vspacing, fontName, dcolor) -- Draw a string
	local ox    = 0
	local oy    = 0
	local oy    = 0
	local fontH = CustomTexter._GetFontHeight(fontName)
	if( mode == nil  ) then
		mode = 0
	end
	if( hspacing == nil  ) then
		hspacing = 1
	end
	if( vspacing == nil  ) then
		vspacing = 3
	end
    local isUnderlined = false
    local firstUnderlinedChar = false
	for i=1,string.len(str) do
        currChar = string.sub(str, i, i)
		if( currChar == "\n"  ) then
			oy = vspacing + oy + fontH
			ox = 0
        elseif currChar == '_' then
            if i < string.len(str) and
                string.sub(str, i+1, i+1) == '_' then
                isUnderlined = not isUnderlined
                if isUnderlined then
                    firstUnderlinedChar = true
                end
            end
		else
            local charWidth = CustomTexter.Tchar(currChar, x+ox, y+oy, ptype, mode, fontName, dcolor)
            if isUnderlined then
                local startJ = 1 - hspacing
                if firstUnderlinedChar then startJ = 1 end
                firstUnderlinedChar = false
                local underlinePadding = 0
                if fontName == '7px' then underlinePadding = 2 end
                for j=startJ,charWidth do
                    local _, partID = pcall(tpt.create, x+ox+j-1, y+oy+fontH+underlinePadding, ptype)
                    if( bit.band(mode, 2) == 2 ) then
                        sim.partProperty(sim.pmap(x+ox+j-1, y+oy+fontH+underlinePadding), sim.FIELD_DCOLOUR, dcolor)
                    end
                end
            end
			ox = hspacing + ox + charWidth
		end
	end
	return {
        ['strlen'] = string.len(str),
        ['width'] = ox - hspacing
    }
end

CustomTexter.Init()
