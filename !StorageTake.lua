local sampev = require 'samp.events'
local imgui = require 'mimgui'
local ffi = require 'ffi'
local encoding = require 'encoding'

local config = {}
do
    local DIR = getWorkingDirectory() .. '\\config\\'

    local function filePath(name)
        return DIR .. name .. '.json'
    end

    local function readFile(path)
        local file = io.open(path, 'rb')
        if not file then return nil end
        local text = file:read('*a')
        file:close()
        return text
    end

    local function writeFile(path, text)
        local file = io.open(path, 'wb')
        if not file then return false end
        file:write(text)
        file:close()
        return true
    end

    local function copy(value)
        if type(value) ~= 'table' then return value end
        local result = {}
        for k, v in pairs(value) do result[k] = copy(v) end
        return result
    end

    local function merge(defaults, source)
        local result = {}
        for key, default in pairs(defaults) do
            local value = source and source[key]
            if type(default) == 'table' then
                local isDict = next(default) ~= nil and #default == 0
                if type(value) == 'table' then
                    result[key] = isDict and merge(default, value) or copy(value)
                else
                    result[key] = copy(default)
                end
            elseif type(value) == type(default) then
                result[key] = value
            else
                result[key] = default
            end
        end
        return result
    end

    function config.save(name, data)
        if not doesDirectoryExist(DIR) then createDirectory(DIR) end
        return writeFile(filePath(name), encodeJson(data))
    end

    function config.load(name, defaults, legacy)
        local text = readFile(filePath(name))
        local source = text and decodeJson(text)
        local fresh = type(source) ~= 'table'
        if fresh and legacy then
            local ok, migrated = pcall(legacy)
            source = ok and migrated or nil
        end
        local data = merge(defaults, type(source) == 'table' and source or nil)
        if fresh then config.save(name, data) end
        return data
    end
end

local theme = {}
do
    local V4 = imgui.ImVec4

    local COLORS = {
        WindowBg = V4(0.10, 0.10, 0.10, 1.00),
        ChildBg = V4(0.14, 0.14, 0.14, 1.00),
        PopupBg = V4(0.12, 0.12, 0.12, 1.00),
        Border = V4(0.43, 0.43, 0.50, 0.50),
        BorderShadow = V4(0.00, 0.00, 0.00, 0.00),
        FrameBg = V4(0.20, 0.20, 0.20, 1.00),
        FrameBgHovered = V4(0.30, 0.30, 0.30, 1.00),
        FrameBgActive = V4(0.25, 0.25, 0.25, 1.00),
        TitleBg = V4(0.10, 0.10, 0.10, 1.00),
        TitleBgActive = V4(0.10, 0.10, 0.10, 1.00),
        TitleBgCollapsed = V4(0.00, 0.00, 0.00, 0.51),
        MenuBarBg = V4(0.14, 0.14, 0.14, 1.00),
        ScrollbarBg = V4(0.02, 0.02, 0.02, 0.53),
        ScrollbarGrab = V4(0.31, 0.31, 0.31, 1.00),
        ScrollbarGrabHovered = V4(0.41, 0.41, 0.41, 1.00),
        ScrollbarGrabActive = V4(0.51, 0.51, 0.51, 1.00),
        CheckMark = V4(0.26, 0.59, 0.98, 1.00),
        SliderGrab = V4(0.24, 0.52, 0.88, 1.00),
        SliderGrabActive = V4(0.26, 0.59, 0.98, 1.00),
        Button = V4(0.20, 0.20, 0.20, 1.00),
        ButtonHovered = V4(0.28, 0.28, 0.28, 1.00),
        ButtonActive = V4(0.18, 0.18, 0.18, 1.00),
        Header = V4(0.26, 0.59, 0.98, 0.31),
        HeaderHovered = V4(0.26, 0.59, 0.98, 0.80),
        HeaderActive = V4(0.26, 0.59, 0.98, 1.00),
        Separator = V4(0.43, 0.43, 0.50, 0.50),
        SeparatorHovered = V4(0.10, 0.40, 0.75, 0.78),
        SeparatorActive = V4(0.10, 0.40, 0.75, 1.00),
        ResizeGrip = V4(0.26, 0.59, 0.98, 0.25),
        ResizeGripHovered = V4(0.26, 0.59, 0.98, 0.67),
        ResizeGripActive = V4(0.26, 0.59, 0.98, 0.95),
        Tab = V4(0.18, 0.35, 0.58, 0.86),
        TabHovered = V4(0.26, 0.59, 0.98, 0.80),
        TabActive = V4(0.20, 0.41, 0.68, 1.00),
        TabUnfocused = V4(0.07, 0.10, 0.15, 0.97),
        TabUnfocusedActive = V4(0.14, 0.26, 0.42, 1.00),
        Text = V4(1.00, 1.00, 1.00, 1.00),
        TextDisabled = V4(0.50, 0.50, 0.50, 1.00),
    }

    theme.color = {
        Green = V4(0.4, 1.0, 0.4, 1.0),
        Red = V4(1.0, 0.4, 0.4, 1.0),
        Orange = V4(1.0, 0.8, 0.2, 1.0),
        Gray = V4(0.5, 0.5, 0.5, 1.0),
        LightGray = V4(0.7, 0.7, 0.7, 1.0),
        Cash = V4(0.35, 0.95, 0.35, 1.0),
        Blue = V4(0.26, 0.59, 0.98, 1.0),
        Gold = V4(1.0, 0.84, 0.0, 1.0),
    }

    theme.button = {
        green = {V4(0.25, 0.6, 0.3, 1), V4(0.32, 0.7, 0.38, 1), V4(0.2, 0.5, 0.25, 1)},
        blue = {V4(0.25, 0.45, 0.7, 1), V4(0.32, 0.55, 0.8, 1), V4(0.2, 0.38, 0.6, 1)},
        red = {V4(0.6, 0.2, 0.2, 1), V4(0.75, 0.28, 0.28, 1), V4(0.5, 0.15, 0.15, 1)},
        purple = {V4(0.4, 0.4, 0.8, 1), V4(0.5, 0.5, 0.9, 1), V4(0.33, 0.33, 0.7, 1)},
        ghost = {V4(0.5, 0.5, 0.5, 0.25), V4(0.5, 0.5, 0.5, 0.45), V4(0.5, 0.5, 0.5, 0.6)},
    }

    function theme.apply()
        local style = imgui.GetStyle()
        style.WindowRounding = 10.0
        style.ChildRounding = 8.0
        style.FrameRounding = 6.0
        style.PopupRounding = 8.0
        style.ScrollbarRounding = 6.0
        style.GrabRounding = 6.0
        style.TabRounding = 6.0
        style.FrameBorderSize = 1.0
        for name, value in pairs(COLORS) do
            if imgui.Col[name] then style.Colors[imgui.Col[name]] = value end
        end
    end

    function theme.pushButton(kind)
        local c = theme.button[kind]
        imgui.PushStyleColor(imgui.Col.Button, c[1])
        imgui.PushStyleColor(imgui.Col.ButtonHovered, c[2])
        imgui.PushStyleColor(imgui.Col.ButtonActive, c[3])
    end

    function theme.popButton()
        imgui.PopStyleColor(3)
    end

    function theme.coloredButton(kind, label, size)
        theme.pushButton(kind)
        local pressed = imgui.Button(label, size)
        theme.popButton()
        return pressed
    end

    function theme.u32(color)
        return imgui.ColorConvertFloat4ToU32(color)
    end
end

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local cfg = config.load('StorageTake', {blacklist = {}})

local S = {
    storageJson = u8:decode('"title":"Хранилище"'),
    menuTitle = u8:decode('Хранилище предметов'),
    mainStorage = u8:decode('Основное хранилище предметов'),
    itemTitle = u8:decode('Хранилище'),
    itemLabel = u8:decode('Предмет:'),
    itemPattern = u8:decode('Предмет:%s*(.-)%s*%((%d+)%s*шт%.%)'),
    itemPatternLoose = u8:decode('Предмет:%s*(.-)%s*$'),
    takeOne = u8:decode('Забрать предмет'),
    allWord = u8:decode('все'),
    quantityAsk = u8:decode('Введите количество'),
    quantityTake = u8:decode('забрать'),
    taken = u8:decode('Вы забрали предмет'),
    cost = u8:decode('Стоимость услуги составила :CASH:([%d%.]+)'),
    empty = u8:decode('В Вашем хранилище нет предметов'),
    noMoney = u8:decode('недостаточно наличных'),
    noSpace = u8:decode('нет свободных мест в инвентаре'),
    trashOne = u8:decode('Выбросить предмет'),
    trashConfirm = u8:decode('избавиться от выбранного предмета'),
}

local DELAY = {
    pause = 850,
    respond = 30,
    tile = 150,
}
local TIMEOUT = {
    dialog = 1.2,
    confirm = 3.0,
    reopen = 3.0,
    reopenWait = 2.5,
    openCommand = 4.0,
    skipClose = 1.5,
}
local ATTEMPTS = 5
local RECENT_LIMIT = 40

local function chat(text)
    sampAddChatMessage(u8:decode('{66CCFF}[StorageTake]{FFFFFF} ' .. text), -1)
end

local function stripColors(s)
    return (s:gsub('{%x%x%x%x%x%x}', ''))
end

local function trim(s)
    return (s:match('^%s*(.-)%s*$'))
end

local function lines(text)
    local result = {}
    for line in (text .. '\n'):gmatch('(.-)\n') do result[#result + 1] = line end
    return result
end

local function firstColumn(s)
    return s:match('^[^\t]*') or s
end

local function lowerCp1251(s)
    return (s:lower():gsub('[\192-\223]', function(c) return string.char(c:byte() + 32) end):gsub('\168', '\184'))
end

local function money(n)
    local s, count = tostring(math.floor(n or 0))
    repeat s, count = s:gsub('^(%d+)(%d%d%d)', '%1.%2') until count == 0
    return s
end

local function isBlacklisted(name)
    local low = lowerCp1251(name)
    for _, entry in ipairs(cfg.blacklist) do
        local needle = lowerCp1251(u8:decode(entry))
        if needle ~= '' and low:find(needle, 1, true) then return true end
    end
    return false
end

local function addToBlacklist(text)
    text = trim(text or '')
    if text == '' then return end
    for _, entry in ipairs(cfg.blacklist) do
        if entry == text then return end
    end
    table.insert(cfg.blacklist, text)
    config.save('StorageTake', cfg)
end

local function removeFromBlacklist(index)
    table.remove(cfg.blacklist, index)
    config.save('StorageTake', cfg)
end

local recent = {}

local function rememberRecent(name)
    name = u8(name)
    for i = #recent, 1, -1 do
        if recent[i] == name then table.remove(recent, i) end
    end
    table.insert(recent, 1, name)
    while #recent > RECENT_LIMIT do table.remove(recent) end
end

local function sendCef(message)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #message)
    raknetBitStreamWriteString(bs, message)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

local function emulateCef(code)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt16(bs, #code)
    raknetBitStreamWriteInt8(bs, 0)
    raknetBitStreamWriteString(bs, code)
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end

local function readIncomingCef(bs)
    raknetBitStreamIgnoreBits(bs, 8)
    if raknetBitStreamReadInt8(bs) ~= 17 then return nil end
    raknetBitStreamIgnoreBits(bs, 32)
    local length = raknetBitStreamReadInt16(bs)
    if length < 0 then length = length + 65536 end
    local encoded = raknetBitStreamReadInt8(bs)
    if encoded ~= 0 then return raknetBitStreamDecodeString(bs, length + encoded) end
    return raknetBitStreamReadString(bs, length)
end

local function readOutgoingCef(bs)
    raknetBitStreamIgnoreBits(bs, 8)
    local sub = raknetBitStreamReadInt8(bs)
    if sub == 18 then
        return 'message', raknetBitStreamReadString(bs, raknetBitStreamReadInt16(bs))
    elseif sub == 0 and raknetBitStreamReadInt8(bs) == 27 then
        return 'escape'
    end
end

local function peek(bs, reader)
    local start = raknetBitStreamGetReadOffset(bs)
    local result = {pcall(reader, bs)}
    raknetBitStreamSetReadOffset(bs, start)
    if not result[1] then return nil end
    return unpack(result, 2)
end

local REMOVE_LEGACY_BUTTON = "(function(){var S=window.__stakeTile;if(S&&S.timer){clearInterval(S.timer);S.timer=null;}var o=document.getElementById('stake_btn');if(o)o.remove();var t=document.getElementById('stake_tile');if(t)t.remove();})();"

local TILE_ID = -2
local ARZMARKET_TILE = u8:decode('{"id":-1,"title":"ArzMarket","img":"8680","color":-969606913,"currency":"Забрать все предметы.","price":" "},')

local function signed32(value)
    if value >= 2147483648 then value = value - 4294967296 end
    return string.format('%d', value)
end

local function tileJson(active)
    return u8:decode(string.format(
        '{"id":%d,"title":"StorageTake","img":"8680","color":%s,"currency":"%s","price":" "},',
        TILE_ID,
        signed32(active and 0xE74C3CFF or 0x2ECC71FF),
        active and 'Остановить забор.' or 'Забрать по фильтру.'))
end

local function arzMarketLoaded()
    local ok, scripts = pcall(script.list)
    if not ok or type(scripts) ~= 'table' then return false end
    for _, s in ipairs(scripts) do
        local found, id = pcall(function()
            return (tostring(s.name) .. '|' .. tostring(s.filename) .. '|' .. tostring(s.path)):lower()
        end)
        if found and id:find('arzmarket', 1, true) then return true end
    end
    return false
end

local view = {storage = false, autoMain = false, seq = 0, openedAt = 0}
local run = {active = false, gen = 0, cursor = 0, taken = 0, skipped = 0, trashed = 0, spent = 0, fails = 0, reason = '', awaitDialog = false, lastCount = nil}
local event = {dialog = nil, taken = false, trashed = false, trashPending = false}
local refreshTile = false

local function stopRun(reason)
    if not run.active then return end
    run.active = false
    run.awaitDialog = false
    view.autoMain = false
    run.reason = reason
    chat(string.format('%s | забрано: %d, пропущено: %d, выброшено: %d, потрачено: $%s',
        reason, run.taken, run.skipped, run.trashed, money(run.spent)))
    refreshTile = true
end

local function alive(gen)
    return run.active and run.gen == gen
end

local function waitFor(gen, condition, timeout)
    local deadline = os.clock() + timeout
    while os.clock() < deadline do
        if not alive(gen) then return false end
        if condition() then return true end
        wait(0)
    end
    return condition()
end

local function ensureStorageOpen(gen, immediate)
    if view.storage then return true end
    if not immediate and waitFor(gen, function() return view.storage end, TIMEOUT.reopenWait) then return true end
    if not alive(gen) then return false end

    local seq = view.seq
    view.autoMain = true
    sampSendChat('/storage')
    local opened = waitFor(gen, function() return view.seq ~= seq end, TIMEOUT.openCommand)
    view.autoMain = false
    return opened
end

local function awaitConfirmation(gen, flag, seqBefore, failReason)
    if waitFor(gen, function() return event[flag] end, TIMEOUT.confirm) then
        run.fails = 0
        waitFor(gen, function() return view.seq ~= seqBefore end, TIMEOUT.reopen)
        return true, true
    end
    if not alive(gen) then return false end
    run.fails = run.fails + 1
    if run.fails >= 3 then
        stopRun(failReason)
        return false
    end
    return true, false
end

local function processItem(gen)
    local seqBefore = view.seq
    event.dialog, event.taken, event.trashed, event.trashPending = nil, false, false, false

    run.awaitDialog = true
    local gotDialog = false
    for _ = 1, ATTEMPTS do
        if not view.storage then break end
        sendCef('mountain.testDrive.selectVehicle|' .. run.cursor)
        gotDialog = waitFor(gen, function() return event.dialog ~= nil end, TIMEOUT.dialog)
        if gotDialog or not alive(gen) then break end
    end
    run.awaitDialog = false
    if not alive(gen) then return false end

    if not gotDialog then
        if not view.storage then return true end
        stopRun(run.cursor == 0 and run.taken == 0 and 'Хранилище пустое' or 'Готово: дошли до конца списка')
        return false
    end

    if event.dialog == 'take' then
        return (awaitConfirmation(gen, 'taken', seqBefore, 'Сервер не подтверждает забор, остановка'))
    elseif event.dialog == 'trash' then
        local continue, confirmed = awaitConfirmation(gen, 'trashed', seqBefore, 'Сервер не подтверждает выброс, остановка')
        if confirmed then
            run.trashed = run.trashed + 1
        elseif continue then
            event.trashPending = false
        end
        return continue
    end

    run.cursor = run.cursor + 1
    run.skipped = run.skipped + 1
    waitFor(gen, function() return not view.storage end, TIMEOUT.skipClose)
    return true, true
end

local function runLoop(gen)
    local skipped = false
    while alive(gen) do
        if not ensureStorageOpen(gen, skipped) then
            if alive(gen) then stopRun('Не удалось открыть хранилище (/storage)') end
            break
        end
        skipped = false

        wait(DELAY.pause)
        if not alive(gen) then break end

        if view.storage then
            local continue, wasSkipped = processItem(gen)
            if not continue then break end
            skipped = wasSkipped == true
        end
    end
    if run.gen == gen then refreshTile = true end
end

local function startRun()
    if run.active then return end
    run.active = true
    run.gen = run.gen + 1
    run.cursor, run.taken, run.skipped, run.trashed, run.spent, run.fails = 0, 0, 0, 0, 0, 0
    run.reason = ''
    run.lastCount = nil
    event.trashPending = false
    chat('старт. В чёрном списке: ' .. #cfg.blacklist .. ' шт. (будут выброшены). ESC — остановить.')
    refreshTile = true
    lua_thread.create(runLoop, run.gen)
end

local function toggleRun()
    if run.active then stopRun('Остановлено вручную') else startRun() end
end

local function respond(id, button, item, input)
    lua_thread.create(function()
        wait(DELAY.respond)
        sampSendDialogResponse(id, button, item, input)
    end)
end

local function injectTile(packet)
    local at = packet:find('{"id":0,', 1, true)
    if not at then return end
    local withArz = arzMarketLoaded()
    local list = packet:sub(1, at - 1) .. (withArz and ARZMARKET_TILE or '') .. tileJson(run.active) .. packet:sub(at)
    if withArz then
        lua_thread.create(function()
            wait(DELAY.tile)
            pcall(emulateCef, list)
        end)
        return false
    end
    if pcall(emulateCef, list) then return false end
end

addEventHandler('onReceivePacket', function(id, bs)
    if id ~= 220 then return end
    local packet = peek(bs, readIncomingCef)
    if not packet then return end

    if packet:find('event.mountain.testDrive.initializeText', 1, true) and packet:find(S.storageJson, 1, true) then
        view.storage = true
        view.seq = view.seq + 1
        view.openedAt = os.clock()
        refreshTile = true
    elseif packet:find('event.mountain.testDrive.addVehicles', 1, true) and view.storage
        and os.clock() - view.openedAt < 1.5
        and not packet:find('"id":' .. TILE_ID .. ',', 1, true) then
        return injectTile(packet)
    elseif packet:find('event.setActiveView', 1, true) then
        if (packet:find('null', 1, true) or not packet:find('MountainTestDrive', 1, true)) and view.storage then
            view.storage = false
            refreshTile = true
        end
    end
end)

addEventHandler('onSendPacket', function(id, bs)
    if id ~= 220 then return end
    local kind, message = peek(bs, readOutgoingCef)
    if kind == 'message' and message and (message:find('selectVehicle|' .. TILE_ID, 1, true) or message:find('stakeAction|', 1, true)) then
        toggleRun()
        return false
    elseif kind == 'escape' and run.active then
        stopRun('Остановлено (ESC)')
    end
end)

local function parseItemDialog(rows)
    local item = {}
    for i, line in ipairs(rows) do
        local row = stripColors(line)
        if not item.trashIndex and row:find(S.trashOne, 1, true) then
            item.trashIndex, item.trashText = i - 1, firstColumn(row)
        end
        if not item.name and row:find(S.itemLabel, 1, true) then
            item.name, item.count = row:match(S.itemPattern)
            item.name = item.name or row:match(S.itemPatternLoose)
        end
        if not item.takeIndex and row:find(S.takeOne, 1, true) and not row:find(S.allWord, 1, true) then
            item.takeIndex, item.takeText = i - 1, firstColumn(row)
        end
    end
    return item
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    title = trim(stripColors(title or ''))
    text = text or ''
    local rows = lines(text)

    if (view.autoMain or run.active) and title:find(S.menuTitle, 1, true) then
        for i, line in ipairs(rows) do
            local row = stripColors(line)
            if row:find(S.mainStorage, 1, true) then
                view.autoMain = false
                respond(id, 1, i - 1, firstColumn(row))
                return false
            end
        end
    end

    if title == S.itemTitle then
        local item = parseItemDialog(rows)
        if item.name and item.name ~= '' then rememberRecent(item.name) end

        if run.active and run.awaitDialog then
            run.awaitDialog = false
            run.lastCount = tonumber(item.count)
            local blacklisted = item.name and isBlacklisted(item.name)
            if blacklisted and item.trashIndex then
                event.dialog = 'trash'
                event.trashPending = true
                respond(id, 1, item.trashIndex, item.trashText)
            elseif item.name and not blacklisted and item.takeIndex then
                event.dialog = 'take'
                respond(id, 1, item.takeIndex, item.takeText)
            else
                event.dialog = 'skip'
                respond(id, 0, -1, '')
            end
            return false
        end
    end

    if not run.active then return end

    if event.trashPending and not title:find(S.trashConfirm, 1, true) and text:find(S.trashConfirm, 1, true) then
        event.trashPending = false
        event.trashed = true
        respond(id, 1, -1, '')
        return false
    end

    if text:find(S.quantityAsk, 1, true) and text:find(S.quantityTake, 1, true) then
        local count = (run.lastCount and run.lastCount > 0) and run.lastCount or 999999
        respond(id, 1, 0, tostring(count))
        return false
    end
end

function sampev.onServerMessage(color, text)
    if not run.active then return end
    local line = stripColors(text or '')

    if line:find(S.taken, 1, true) then
        event.taken = true
        run.taken = run.taken + 1
    end

    local cost = line:match(S.cost)
    if cost then run.spent = run.spent + (tonumber((cost:gsub('%D', ''))) or 0) end

    if line:find(S.empty, 1, true) then
        stopRun('Готово: хранилище пустое')
    elseif line:find(S.noMoney, 1, true) then
        stopRun('Стоп: не хватает наличных')
    elseif line:find(S.noSpace, 1, true) then
        stopRun('Стоп: нет места в инвентаре')
    end
end

local windowOpen = imgui.new.bool(false)
local inputBuffer = imgui.new.char[128]()
local C = theme.color
local V2 = imgui.ImVec2

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    theme.apply()
end)

local function statCard(id, width, value, caption, color)
    imgui.BeginChild(id, V2(width, 62), true)
    value = tostring(value)
    imgui.SetWindowFontScale(1.4)
    imgui.SetCursorPos(V2((width - imgui.CalcTextSize(value).x) / 2, 6))
    imgui.TextColored(color, value)
    imgui.SetWindowFontScale(0.85)
    imgui.SetCursorPos(V2((width - imgui.CalcTextSize(caption).x) / 2, 38))
    imgui.TextDisabled(caption)
    imgui.SetWindowFontScale(1.0)
    imgui.EndChild()
end

local function drawStatus()
    imgui.Text('Статус:')
    imgui.SameLine()
    if run.active then
        local pulse = 0.6 + 0.4 * math.sin(os.clock() * 5)
        imgui.TextColored(imgui.ImVec4(C.Green.x, C.Green.y, C.Green.z, pulse), 'ИДЁТ ЗАБОР')
    elseif run.reason ~= '' then
        imgui.TextColored(C.Orange, run.reason)
    else
        imgui.TextDisabled('ОЖИДАНИЕ')
    end
end

local function drawStats(width)
    local cardWidth = (width - imgui.GetStyle().ItemSpacing.x * 3) / 4
    statCard('##taken', cardWidth, run.taken, 'забрано', C.Green)
    imgui.SameLine()
    statCard('##trashed', cardWidth, run.trashed, 'выброшено', C.Red)
    imgui.SameLine()
    statCard('##skipped', cardWidth, run.skipped, 'пропущено', C.LightGray)
    imgui.SameLine()
    statCard('##spent', cardWidth, '$ ' .. money(run.spent), 'потрачено', C.Orange)
end

local function drawBlacklist(width)
    imgui.TextColored(C.Red, 'Чёрный список (будет выброшено)')
    imgui.SameLine()
    imgui.TextDisabled('часть названия, регистр не важен')
    imgui.PushItemWidth(width - 110)
    local entered = imgui.InputText('##add', inputBuffer, ffi.sizeof(inputBuffer), imgui.InputTextFlags.EnterReturnsTrue)
    imgui.PopItemWidth()
    imgui.SameLine()
    if theme.coloredButton('blue', 'Добавить', V2(-1, 0)) or entered then
        addToBlacklist(ffi.string(inputBuffer))
        ffi.fill(inputBuffer, ffi.sizeof(inputBuffer))
    end

    imgui.BeginChild('##blacklist', V2(0, 130), true)
    local removeIndex
    for i, entry in ipairs(cfg.blacklist) do
        theme.pushButton('red')
        if imgui.SmallButton('x##bl' .. i) then removeIndex = i end
        theme.popButton()
        imgui.SameLine()
        imgui.Text(entry)
    end
    if #cfg.blacklist == 0 then imgui.TextColored(C.Gray, 'пусто — забирается всё, ничего не выбрасывается') end
    imgui.EndChild()
    if removeIndex then removeFromBlacklist(removeIndex) end
end

local function drawRecent()
    imgui.Text('Недавно увиденные предметы')
    imgui.BeginChild('##recent', V2(0, 0), true)
    for i, name in ipairs(recent) do
        if isBlacklisted(u8:decode(name)) then
            imgui.TextColored(C.Red, '[ЧС]')
            imgui.SameLine()
            imgui.TextDisabled(name)
        else
            theme.pushButton('ghost')
            if imgui.SmallButton('+ ЧС##r' .. i) then addToBlacklist(name) end
            theme.popButton()
            imgui.SameLine()
            imgui.Text(name)
        end
    end
    if #recent == 0 then imgui.TextColored(C.Gray, 'откройте любой предмет в хранилище') end
    imgui.EndChild()
end

imgui.OnFrame(function() return windowOpen[0] end, function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(V2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, V2(0.5, 0.5))
    imgui.SetNextWindowSize(V2(480, 600), imgui.Cond.FirstUseEver)
    if imgui.Begin('StorageTake##stake', windowOpen, imgui.WindowFlags.NoCollapse) then
        local width = imgui.GetContentRegionAvail().x
        imgui.TextDisabled('выборочный забор из /storage')
        imgui.Separator()
        drawStatus()
        imgui.Dummy(V2(0, 4))
        drawStats(width)
        imgui.Dummy(V2(0, 4))
        if theme.coloredButton(run.active and 'red' or 'green', run.active and 'Остановить' or 'Начать забор', V2(-1, 40)) then
            toggleRun()
        end
        imgui.Dummy(V2(0, 4))
        imgui.Separator()
        drawBlacklist(width)
        imgui.Dummy(V2(0, 4))
        drawRecent()
    end
    imgui.End()
end)

function main()
    while not isSampAvailable() do wait(100) end
    sampRegisterChatCommand('stake', function() windowOpen[0] = not windowOpen[0] end)
    chat('загружен. Меню: /stake')

    while true do
        wait(50)
        if refreshTile then
            refreshTile = false
            pcall(emulateCef, REMOVE_LEGACY_BUTTON)
        end
    end
end

function onScriptTerminate(s)
    if s == thisScript() then pcall(emulateCef, REMOVE_LEGACY_BUTTON) end
end
