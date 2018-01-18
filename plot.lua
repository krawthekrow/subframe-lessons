dofile('./subframe-lessons/CustomTexter.lua')

function string:split(sep)
    local sep, fields = sep or ' ', {}
    local pattern = string.format('([^%s]+)', sep)
    self:gsub(pattern, function(c) table.insert(fields, c) end)
    return fields
end

function intdiv(a, b)
    return (a - a % b) / b;
end

local FONT_DATA = {
    ['5px'] = {
        ['height'] = 5
    },
    ['7px'] = {
        ['height'] = 7
    }
}

local function drawBox(x1, y1, x2, y2, elem, dcolor)
    for i = y1, y2 do
        for j = x1, x2 do
            local partID = sim.partID(j, i)
            if partID == nil then
                partID = sim.partCreate(-1, j, i, elem)
            end
        end
    end
    sim.decoBox(x1, y1, x2, y2,
        bit.band(bit.rshift(dcolor, 4 * 4), 0xff),
        bit.band(bit.rshift(dcolor, 2 * 4), 0xff),
        bit.band(bit.rshift(dcolor, 0 * 4), 0xff),
        bit.band(bit.rshift(dcolor, 6 * 4), 0xff))
end

local sourceFile = ...
io.input('./subframe-lessons/'..sourceFile)
local currX, currY = 0, 0
local currFont = '7px'
local currColor = 0xffffffff
local minTitleX, minTitleY, maxTitleX, maxTitleY = 612, 384, 0, 0
local hasTitle = false
local titleColor = nil
local answerMode = false
local minAnswerX, minAnswerY, maxAnswerX, maxAnswerY
while true do
    local line = io.read()
    if line == nil then break end
    if #line == 0 then
        currY = currY + 2
    elseif string.sub(line, 1, 1) == '#' then
        local firstSpaceIndex = string.find(line, ' ')
        local cmd, arg
        if firstSpaceIndex == nil then
            cmd = string.sub(line, 2, #line)
            arg = ''
        else
            cmd = string.sub(line, 2, firstSpaceIndex - 1)
            arg = string.sub(line, firstSpaceIndex + 1, #line)
        end
        if cmd == 'coord' then
            local args = arg:split(' ')
            currX = args[1]
            currY = args[2]
        elseif cmd == 'color' then
            currColor = tonumber(arg)
        elseif cmd == 'font' then
            currFont = arg
        elseif cmd == 'space' then
            currY = currY + tonumber(arg)
        elseif cmd == 'blackbox' then
            local args = arg:split(' ')
            local x1, y1, x2, y2 = args[1], args[2], args[3], args[4]
            drawBox(x1, y1, x2, y2,
                elements.DEFAULT_PT_COAL, currColor)
        elseif cmd == 'answer' or cmd == 'hint' then
            local function drawAnswerBox()
                local notif
                if cmd == 'answer' then
                    notif = 'DECO OFF TO SEE ANSWER'
                else -- hint
                    notif = 'DECO OFF TO SEE HINT'
                end
                lineWidth = CustomTexter.Tstr(notif,
                    currX, currY, 'DMND', 0x4, 1, 1, '7px',
                    0xff000000).width
                if maxAnswerX - minAnswerX < 150 then
                    maxAnswerX = minAnswerX + 150
                end
                if maxAnswerY - minAnswerY < 10 then
                    maxAnswerY = minAnswerY + 10
                end
                drawBox(minAnswerX, minAnswerY, maxAnswerX, maxAnswerY,
                    elements.DEFAULT_PT_COAL, currColor)
                local answerWidth = maxAnswerX - minAnswerX + 1
                local answerHeight = maxAnswerY - minAnswerY + 1
                local notifX = minAnswerX + intdiv(answerWidth, 2)
                    - intdiv(lineWidth, 2)
                local notifY = minAnswerY + intdiv(answerHeight, 2)
                    - intdiv(FONT_DATA['7px'].height, 2)
                CustomTexter.Tstr(notif,
                    notifX, notifY, 'DMND', 0x2, 1, 1, '7px',
                    0xff000000)
            end
            if arg == '' then
                answerMode = not answerMode
                if answerMode then
                    minAnswerX, minAnswerY, maxAnswerX, maxAnswerY =
                        currX, currY, currX, currY
                else
                    drawAnswerBox()
                end
            else
                local args = arg:split(' ')
                minAnswerX, minAnswerY, maxAnswerX, maxAnswerY =
                    currX, currY,
                    currX + tonumber(args[1]), currY + tonumber(args[2])
                local answerHeight = maxAnswerY - minAnswerY + 1
                drawAnswerBox()
                currY = currY + answerHeight + 5
            end
        elseif cmd == 'title' then
            hasTitle = true
            titleColor = currColor
            lineWidth = CustomTexter.Tstr(string.upper(arg),
                currX, currY, 'DMND', 0x4, 1, 1, '7px', currColor).width
            local titleX = currX - intdiv(lineWidth, 2)
            minTitleX = math.min(minTitleX, titleX)
            minTitleY = math.min(minTitleY, currY)
            maxTitleX = math.max(maxTitleX, titleX + lineWidth - 1)
            maxTitleY =
                math.max(maxTitleY, currY + FONT_DATA[currFont].height)
            CustomTexter.Tstr(string.upper(arg),
                titleX, currY,
                'DMND', 0x2, 1, 1, '7px', currColor)
            currY = currY + FONT_DATA[currFont].height + 5
        elseif cmd == 'section' then
            currY = currY + FONT_DATA[currFont].height
            local lineWidth = CustomTexter.Tstr(string.upper(arg),
                currX, currY, 'DMND', 0x2, 1, 1, currFont, currColor).width;
            local linePos = FONT_DATA[currFont].height + 2
            drawBox(currX, currY + linePos,
                currX + lineWidth, currY + linePos,
                elements.DEFAULT_PT_DMND, currColor)
            currY = currY + FONT_DATA[currFont].height + 7
        else
            error('\''..cmd..'\' is not a valid command.')
        end
    else
        if currFont == '5px' then line = string.upper(line) end
        local lineWidth = CustomTexter.Tstr(line, currX, currY,
            'DMND', 0x2, 1, 1, currFont, currColor).width
        if answerMode then
            minAnswerX = math.min(minAnswerX, currX)
            minAnswerY = math.min(minAnswerY, currY)
            maxAnswerX = math.max(maxAnswerX, currX + lineWidth - 1)
            maxAnswerY = math.max(maxAnswerY,
                currY + FONT_DATA[currFont].height - 1)
        end
        currY = currY + FONT_DATA[currFont].height + 5
    end
end

-- if hasTitle then
--     local paddingX, paddingY = 10, 5
--     local titleBoxX1, titleBoxY1, titleBoxX2, titleBoxY2 =
--         minTitleX - paddingX, minTitleY - paddingY,
--         maxTitleX + paddingX, maxTitleY + paddingY
--     drawBox(titleBoxX1, titleBoxY1, titleBoxX2, titleBoxY1,
--         elements.DEFAULT_PT_DMND, titleColor)
--     drawBox(titleBoxX1, titleBoxY1, titleBoxX1, titleBoxY2,
--         elements.DEFAULT_PT_DMND, titleColor)
--     drawBox(titleBoxX1, titleBoxY2, titleBoxX2, titleBoxY2,
--         elements.DEFAULT_PT_DMND, titleColor)
--     drawBox(titleBoxX2, titleBoxY1, titleBoxX2, titleBoxY2,
--         elements.DEFAULT_PT_DMND, titleColor)
-- end
