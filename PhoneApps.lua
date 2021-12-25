-- [ Описание Скрипта ]
script_authors('Leon')
script_version('1.0')
script_version_number(1)
-- [ Библиотеки ]
require ('lib.moonloader')
local as_action = require('moonloader').audiostream_state
local as_status = require('moonloader').audiostream_status
local res, notf = pcall(import, 'imgui_notf.lua')
assert(res, 'PA: Нет библиотеки imgui_notf.lua')
local res, imadd = pcall(require, 'imgui_addons')
assert(res, 'PA: Нет библиотеки imgui_addons')
local res, sampev = pcall(require, 'lib.samp.events')
assert(res, 'PA: Нет библиотеки lib.samp.events')
local res, imgui = pcall(require, 'imgui')
assert(res, 'PA: Нет библиотеки imgui')
local res, memory = pcall(require, 'memory')
assert(res, 'PA: Нет библиотеки memory')
local res, vkeys = pcall(require, 'vkeys')
assert(res, 'PA: Нет библиотеки vkeys')
local res, rkeys = pcall(require, 'lib.rkeys')
assert(res, 'PA: Нет библиотеки RKeys')
local res, folder = pcall(require, 'folder')
assert(res, 'PA: Нет библиотеки folder')
local res, socket = pcall(require, 'socket') 
assert(res, 'PA: Нет библиотеки socket')
local res, encoding = pcall(require, 'encoding')
assert(res, 'PA: Нет библиотеки encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8
-- [ Переменные ]
local variables = {
    ['imgui'] = {                                                                                                           -- Imgui переменные:
        ['MainWindow'] = imgui.ImBool(false),                                                                                   -- Главное окно Imgui
        ['Alarm'] = imgui.ImBool(false),                                                                                        -- Окно Будильника
        ['AddAlarm'] = imgui.ImBool(false),                                                                                     -- Окно Будильника [Добавление]
        ['Timer'] = imgui.ImBool(false),                                                                                        -- Окно Таймера
        ['StopWatch'] = imgui.ImBool(false),                                                                                    -- Окно секундомера
        ['Gallery'] = imgui.ImBool(false),                                                                                      -- Окно Галереи
        ['Music'] = imgui.ImBool(false),                                                                                        -- Окно музыки
        ['EditNote'] = imgui.ImBool(false),                                                                                     -- Редактирование заметок окно Imgui
        ['EditMusic'] = imgui.ImBool(false),                                                                                    -- Редактирование плейлистов окно Imgui
        ['AddToPlaylist'] = imgui.ImBool(false),                                                                                -- Добавление трека в плейлист
        ['Text'] = imgui.ImBuffer('', 1000),                                                                                    -- Редактируемый текст записки календаря
        ['WindowSize'] = { ['x'] = 800, ['y'] = 440 },                                                                          -- Размеры окна Imgui [X, Y]
        ['ChangeMonth'] = imgui.ImInt(os.date('%m')),                                                                           -- Текущий месяц в календаре
        ['ChangeYear'] = imgui.ImInt(os.date('%Y')),                                                                            -- Текущий год в календаре
        ['CalendarBtnSize'] = { ['x'] = 70, ['y'] = 20 },                                                                       -- Размеры кнопок календаря
        ['SelectedDate'] = nil,                                                                                                 -- Выбранная дата для изменения
        ['CalculatorText'] = imgui.ImBuffer('', 1000),                                                                          -- Редактируемый текст калькулятора
        ['Hour'] = imgui.ImInt(1),                                                                                              -- Выбранный час для будильника
        ['Minute'] = imgui.ImInt(1),                                                                                            -- Выбранная минута для будильника
    },
    ['other'] = {                                                                                                           -- Другие переменные:
        ['Screen_X'] = nil,                                                                                                     -- Размер монитора X
        ['Screen_Y'] = nil                                                                                                      -- Размер монитора Y
    }
}
local ScreenFile = {}
local Navigate = {                                                                                                          -- Навигация Imgui [Разделы]:
    ['name'] = '{008000}Phone Apps',                                                                                            -- Имя окна                                                                                          
    ['selected'] = 'Информация',                                                                                                -- Выбранное окно [Стандарт: Информация]
    ['buttons'] = {                                                                                                             -- Кнопки:
        {'Информация'},                                                                                                             -- Раздел Информации
        {'Календарь'},                                                                                                              -- Раздел Календаря
        {'Калькулятор'},                                                                                                            -- Раздел Калькулятора
        {'Музыка'},                                                                                                                 -- Раздел Музыки
        {'Часы'},                                                                                                                   -- Раздел Часов
        {'Галерея'}                                                                                                                 -- Раздел Галереи
    }
}
local StopWatchVariables = {
    ['timertime'] = 0,                                  -- Время начала
    ['reservetime'] = 0,                                -- Время паузы
    ['paused'] = false,                                 -- Пауза ли
    ['enabled'] = false,                                -- Включен ли
    ['Text'] = imgui.ImBuffer('00:00:00.00',100),       -- Текст
    ['logs'] = {}                                       -- Список кругов
}
local ActiveDays = 
{
    ['name'] = {
        'ПН',
        'ВТ',
        'СР',
        'ЧТ',
        'ПТ',
        'СБ',
        'ВС'
    },
    ['imgui'] = {
        imgui.ImBool(false),
        imgui.ImBool(false),
        imgui.ImBool(false),
        imgui.ImBool(false),
        imgui.ImBool(false),
        imgui.ImBool(false),
        imgui.ImBool(false)
    }
}
-- // Получение скриншотов
function getScreens()
    return tostring(memory.tostring(sampGetBase() + 0x219F88) .. "/screens/")
end

-- [ Gallery ]
local ImageNumber = 1                                                                                           -- ID картинки, которое сейчас отображается
local imgs                                                                                                      -- Массив для загрузки скриншотов из папки
local info = {}                                                                                                 -- Информация о пути и имени файла
local logo = {}                                                                                                 -- Создание текстуры полученного файла PNG

-- [ Music Player]
local Music = {
    ['PlaySound'] = nil,
    ['NowPlaying'] = 0,
    ['NowPlayingPL'] = 'All',
    ['Volume'] = 100, -- 2.0
    ['Pause'] = false,
    ['Path'] = 'moonloader/PhoneApps/Music', -- 2.0
    ['Repeating'] = 'none', -- [none] - не повторять | [all] - повторять плейлист | [track] - повторять трек | 2.0
    ['AddName'] = nil,
}
local AlwaysPlaylists = {} -- 2.0
local NowPlaylist = {} -- 2.0
--****************** [ HotKey Function ] ***************
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end 
local Luacfg = {
    _version = "9"
}
setmetatable(Luacfg, {
    __call = function(self)
        return self.__init()
    end
})
function Luacfg.__init()
local self = {}
local lfs = require "lfs"
local inspect = require "inspect"
function self.mkpath(filename)
    local sep, pStr = package.config:sub(1, 1), ""
    local path = filename:match("(.+"..sep..").+$") or filename
    for dir in path:gmatch("[^" .. sep .. "]+") do
        pStr = pStr .. dir .. sep
        lfs.mkdir(pStr)
    end
end
function self.load(filename, tbl)
    local file = io.open(filename, "r")		
    if file then 
        local text = file:read("*all")
        file:close()
        local lua_code = loadstring("return "..text)
        if lua_code then
            loaded_tbl = lua_code()   
            if type(loaded_tbl) == "table" then
                for key, value in pairs(loaded_tbl) do
                    tbl[key] = value
                end
                return true
            else
                return false
            end
        else
            return false
        end
    else
        return false
    end
end  
function self.save(filename, tbl)
    self.mkpath(filename)
    local file = io.open(filename, "w+")
    if file then
        file:write(inspect(tbl))
        file:close()
        return true
    else
        return false
    end
end
    return self
end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local fontsize = {}                                                                                                          -- Размер шрифтов
local mc = imgui.ColorConvertU32ToFloat4(0xFF3333AA)                                                                         -- Цвет
variables['other']['Screen_X'], variables['other']['Screen_Y'] = getScreenResolution()                                       -- Получение разрешения монитора
local clocklineimgui                                                                                                         -- Файл циферблата
if not doesDirectoryExist(getWorkingDirectory()..'\\config\\PhoneApps') then                                                 -- Если нет папки PhoneApps, то создаём
    createDirectory(getWorkingDirectory()..'\\config\\PhoneApps\\Images')
end
if not doesDirectoryExist(getWorkingDirectory()..'\\config\\PhoneApps\\Music') then                                          -- Если нет папки Music, то создаём
    createDirectory(getWorkingDirectory()..'\\config\\PhoneApps\\Music')
end
if not doesFileExist(getWorkingDirectory()..'\\config\\PhoneApps\\Images\\clock.png') then
    downloadUrlToFile('https://github.com/Kaster31/PhoneApps/releases/download/PhoneApps/clock.png',                         -- Если не скачан файл часов, то скачиваем
    getWorkingDirectory()..'\\config\\PhoneApps\\Images\\clock.png')
    clocklineimgui = imgui.CreateTextureFromFile('moonloader\\config\\PhoneApps\\Images\\clock.png')                         -- Создание текстуры из PNG
end

-- [ Биндер Кнопок]
local filename_settings = getWorkingDirectory().."\\config\\PhoneApps\\buttons.txt"                                           -- Путь к файлу о хоткее
if not doesFileExist(filename_settings) then                                                                                  -- Создание файла, если его нет
    local f = io.open(filename_settings, 'w')
    f:close()
end
luacfg = Luacfg()                                                                                                             -- Стандартные клавиши Хоткея
cfg = {
    StopWatchEnabled = {vkeys.VK_F4},                                                                                          
    StopWatchClear = {vkeys.VK_F5}
}
luacfg.load(filename_settings, cfg)                                                                                           -- Загрузка клавиш Хоткея
local hotkeys = {   -- хоткей                                                                                                 -- Imgui Хоткейные клавиши
    StopWatchEnabled = {v = deepcopy(cfg.StopWatchEnabled)},
    StopWatchClear = {v = deepcopy(cfg.StopWatchClear)}
}
------------------------------------------------------------
local JSONFiles = {'calendar','alarm','music'}                                                                               -- Массив JSON Файлов, которые нужно создать
for _, Value in ipairs(JSONFiles) do
    if not doesFileExist(getWorkingDirectory()..'/config/PhoneApps/'..Value..'.json') then                                   -- Если нет файла, то создаём пустой файл
        local File = io.open(getWorkingDirectory()..'/config/PhoneApps/'..Value..'.json',"r");
        if File == nil then 
            local table = {}
            local encodetable = encodeJson(table)
            File = io.open(getWorkingDirectory()..'/config/PhoneApps/'..Value..'.json',"w"); 
            File:write(encodetable)                                                                                          -- Записываем нашу таблицу
            File:flush()
            File:close()
        end
    end
end
-- [  JSON ]
local NoteInDate                                                                                                             -- Таблица с заметками дат календаря
local calendar = io.open(getWorkingDirectory()..'/config/PhoneApps/calendar.json',"r")                                       -- Открытие JSON файла
local file = calendar:read("*a")                                                                                             -- Чтение строк с файла
NoteInDate = decodeJson(file)                                                                                                -- Докодирование JSON файла
calendar:close()                                                                                                             -- Закрытие JSON файла

local NoteInAlarm                                                                                                            -- Таблица с информацией о будильнике
local alarmJSON = io.open(getWorkingDirectory()..'/config/PhoneApps/alarm.json',"r")                                         -- Открытие JSON файла
local file = alarmJSON:read("*a")                                                                                            -- Чтение строк с файла
NoteInAlarm = decodeJson(file)                                                                                               -- Докодирование JSON файла
alarmJSON:close()                                                                                                            -- Закрытие JSON файла

local Playlists = {}

function getMusicList()
	local files = {}
	local handleFile, nameFile = findFirstFile('moonloader/config/PhoneApps/Music/*.mp3') --Music['Path']..'/*.mp3')
	while nameFile do
		if handleFile then
			if not nameFile then 
				findClose(handleFile)
			else
				files[#files+1] = nameFile
				nameFile = findNextFile(handleFile)
			end
		end
	end
	return files
end                                                                                                          -- Закрытие JSON файла

function main()                                                                                                              -- Главная функция скрипта
    while not isSampAvailable() do wait(200) end                                                                             -- Пока SA:MP не загружен ждём
    sampAddChatMessage('[{FF9900}Phone Apps{FFFFFF}] Lua скрипт инициализирован [CMD: {FF0000}/app{FFFFFF}] {990000}!', -1)   -- Вывод сообщения в чат о загрузке скрипта
    sampRegisterChatCommand('app',function()                                                                                 -- Регистрация команды
        variables['imgui']['MainWindow'].v = not variables['imgui']['MainWindow'].v                                          -- Открытие/закрытие главного Imgui окна
    end)
    for Key, Value in pairs(NoteInDate) do
        local day,month,year = Key:match('(%d+)%.(%d+)%.(%d+)')                                                             -- Дата записи календаря
        local datetime = { 
            year  = tonumber(year),
             month = tonumber(month),
             day   = tonumber(day),
             hour  = 0,
             min   = 0,
             sec   = 1
        }
        local seconds = os.time(datetime)                                                                                   
        if os.time() > seconds then                                                                                         -- Если текущее время больше чем время записи, то выводим уведомление
            notf.addNotification('Заметка на '..day..':'..month..':'..year..'\n'..Value, 2, 2)
        end
    end
    StopWatchEnabled = rkeys.registerHotKey(hotkeys.StopWatchEnabled.v, true, function()
        if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and variables['imgui']['StopWatch'].v  then
            if StopWatchVariables['enabled'] then
                if StopWatchVariables['paused'] then
                    StopWatchVariables['timertime'] = os.clock() - StopWatchVariables['reservetime'] + StopWatchVariables['timertime']
                    StopWatchVariables['reservetime'] = 0
                else
                    StopWatchVariables['reservetime'] = os.clock()
                end
                StopWatchVariables['paused'] = not StopWatchVariables['paused']
            else
                StopWatchVariables['enabled'] = true
                StopWatchVariables['timertime'] = os.clock()
            end
        end
    end)
    StopWatchClear = rkeys.registerHotKey(hotkeys.StopWatchClear.v, true, function()
        if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and variables['imgui']['StopWatch'].v  then
            StopWatchVariables['timertime'], StopWatchVariables['reservetime'], StopWatchVariables['enabled'], StopWatchVariables['paused'] = 0, 0, false, false
            StopWatchVariables['Text'] = imgui.ImBuffer('00:00:00.00',100)
            StopWatchVariables['logs'] = {}
        end
    end)
    wait(1000)
    -- [ Получение PNG Файлов из папки скринов]
    imgs = folder.new(getScreens()) 
    imgs:submit('*')
    info = {}
    local files = imgs:files()
    for i = 2, #files do
        if files[i]:type() == 'file' then
            info[#info + 1] = files[i]
            logo[#info] = imgui.CreateTextureFromFile(files[i]:get_path()..files[i]:get_name())
        end
    end
    -- [ Music ]
    local AllMusic = getMusicList()
    Playlists[1] = {['Name'] = 'All', ['Tracks'] = {}}
    for num, name in pairs(AllMusic) do
        local name = name:gsub('.mp3', '')
        table.insert(Playlists[1]['Tracks'], name)
    end
    local musicJSON = io.open(getWorkingDirectory()..'/config/PhoneApps/music.json',"r")                                         -- Открытие JSON файла
    local file = musicJSON:read("*a")                                                                                            -- Чтение строк с файла
    local PlaylistsJSON = decodeJson(file)                                                                                       -- Докодирование JSON файла
    for Key, Value in ipairs(PlaylistsJSON) do
        table.insert(Playlists, Value)
    end
    musicJSON:close()  
    ------------------------------------------
    clocklineimgui = imgui.CreateTextureFromFile('moonloader\\config\\PhoneApps\\Images\\clock.png')                         -- Картинка циферблата
    lua_thread.create(checkAlarm)                                                                                            -- Поток для активации будильника, если нужное время
    lua_thread.create(TimerStart)                                                                                            -- Поток для активации Таймера
    lua_thread.create(StopWatchStart)                                                                                        -- Поток для активации Секундомера
    while true do                                                                                                            -- Бесконечный цикл
        wait(0)                                                                                                              -- Задержка [0 ms]
        -- Открытие Imgui окна зависит от значения переменной
        imgui.Process = variables['imgui']['MainWindow'].v or variables['imgui']['EditNote'].v or variables['imgui']['Alarm'].v or variables['imgui']['Timer'].v or variables['imgui']['StopWatch'].v or
            variables['imgui']['AddAlarm'].v or variables['imgui']['Gallery'].v or variables['imgui']['Music'].v or variables['imgui']['EditMusic'].v or variables['imgui']['AddToPlaylist'].v
        if wasKeyPressed(VK_L) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
            imgui.ShowCursor = not imgui.ShowCursor
        end
        -- [ Music ]
        local PlayListNumber
        for k,v in pairs(Playlists) do
            if Playlists[k]['Name'] == Music['NowPlayingPL'] then 
                PlayListNumber = k
            end
        end
        if Music['PlaySound'] ~= nil and isKeyDown(0x11) and wasKeyPressed(0x37) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
            Music['Pause'] = not Music['Pause']
            if Music['Pause'] then
                setAudioStreamState(Music['PlaySound'], as_action.RESUME)
            else 
                setAudioStreamState(Music['PlaySound'], as_action.PAUSE)
            end
        end
        if Music['PlaySound'] ~= nil and isKeyDown(0x11) and wasKeyPressed(0x36) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
            setAudioStreamState(Music['PlaySound'], as_action.STOP)
            local Numbers = Music['NowPlaying'] 
            if Numbers - 1 < 1 then                                                 
                Numbers = #Playlists[PlayListNumber]['Tracks']
            else 
                Numbers =  Numbers - 1 
            end
            Music['PlaySound'] = loadAudioStream('moonloader/config/PhoneApps/Music/'.. Playlists[PlayListNumber]['Tracks'][Numbers]..'.mp3')
            setAudioStreamState(Music['PlaySound'], as_action.PLAY)
            setAudioStreamVolume(Music['PlaySound'], 99)
            Music['NowPlaying'] = Numbers
            notf.addNotification('Сейчас играет: '..Playlists[PlayListNumber]['Tracks'][Numbers], 2, 2)
        end
        if Music['PlaySound'] ~= nil and isKeyDown(0x11) and wasKeyPressed(0x38) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
            setAudioStreamState(Music['PlaySound'], as_action.STOP)
            local Numbers = Music['NowPlaying'] 
            if Numbers - 1 > #Playlists[PlayListNumber]['Tracks'] then                                                 
                Numbers = 1
            else 
                Numbers =  Numbers + 1 
            end
            Music['PlaySound'] = loadAudioStream('moonloader/config/PhoneApps/Music/'.. Playlists[PlayListNumber]['Tracks'][Numbers]..'.mp3')
            setAudioStreamState(Music['PlaySound'], as_action.PLAY)
            setAudioStreamVolume(Music['PlaySound'], 99)
            Music['NowPlaying'] = Numbers
            notf.addNotification('Сейчас играет: '..Playlists[PlayListNumber]['Tracks'][Numbers], 2, 2)
        end
        if Music['PlaySound'] ~= nil then -- Music
            if getAudioStreamState(Music['PlaySound']) == as_status.STOPPED then                                            -- Если песня кончилась                                                                  -- Для Плейлистов:
                if Playlists[PlayListNumber]['Name'] == Music['NowPlayingPL'] then                                                 -- Если текущий плейлист = из цикла то
                    if Music['Repeating'] == 'none' then                                                                -- Если повтор выключен
                        if Music['NowPlaying'] + 1 <= #Playlists[PlayListNumber]['Tracks'] then                                    -- Включаем следующую песню
                            Music['PlaySound'] = loadAudioStream('moonloader/config/PhoneApps/Music/'.. Playlists[PlayListNumber]['Tracks'][Music['NowPlaying'] + 1]..'.mp3')
                            setAudioStreamState(Music['PlaySound'], as_action.PLAY)
                            setAudioStreamVolume(Music['PlaySound'], 99)
                            Music['NowPlaying'] = Music['NowPlaying'] + 1
                            notf.addNotification('Сейчас играет: '..Playlists[PlayListNumber]['Tracks'][Music['NowPlaying']], 2, 2)
                        else
                            Music['PlaySound'] = nil
                            Music['NowPlaying'] = 0 
                            Music['NowPlayingPL'] = 'All'
                            Music['Pause'] = false 
                        end 
                    elseif Music['Repeating'] == 'track' then                                                               -- Если повтор трека, то включаем его заного
                        Music['PlaySound'] = loadAudioStream('moonloader/config/PhoneApps/Music/'.. Playlists[PlayListNumber]['Tracks'][Music['NowPlaying']]..'.mp3')
                        setAudioStreamState(Music['PlaySound'], as_action.PLAY)
                        setAudioStreamVolume(Music['PlaySound'], 99)
                        Music['NowPlaying'] = Music['NowPlaying']
                        notf.addNotification('Сейчас играет: '..Playlists[PlayListNumber]['Tracks'][Music['NowPlaying']], 2, 2)
                    elseif Music['Repeating'] == 'all' then                                                             -- Если повтор плейлиста, то:
                        local Numbers = Music['NowPlaying'] 
                        if Numbers + 1 > #Playlists[PlayListNumber]['Tracks'] then                                                     -- Если песня конечная, то ставим первый трек плейлиста
                            Numbers = 1 
                        else 
                            Numbers =  Numbers+ 1 
                        end
                        Music['PlaySound'] = loadAudioStream('moonloader/config/PhoneApps/Music/'.. Playlists[PlayListNumber]['Tracks'][Numbers]..'.mp3')
                        setAudioStreamState(Music['PlaySound'], as_action.PLAY)
                        setAudioStreamVolume(Music['PlaySound'], 99)
                        Music['NowPlaying'] = Numbers
                        notf.addNotification('Сейчас играет: '..Playlists[PlayListNumber]['Tracks'][Numbers], 2, 2)
                    end
                end
            end
        end
        --------------------------------------------
    end
end

function checkAlarm()
    while true do
        wait(1000)
        local datetime = os.date("*t",os.time())                                                                              -- Текущение время
        local DayOfWeek = tonumber(os.date("%w",os.time({ year=datetime['year'],                                              -- Получение дня недели по числу
                month = datetime['month'], day = datetime['day']})))
        if DayOfWeek == 0 then DayOfWeek = 7 end
        for Key, Value in pairs(NoteInAlarm) do                                                                               -- Для Ключа, значения в массиве с будильниками
            for Key2, Value2 in pairs(NoteInAlarm[Key]['days']) do                                                            -- Для Ключа2, значения2 в массиве с будильниками ключа 'days'
                if Value2 and Key2 == ActiveDays['name'][DayOfWeek] then                                                      -- Если день активный и Ключ2 = текущему дню тогда
                    if NoteInAlarm[Key]['active'] then                                                                        -- Если будильник включён то
                        local times = os.date("%X", os.time())                                                                -- Получение текущего времени %h:%m:%s
                        local hours, minute, second = times:match('(%d+):(%d+):(%d+)')                                        -- Разбиение времени на переменные
                        if tonumber(hours) == NoteInAlarm[Key]['hour'] and tonumber(minute) == NoteInAlarm[Key]['minute']     -- Если час = часу будильника и минута тоже и секунды меньше 4, тогда активируем будильник
                                and tonumber(second) < 4 then
                            notf.addNotification('Будильник сработал!', 2, 2)
                            addOneOffSound(0.0, 0.0, 0.0, 1056) 
                        end
                    end
                end
            end
        end
    end
end

function imgui.BeforeDrawFrame()                                                                                             -- Функция работы с окном перед открытием Imgui
    if fontsize[25] == nil then                                                                                              -- Загрузка шрифта с 25 размером
        fontsize[25] = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 25.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
    if fontsize[18] == nil then                                                                                              -- Загрузка шрифта с 18 размером
        fontsize[18] = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 18.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
    if fontsize[13] == nil then                                                                                              -- Загрузка шрифта с 13 размером
        fontsize[13] = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 13.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end
function imgui.OnDrawFrame()
    if variables['imgui']['Gallery'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']/6, variables['other']['Screen_Y']/6), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(variables['other']['Screen_X']/1.5,variables['other']['Screen_Y']/1.5 + 120), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'Галерея', variables['imgui']['Gallery'])
            Gallery()
        imgui.End()
    end
    if variables['imgui']['StopWatch'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']-200, variables['other']['Screen_Y']-150), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(200,150), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'Секундомер',variables['imgui']['StopWatch'])
            StopWatch()
        imgui.End()
    end
    if variables['imgui']['Timer'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']-200, variables['other']['Screen_Y']-100), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(200,100))
        imgui.Begin(u8'Таймер',variables['imgui']['Timer'], imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
            Timer()
        imgui.End()
    end
    if variables['imgui']['Alarm'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']/3+variables['imgui']['WindowSize']['x']+5, variables['other']['Screen_Y']/3), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(300,450))
        imgui.Begin(u8'Будильник',variables['imgui']['Alarm'], imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
            Alarm()
        imgui.End()
    end
    if variables['imgui']['AddAlarm'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']/3+variables['imgui']['WindowSize']['x']+5, variables['other']['Screen_Y']/3+290), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(300,160))
        imgui.Begin(u8'Добавить Будильник',variables['imgui']['AddAlarm'], imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
            AddAlarm()
        imgui.End()
    end
    if variables['imgui']['EditMusic'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']/3+variables['imgui']['WindowSize']['x']+5, variables['other']['Screen_Y']/3+290), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(310,100))
        imgui.Begin(u8'Добавить плейлист',variables['imgui']['EditMusic'], imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
            AddPlayList()
        imgui.End()
    end
    if variables['imgui']['AddToPlaylist'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']/3+variables['imgui']['WindowSize']['x']+5, variables['other']['Screen_Y']/3+290), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(310,260))
        imgui.Begin(u8'Добавить в плейлист',variables['imgui']['AddToPlaylist'], imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
            AddToPlayList()
        imgui.End()
    end
    if variables['imgui']['EditNote'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']/3+variables['imgui']['WindowSize']['x']+5, variables['other']['Screen_Y']/3), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(300,450))
        imgui.Begin('Note Edit',variables['imgui']['EditNote'], imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
            NoteCalendar()
        imgui.End()
    else variables['imgui']['Text'].v = '' end

    if variables['imgui']['MainWindow'].v then
        imgui.SetNextWindowPos(imgui.ImVec2(variables['other']['Screen_X']/3, variables['other']['Screen_Y']/3), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(variables['imgui']['WindowSize']['x'], variables['imgui']['WindowSize']['y']), imgui.Cond.FirstUseEver)
        imgui.Begin('Apps',variables['imgui']['MainWindow'], imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
        -- >> Закрытие окна
            imgui.SameLine()
            imgui.SetCursorPos(imgui.ImVec2(variables['imgui']['WindowSize']['x']-30, 30))
            imgui.CloseButton(6, variables['imgui']['MainWindow']) 
        -->> Заголовок активного раздела
            imgui.SetCursorPos( imgui.ImVec2(variables['imgui']['WindowSize']['x']/3, 10) ) 
            imgui.BeginChild('##Title', imgui.ImVec2(400 , 40) , false)
                imgui.PushFont(fontsize[25])
                imgui.TextColoredRGB(Navigate['name']) -- название скрипта
                imgui.SameLine()
                imgui.Text(u8('| '..Navigate['selected']))
                imgui.PopFont()
            imgui.EndChild()
       -->> Кнопки по разделам главного меню
            imgui.NewLine()
            imgui.BeginChild('##Buttons', imgui.ImVec2(600, 40), false)
                imgui.PushFont(fontsize[18])
                imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.0, 0.5))
                for i, title in ipairs(Navigate['buttons']) do
                        if HeaderButton(Navigate['buttons'] == title[1], u8(title[1])) then
                            Navigate['selected'] = title[1]
                        end
                        if Navigate['buttons'] ~= Navigate['selected'] then
                            imgui.SameLine(nil, 30)
                        end
                        --[[if i == 7 then -- Если будет больше, чем 7 объектов, то переносим
                            imgui.NewLine()
                            imgui.NewLine()
                            imgui.SameLine(55)
                        end]]
                end
                imgui.PopStyleVar()
                imgui.PopFont()
            imgui.EndChild()
        -->> Получение контента
        -- Свой цвет + смещение заголовка на 60 пикселей вправо
        imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.01, 0.01, 0.01, 0.00))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
        imgui.BeginTitleChild(u8(Navigate['selected']), imgui.ImVec2(-1, -1), imgui.ImVec4(0.3, 1, 0.3, 1), variables['imgui']['WindowSize']['x']/2 - imgui.CalcTextSize(u8(Navigate['selected'])).x/2 )
            getContentMenu(Navigate['selected'])
        imgui.EndChild()
        imgui.PopStyleColor(2)
        imgui.End()
    end
end

function StopWatch()
    local tLastKeys = {} -- Таблица для клавиш Хоткея
    if require('imgui_addons').HotKey("##StopWatchEnabled", hotkeys.StopWatchEnabled, tLastKeys, 100) then  -- Смена клавиши хоткея
        rkeys.changeHotKey(StopWatchEnabled, hotkeys.StopWatchEnabled.v)
        cfg.StopWatchEnabled = deepcopy(hotkeys.StopWatchEnabled.v)
        luacfg.save(filename_settings, cfg)
    end
    imgui.Hint(u8('Чтобы включить/остановить секундомер используйте эту клавишу  или сочитание клавиш'))    -- Подсказка
    if require('imgui_addons').HotKey("##StopWatchClear", hotkeys.StopWatchClear, tLastKeys, 100) then      -- Смена клавиши хоткея
        rkeys.changeHotKey(StopWatchClear, hotkeys.StopWatchClear.v)
        cfg.StopWatchClear = deepcopy(hotkeys.StopWatchClear.v)
        luacfg.save(filename_settings, cfg)
    end
    imgui.Hint(u8('Чтобы сбросить секундомер используйте эту клавишу или сочитание клавиш'))                -- Подсказка
    if imgui.Button(u8'Сделать отметку', imgui.ImVec2(-0.1,20)) then                                        -- Круг в секундомере
        table.insert(StopWatchVariables.logs, StopWatchVariables['Text'].v)
    end
    imgui.CenterText(u8(StopWatchVariables['Text'].v))                                                      -- Вывод текущего времени секундомера [переменная]
    imgui.Separator()
    if StopWatchVariables['logs'] ~= nil then                                                               -- Вывод Кругов
        for Key, Value in ipairs(StopWatchVariables['logs']) do
            imgui.Text(u8('Круг#'..Key..': '..Value))
        end
    end
end

function StopWatchStart() -- Поток отображения текущего времени секундомера
    while true do 
        wait(0)
        if StopWatchVariables['enabled'] and not StopWatchVariables['paused'] then
            StopWatchVariables['Text'].v = string.format("%02i:%02i:%06.3f",math.floor((os.clock() - StopWatchVariables['timertime']) / 60/60),
            math.floor((os.clock() - StopWatchVariables['timertime']) / 60),
            os.clock() - StopWatchVariables['timertime'] - math.floor((os.clock() - StopWatchVariables['timertime']) / 60) * 60)
        end
    end
end

local TimerVariables = {  -- Время отсчёта для таймера
    ['Hour'] = imgui.ImInt(0),
    ['Minute'] = imgui.ImInt(0),
    ['Second'] = imgui.ImInt(0),
    ['active'] = false
}
function Timer()    -- Таймер
    local Hour = TimerVariables['Hour'].v 
    if Hour < 10 then Hour = '0'..TimerVariables['Hour'].v end
    local Minute = TimerVariables['Minute'].v 
    if Minute < 10 then Minute = '0'..TimerVariables['Minute'].v end
    local Second = TimerVariables['Second'].v 
    if Second < 10 then Second = '0'..TimerVariables['Second'].v end
    imgui.CenterText(u8(Hour..':'..Minute..':'..Second))
    imgui.PushItemWidth(60)                                                                                  -- Установка длины объектам  
    imgui.SliderInt(u8"##Час:", TimerVariables['Hour'], 0, 23) 
    imgui.SameLine()
    imgui.SliderInt(u8"##Минуты:", TimerVariables['Minute'], 0, 59)
    imgui.SameLine()
    imgui.SliderInt(u8"##Секунды:", TimerVariables['Second'], 0, 59)
    imgui.PopItemWidth()  
    if imgui.Button(TimerVariables['active'] and u8'Пауза' or u8'Запустить', imgui.ImVec2(-1, 20)) then      -- Запуск/Пауза
        TimerVariables['active'] = not TimerVariables['active']
    end
end

function TimerStart() -- Поток отсчёта времени в Таймере
    while true do
        wait(1000)
        if TimerVariables['active'] then
            if TimerVariables['Second'].v > 0 then TimerVariables['Second'].v = TimerVariables['Second'].v  - 1 end
            if TimerVariables['Minute'].v > 0 and TimerVariables['Second'].v == 0  then
                TimerVariables['Minute'].v = TimerVariables['Minute'].v - 1 
                TimerVariables['Second'].v = 59 
            end
            if TimerVariables['Hour'].v > 0 and TimerVariables['Minute'].v == 0  then
                TimerVariables['Hour'].v = TimerVariables['Hour'].v - 1 
                TimerVariables['Minute'].v = 59 
            end
            if TimerVariables['Hour'].v == 0 and TimerVariables['Minute'].v == 0 and TimerVariables['Second'].v == 0 then
                TimerVariables['active'] = not TimerVariables['active']
                notf.addNotification('Время Таймера вышло', 2, 2)
                addOneOffSound(0.0, 0.0, 0.0, 1056) 
            end
        end
    end
end

function NoteCalendar() -- Редактирование текста для записки в календаре
    imgui.Text(variables['imgui']['SelectedDate'])                                                                                          -- Текущая запись дня в календаре
    if NoteInDate[tostring(variables['imgui']['SelectedDate'])] ~= nil then
        imgui.Text(u8('Старый текст: ')..u8(NoteInDate[tostring(variables['imgui']['SelectedDate'])]))
    end
    imgui.Text(u8('Новый текст: ')..variables['imgui']['Text'].v)
    imgui.InputTextMultiline('##WriteLine', variables['imgui']['Text'], imgui.ImVec2(-1, 150))
    if imgui.Button('Save',imgui.ImVec2(70,20)) then                                                                                        -- Сохранить текущую запись
        NoteInDate[tostring(variables['imgui']['SelectedDate'])] = u8:decode(variables['imgui']['Text'].v)                                                                                                                      
        variables['imgui']['Text'] = imgui.ImBuffer('', 1000)
        sampAddChatMessage('[{FF9900}Phone Apps{FFFFFF}] Сохранено{990000}!', -1) 
    end
    imgui.SameLine()
    if NoteInDate[tostring(variables['imgui']['SelectedDate'])] ~= nil then                                                                 -- Удалить текущую запись
        if imgui.Button('Delete',imgui.ImVec2(70,20)) then
            NoteInDate[tostring(variables['imgui']['SelectedDate'])] = nil
            sampAddChatMessage('[{FF9900}Phone Apps{FFFFFF}] Удалено{990000}!', -1) 
        end
    end
end

function getContentMenu(section)                                                                                                            -- Получение содержимого меню
	if section == Navigate['buttons'][1][1] --[[ Секция 1 ]] then                                                                           -- Если секция [Информация]
        Information()
    elseif section == Navigate['buttons'][2][1] --[[ Секция 2 ]] then                                                                       -- Если секция [Календарь]
        Calendar()  
    elseif section == Navigate['buttons'][3][1] --[[ Секция 3 ]] then                                                                       -- Если секция [Калькулятор]
        Calculator()
    elseif section == Navigate['buttons'][4][1] --[[ Секций 4 ]] then                                                                       -- Если секция [Музыка]
        Musics()
    elseif section == Navigate['buttons'][5][1] --[[ Секция 5 ]] then                                                                       -- Если секция [Часы]
        Clock()
    elseif section == Navigate['buttons'][6][1] --[[ Секция 6 ]] then                                                                       -- Если секция [Галерея]
        variables['imgui']['MainWindow'].v = false
        Navigate['selected'] = Navigate['buttons'][1][1]
        variables['imgui']['Gallery'].v = true
    end
end

local BTNsize = imgui.ImVec2(80,20) -- Размер Кнопки
local WindowMode = 'All'    -- Плейлист окно
function Musics() -- Вывод окна музыки
    imgui.BeginChild('##left', imgui.ImVec2(500, 0), false)
        playlistmusic()
    imgui.EndChild()
    
    imgui.SameLine()
    imgui.BeginChild('##right', imgui.ImVec2(250, 0), true)
       getPlayLists()
    imgui.EndChild()
end

function getPlayLists() -- Получение списка плейлистов
    imgui.CenterText(u8('..:: Список Плейлистов ::..'))
    if imgui.Button(u8('Создать Плейлист'), imgui.ImVec2(-0.1,20)) then variables['imgui']['EditMusic'].v = not variables['imgui']['EditMusic'].v  end
    if Playlists ~= nil then
        for Key, Value in pairs(Playlists) do
            imgui.BeginChild('##left', imgui.ImVec2(230, 0), true)
                if imgui.ButtonHex(Playlists[Key]['Name'], 0x808080, imgui.ImVec2(140,20)) then WindowMode = Playlists[Key]['Name'] end
                if Key ~= 1 then
                    imgui.SameLine()
                    if imgui.ButtonHex(u8'Удалить##'..Key, 0x808080, imgui.ImVec2(60,20)) then Playlists[Key] = nil end
                end
            imgui.EndChild()
        end
    end
end

--Music['Repeating'] 'none' 'all' 'track'
local RepeatingTable = 
{
    'Без повтора',
    'Повтор Плейлиста',
    'Повтор аудио'
}
local NameOfRepeting = ''
function playlistmusic() -- Получение песен из плейлиста
    imgui.CenterText('..! '..WindowMode.. ' !..')
    imgui.CenterText(u8('..:: Аудиозаписи ::..'))
    -- Повтор
    if Music['Repeating'] == 'all' then NameOfRepeting = RepeatingTable[2]
    elseif Music['Repeating'] == 'none' then NameOfRepeting = RepeatingTable[1]
    elseif Music['Repeating'] == 'track' then NameOfRepeting = RepeatingTable[3] end
    if imgui.ButtonHex(u8(NameOfRepeting), 0x808080, imgui.ImVec2(-0.1,20)) then 
        if Music['Repeating'] == 'all' then Music['Repeating'] = 'track'
        elseif Music['Repeating'] == 'track' then Music['Repeating'] = 'none' 
        elseif Music['Repeating'] == 'none' then Music['Repeating'] = 'all'  end
    end
    -- Треки
    for key, value in pairs(Playlists) do
        if Playlists[key]['Name'] == WindowMode then
            for Key, Value in pairs(Playlists[key]['Tracks']) do
                imgui.ButtonHex(u8(Value..'##'..key), 0x42aaff, imgui.ImVec2(360,20)) -- Name
                imgui.SameLine()
                if Key == Music['NowPlaying'] and Music['Pause'] == false and Playlists[key]['Name'] == Music['NowPlayingPL'] then
                    if imgui.ButtonHex(u8'Пауза##'..Value, 0x808080, BTNsize) then 
                        setAudioStreamState(Music['PlaySound'], as_action.PAUSE)
                        Music['Pause'] = true 
                    end
                elseif Key == Music['NowPlaying'] and Music['Pause'] and Playlists[key]['Name'] == Music['NowPlayingPL'] then 
                    if imgui.ButtonHex(u8'Продолжить##'..Value, 0x808080, BTNsize) then 
                        setAudioStreamState(Music['PlaySound'], as_action.RESUME)
                        Music['Pause'] = false 
                    end
                else
                    if imgui.ButtonHex(u8'Произвести##'..Value, 0x808080, BTNsize) then 
                        if Music['PlaySound'] ~= nil then setAudioStreamState(Music['PlaySound'], as_action.STOP) Music['PlaySound'] = nil end
                        Music['PlaySound'] = loadAudioStream('moonloader/config/PhoneApps/Music/'..Value..'.mp3')
                        setAudioStreamState(Music['PlaySound'], as_action.PLAY)
                        setAudioStreamVolume(Music['PlaySound'], 99)
                        Music['NowPlaying'] = Key 
                        Music['NowPlayingPL'] = Playlists[key]['Name']
                        notf.addNotification('Сейчас играет: '..Value, 2, 2)
                        Music['Pause'] = false 
                    end
                end
                imgui.SameLine()
                if WindowMode ~= 'All' then
                    if imgui.ButtonHex(u8('-##'..Key), 0x808080, imgui.ImVec2(20,20)) then table.remove(Playlists[key]['Tracks'], Key) end
                else
                    if imgui.ButtonHex(u8('+##'..Key), 0x808080, imgui.ImVec2(20,20)) then 
                        Music['AddName'] = Value 
                        if variables['imgui']['AddToPlaylist'].v == false then
                            variables['imgui']['AddToPlaylist'].v = not variables['imgui']['AddToPlaylist'].v
                        end
                    end
                end
            end
        end
    end
end

local NamePlayList = imgui.ImBuffer('',32)
function AddPlayList() -- Добавление плейлиста
    imgui.InputText(u8'Имя плейлиста', NamePlayList)
    if imgui.ButtonHex(u8('Сохранить Плейлист'), 0x808080, imgui.ImVec2(-0.1, 0)) then 
        if NamePlayList.v == '' then return notf.addNotification('Введите уникальное имя плейлиста', 2, 3) end
        for k,v in ipairs(Playlists) do
            if Playlists[k]['Name'] == NamePlayList.v then return notf.addNotification('Введите уникальное имя плейлиста', 2, 3) end
        end
        sampAddChatMessage('[{FF9900}Phone Apps{FFFFFF}] Плейлист сохранён{990000}!', -1) 
        table.insert(Playlists, {['Name'] = NamePlayList.v, ['Tracks'] = {}})
    end
end

function AddToPlayList()
    imgui.CenterText(u8'Список плейлистов:')
    for Key, Value in ipairs(Playlists) do
        for Key2, Value2 in pairs(Playlists[Key]['Tracks']) do
            if Value2 == Music['AddName'] then goto metka2 end
        end
        if imgui.ButtonHex(Playlists[Key]['Name'], 0x808080, imgui.ImVec2(-0.1, 0)) then 
            notf.addNotification('Добавлен новый трек в плейлист', 2, 2)
             table.insert(Playlists[Key]['Tracks'], Music['AddName']) 
        end
        ::metka2::
    end
end

function Gallery()  -- Галерея
    imgui.SameLine()
    if info[ImageNumber] ~= nil then -- Если массив с информацией о скриншотах не пустой
        imgui.CenterText(info[ImageNumber]:get_name()) -- Вывод имени
        local bColor = imgui.ImColor(255, 255, 255, 255):GetU32()
        imgui.Image(logo[ImageNumber], imgui.ImVec2(variables['other']['Screen_X']/1.5, variables['other']['Screen_Y']/1.5), imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), imgui.ImColor(bColor):GetVec4()) -- PNG File
        imgui.NewLine()
        imgui.SameLine(imgui.GetCenter()-90) -- Отступ
        if ImageNumber > 1 then -- Изображение слева
            if imgui.ButtonHex('<--', 0x808080, imgui.ImVec2(60,20)) then
                ImageNumber = ImageNumber - 1
            end
        else imgui.ButtonHex('##<--', 0x000000, imgui.ImVec2(60,20)) 
        end
        imgui.SameLine()
        if imgui.ButtonHex(u8'Удалить', 0xff0000, imgui.ImVec2(60,20)) then -- Удаление скриншота
            os.remove(info[ImageNumber]:get_path()..info[ImageNumber]:get_name()) -- Удаление
            RefreshImg() -- Обновление
            sampAddChatMessage('[{FF9900}Phone Apps{FFFFFF}] Удалено{990000}!', -1) 
        end
        imgui.SameLine()
        if ImageNumber < #info then -- Изображение справа
            if imgui.ButtonHex('-->', 0x808080, imgui.ImVec2(60,20)) then
                ImageNumber = ImageNumber + 1
            end
        else imgui.ButtonHex('##-->', 0x000000, imgui.ImVec2(60,20)) 
        end
    else 
        imgui.CenterText(u8'Папка скриншотов пустая')
    end
end

function RefreshImg()   -- Удаление из массива удалённого файла
    table.remove(info, ImageNumber)
    table.remove(logo, ImageNumber)
    ImageNumber = #info
end

function Information()  -- Информация
    imgui.CenterText(u8'Текущая версия: '..thisScript().version )
    imgui.TextColoredRGB('{FFFFFF}Используйте кнопку [{FF0000}L{FFFFFF}], чтобы включить/выключить imgui курсор мыши')
    imgui.TextColoredRGB('{FFFFFF}Используйте сочитание клавиш [{FF0000}CTRL + 6{FFFFFF}], чтобы переключить песню назад')
    imgui.TextColoredRGB('{FFFFFF}Используйте сочитание клавиш [{FF0000}CTRL + 7{FFFFFF}], чтобы возобновить/поставить песню на паузу')
    imgui.TextColoredRGB('{FFFFFF}Используйте сочитание клавиш [{FF0000}CTRL + 8{FFFFFF}], чтобы переключить песню вперёд')
end

local NameOfDayOfWeek = {                                                                                                                   -- Название дней недели
    'ПН',
    'ВТ',
    'СР',
    'ЧТ',
    'ПТ',
    'СБ',
    'ВС'
}
local NumberOfDaysInMonth = {                                                                                                               -- Количество дней в месяце, кроме Февраля
    ['1'] = 31,
    ['3'] = 31,
    ['4'] = 30, 
    ['5'] = 31,
    ['6'] = 30,
    ['7'] = 31,
    ['8'] = 31,
    ['9'] = 30,
    ['10'] = 31,
    ['11'] = 30,
    ['12'] = 31
}
function getDaysInMonth(month, year)                                                                                                        -- Получение дней в месяце по месяцу и году
    month = tostring(month)
    if NumberOfDaysInMonth[month] ~= nil then return NumberOfDaysInMonth[month] 
    elseif tonumber(month) == 2 then 
        if year % 4 == 0 or year % 400 == 0 then 
            return 29 
        else 
            return 28 
        end
    end
end
function Calendar()
    local Date = {                                                                                                                          -- Переменные
        ['NowTime'] =  os.date("*t",os.time()),                                                                                             -- Получение таблицы текущего времени                                                                                                         -- Получение текущего года
    }
    local FirstDayOfMonth = tonumber(os.date("%w",os.time({ year = variables['imgui']['ChangeYear']['v'],                                   -- Получение недели первого дня месяца
        month = variables['imgui']['ChangeMonth']['v'], day = 1}))) 
    imgui.SetCursorPos(imgui.ImVec2(30,115))
    imgui.BeginChild("##CalendarChildSkip", imgui.ImVec2(80,30), true)                                                                      -- Месяц назад
    if imgui.ButtonHex('<<<', 0xdc143c, imgui.ImVec2(variables['imgui']['CalendarBtnSize']['x'], variables['imgui']['CalendarBtnSize']['y'])) then
        if variables['imgui']['ChangeMonth']['v']-1 < 1 then 
            variables['imgui']['ChangeMonth']['v'] = 12 
            variables['imgui']['ChangeYear']['v'] = variables['imgui']['ChangeYear']['v'] - 1 
        else
            variables['imgui']['ChangeMonth']['v'] = variables['imgui']['ChangeMonth']['v'] - 1
        end
    end
    imgui.EndChild()
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(120,20))
    imgui.BeginChild("##CalendarChild", imgui.ImVec2(7*variables['imgui']['CalendarBtnSize']['x']+7*5,25*8), true)                                         
    imgui.SameLine(variables['imgui']['WindowSize']['x']/4)      
    local MonthImgui = variables['imgui']['ChangeMonth']['v']
    if tonumber(MonthImgui) < 10 then MonthImgui = '0'..variables['imgui']['ChangeMonth']['v']  end                                                                      
    imgui.CenterText(u8(tostring('Месяц: '..MonthImgui..' | Год: '..variables['imgui']['ChangeYear']['v'])))                                      -- Текущая дата
    for Key, Value in ipairs(NameOfDayOfWeek) do                                                                                            -- Вывод дней недели
        imgui.ButtonHex(u8(Value), 0x2E2626, imgui.ImVec2(variables['imgui']['CalendarBtnSize']['x'], variables['imgui']['CalendarBtnSize']['y']))
        imgui.SameLine()                                                                                                                    -- Отступ
    end
    imgui.NewLine()                                                                                                                         -- Перенос строки
    for DaysCount = 1, getDaysInMonth(variables['imgui']['ChangeMonth']['v'], variables['imgui']['ChangeYear']['v']) do                     -- Для первого дня до количества дней в месяц
        -- [ Переменнные ]
        local DayOfWeek = tonumber(os.date("%w",os.time({ year=variables['imgui']['ChangeYear']['v'],                                       -- Получение дня недели по числу
        month = variables['imgui']['ChangeMonth']['v'], day = DaysCount}))) + 1
        local NowNameOfDay = tostring(DaysCount)                                                                                            -- Число 
        -- [ Тело ]
        if FirstDayOfMonth == 0 and DaysCount == 1 then                                                                                     -- Если первый день Воскресенье:
            for DaysOfLastMonth = 1, 6 do                                                                                               
                imgui.ButtonHex(' ',0x808080,imgui.ImVec2(variables['imgui']['CalendarBtnSize']['x'], variables['imgui']['CalendarBtnSize']['y']),1)                                                                       
                imgui.SameLine()
            end
        elseif DaysCount == 1 then                                                                                                          -- Если день первый то:
            for DaysOfLastMonth = 0, 5 - math.abs(FirstDayOfMonth-7) do                                                                     -- Высчитывание дней с прошлого месяца [Цикл]
                imgui.ButtonHex(' ',0x808080,imgui.ImVec2(variables['imgui']['CalendarBtnSize']['x'], variables['imgui']['CalendarBtnSize']['y']),1)                                                                       
                imgui.SameLine()
            end
        end
        if DaysCount ~= Date['NowTime']['day'] or                                                                                           -- Если счётчик дня не равен сегодняшнему дню или равен, но другой месяц то:
            (variables['imgui']['ChangeMonth']['v'] ~= Date['NowTime']['month'] and DaysCount == Date['NowTime']['day']) or
            (DaysCount == Date['NowTime']['day'] and variables['imgui']['ChangeYear']['v'] ~= Date['NowTime']['year'])
        then                   
            if imgui.ButtonHex(NowNameOfDay,0xbbbbbb,imgui.ImVec2(variables['imgui']['CalendarBtnSize']['x'],                               -- Выводим обычную кнопку
                variables['imgui']['CalendarBtnSize']['y'])) then
                edit_Note(tostring(DaysCount..'.'..variables['imgui']['ChangeMonth']['v']..'.'..variables['imgui']['ChangeYear']['v']))
            end
        elseif DaysCount == Date['NowTime']['day'] and variables['imgui']['ChangeYear']['v'] == Date['NowTime']['year'] then                -- Иначе выводим красную кнопку [Текущий день]
            if imgui.ButtonHex(NowNameOfDay,0xff0000, imgui.ImVec2(variables['imgui']['CalendarBtnSize']['x'], variables['imgui']['CalendarBtnSize']['y']), 1) then
                edit_Note(tostring(DaysCount..'.'..variables['imgui']['ChangeMonth']['v']..'.'..variables['imgui']['ChangeYear']['v']))
            end
        end
        for Key, Value in pairs(NoteInDate) do
            if tostring(DaysCount..'.'..variables['imgui']['ChangeMonth']['v']..'.'..variables['imgui']['ChangeYear']['v']) == Key then
                imgui.Hint(u8(Value))
            end
        end
    imgui.SameLine()                                                                                                                        -- Отступ на той же строке
        if DayOfWeek == 1 then imgui.NewLine() end                                                                                          -- Если день недели = Воскресенье, перенос строки
    end
    imgui.EndChild()
    imgui.SetCursorPos(imgui.ImVec2(655,115))
    imgui.BeginChild("##CalendarChildSkip2", imgui.ImVec2(80,30), true)                                                                     -- Месяц назад
    if imgui.ButtonHex('>>>', 0xdc143c, imgui.ImVec2(variables['imgui']['CalendarBtnSize']['x'], variables['imgui']['CalendarBtnSize']['y'])) then
        if variables['imgui']['ChangeMonth']['v']+1 > 12 then 
            variables['imgui']['ChangeMonth']['v'] = 1 
            variables['imgui']['ChangeYear']['v'] = variables['imgui']['ChangeYear']['v'] + 1 
        else
            variables['imgui']['ChangeMonth']['v'] = variables['imgui']['ChangeMonth']['v'] + 1
        end
    end
    imgui.EndChild()
end

function edit_Note(SelectedDate)                                                                                                            -- Включение окна редактирования записи дня в календаре
    if not variables['imgui']['EditNote'].v then
        variables['imgui']['EditNote'].v = not variables['imgui']['EditNote'].v
    end
    variables['imgui']['SelectedDate'] = SelectedDate
end

function Calculator()                                                                                                                       -- Функция калькулятора 
    local sizeItem = 200                                                                                                                    -- Размер предметов
    imgui.SetCursorPos(imgui.ImVec2(variables['imgui']['WindowSize']['x']/2-sizeItem/2,20))                                                 -- Положение курсора в окне Imgui 
    imgui.PushItemWidth(sizeItem)                                                                                                           -- Установка длины объектам
    imgui.InputText('',variables['imgui']['CalculatorText'])                                                                                -- Ввод примера
    imgui.PopItemWidth()                                                                                                                    -- Конец установки длины объекта
    imgui.Hint(u8('"+" - сложение\n"-" - вычитание\n"*" - умножение\n"/"- деление\n"^" - степень'))                                         -- Подсказка
    imgui.SetCursorPos(imgui.ImVec2(variables['imgui']['WindowSize']['x']/2-sizeItem/3,45))                                                 -- Установка курсора в окне Imgui
    if imgui.Button(u8'Вывести результат') then
        local result = math.eval(variables['imgui']['CalculatorText']['v'])                                                                 -- Математическая функция для просчёта примера
        if result ~= nil then
            if type(result) == 'string' or type(result) == 'number' then
                sampAddChatMessage('[{FF9900}Phone Apps{FFFFFF}] Результат: {990000}'..result..'{FFFFFF}!',-1)                              -- Вывод результата
            end
        end
    end
end
local TSTi = imgui.ImBuffer('', 35000)

-- [ Загрузка изображений из base85 и png с папки]
local hourline ="\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x96\x00\x00\x00\x96\x08\x06\x00\x00\x00\x3C\x01\x71\xE2\x00\x00\x01\x37\x69\x43\x43\x50\x41\x64\x6F\x62\x65\x20\x52\x47\x42\x20\x28\x31\x39\x39\x38\x29\x00\x00\x28\x91\x95\x8F\xBF\x4A\xC3\x50\x14\x87\xBF\x1B\x45\xC5\xA1\x56\x08\xE2\xE0\x70\x27\x51\x50\x6C\xD5\xC1\x8C\x49\x5B\x8A\x20\x58\xAB\x43\x92\xAD\x49\x43\x95\x62\x12\x6E\xAE\x7F\xFA\x10\x8E\x6E\x1D\x5C\xDC\x7D\x02\x27\x47\xC1\x41\xF1\x09\x7C\x03\xC5\xA9\x83\x43\x84\x0C\x05\x8B\xDF\xF4\x9D\xDF\x39\x1C\xCE\x01\xA3\x62\xD7\x9D\x86\x51\x86\xF3\x58\xAB\x76\xD3\x91\xAE\xE7\xCB\xD9\x17\x66\x98\x02\x80\x4E\x98\xA5\x76\xAB\x75\x00\x10\x27\x71\xC4\x18\xDF\xEF\x08\x80\xD7\x4D\xBB\xEE\x34\xC6\xFB\x7F\x32\x1F\xA6\x4A\x03\x23\x60\xBB\x1B\x65\x21\x88\x0A\xD0\xBF\xD2\xA9\x06\x31\x04\xCC\xA0\x9F\x6A\x10\x0F\x80\xA9\x4E\xDA\x35\x10\x4F\x40\xA9\x97\xFB\x1B\x50\x0A\x72\xFF\x00\x4A\xCA\xF5\x7C\x10\x5F\x80\xD9\x73\x3D\x1F\x8C\x39\xC0\x0C\x72\x5F\x01\x4C\x1D\x5D\x6B\x80\x5A\x92\x0E\xD4\x59\xEF\x54\xCB\xAA\x65\x59\xD2\xEE\x26\x41\x24\x8F\x07\x99\x8E\xCE\x33\xB9\x1F\x87\x89\x4A\x13\xD5\xD1\x51\x17\xC8\xEF\x03\x60\x31\x1F\x6C\x37\x1D\xB9\x56\xB5\xAC\xBD\xF5\x7F\xFE\x3D\x11\xD7\xF3\x65\x6E\x9F\x47\x08\x40\x2C\x3D\x17\x59\x41\x78\xA1\x2E\x7F\x55\x18\x3B\x93\xEB\x62\xC7\x70\x19\x0E\xEF\x61\x7A\x54\x64\xBB\x37\x70\xB7\x01\x0B\xB7\x45\xB6\x5A\x85\xF2\x16\x3C\x0E\x7F\x00\xC0\xC6\x4F\xFD\xF3\x53\x3F\xC8\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x0B\x13\x00\x00\x0B\x13\x01\x00\x9A\x9C\x18\x00\x00\x05\xD1\x69\x54\x58\x74\x58\x4D\x4C\x3A\x63\x6F\x6D\x2E\x61\x64\x6F\x62\x65\x2E\x78\x6D\x70\x00\x00\x00\x00\x00\x3C\x3F\x78\x70\x61\x63\x6B\x65\x74\x20\x62\x65\x67\x69\x6E\x3D\x22\xEF\xBB\xBF\x22\x20\x69\x64\x3D\x22\x57\x35\x4D\x30\x4D\x70\x43\x65\x68\x69\x48\x7A\x72\x65\x53\x7A\x4E\x54\x63\x7A\x6B\x63\x39\x64\x22\x3F\x3E\x20\x3C\x78\x3A\x78\x6D\x70\x6D\x65\x74\x61\x20\x78\x6D\x6C\x6E\x73\x3A\x78\x3D\x22\x61\x64\x6F\x62\x65\x3A\x6E\x73\x3A\x6D\x65\x74\x61\x2F\x22\x20\x78\x3A\x78\x6D\x70\x74\x6B\x3D\x22\x41\x64\x6F\x62\x65\x20\x58\x4D\x50\x20\x43\x6F\x72\x65\x20\x35\x2E\x36\x2D\x63\x31\x34\x35\x20\x37\x39\x2E\x31\x36\x33\x34\x39\x39\x2C\x20\x32\x30\x31\x38\x2F\x30\x38\x2F\x31\x33\x2D\x31\x36\x3A\x34\x30\x3A\x32\x32\x20\x20\x20\x20\x20\x20\x20\x20\x22\x3E\x20\x3C\x72\x64\x66\x3A\x52\x44\x46\x20\x78\x6D\x6C\x6E\x73\x3A\x72\x64\x66\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x77\x77\x77\x2E\x77\x33\x2E\x6F\x72\x67\x2F\x31\x39\x39\x39\x2F\x30\x32\x2F\x32\x32\x2D\x72\x64\x66\x2D\x73\x79\x6E\x74\x61\x78\x2D\x6E\x73\x23\x22\x3E\x20\x3C\x72\x64\x66\x3A\x44\x65\x73\x63\x72\x69\x70\x74\x69\x6F\x6E\x20\x72\x64\x66\x3A\x61\x62\x6F\x75\x74\x3D\x22\x22\x20\x78\x6D\x6C\x6E\x73\x3A\x78\x6D\x70\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F\x78\x61\x70\x2F\x31\x2E\x30\x2F\x22\x20\x78\x6D\x6C\x6E\x73\x3A\x78\x6D\x70\x4D\x4D\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F\x78\x61\x70\x2F\x31\x2E\x30\x2F\x6D\x6D\x2F\x22\x20\x78\x6D\x6C\x6E\x73\x3A\x73\x74\x45\x76\x74\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F\x78\x61\x70\x2F\x31\x2E\x30\x2F\x73\x54\x79\x70\x65\x2F\x52\x65\x73\x6F\x75\x72\x63\x65\x45\x76\x65\x6E\x74\x23\x22\x20\x78\x6D\x6C\x6E\x73\x3A\x64\x63\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x70\x75\x72\x6C\x2E\x6F\x72\x67\x2F\x64\x63\x2F\x65\x6C\x65\x6D\x65\x6E\x74\x73\x2F\x31\x2E\x31\x2F\x22\x20\x78\x6D\x6C\x6E\x73\x3A\x70\x68\x6F\x74\x6F\x73\x68\x6F\x70\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F\x70\x68\x6F\x74\x6F\x73\x68\x6F\x70\x2F\x31\x2E\x30\x2F\x22\x20\x78\x6D\x70\x3A\x43\x72\x65\x61\x74\x6F\x72\x54\x6F\x6F\x6C\x3D\x22\x41\x64\x6F\x62\x65\x20\x50\x68\x6F\x74\x6F\x73\x68\x6F\x70\x20\x43\x43\x20\x32\x30\x31\x39\x20\x28\x57\x69\x6E\x64\x6F\x77\x73\x29\x22\x20\x78\x6D\x70\x3A\x43\x72\x65\x61\x74\x65\x44\x61\x74\x65\x3D\x22\x32\x30\x32\x31\x2D\x30\x31\x2D\x32\x33\x54\x32\x30\x3A\x31\x39\x3A\x33\x35\x2B\x30\x33\x3A\x30\x30\x22\x20\x78\x6D\x70\x3A\x4D\x65\x74\x61\x64\x61\x74\x61\x44\x61\x74\x65\x3D\x22\x32\x30\x32\x31\x2D\x30\x31\x2D\x32\x33\x54\x32\x30\x3A\x31\x39\x3A\x33\x35\x2B\x30\x33\x3A\x30\x30\x22\x20\x78\x6D\x70\x3A\x4D\x6F\x64\x69\x66\x79\x44\x61\x74\x65\x3D\x22\x32\x30\x32\x31\x2D\x30\x31\x2D\x32\x33\x54\x32\x30\x3A\x31\x39\x3A\x33\x35\x2B\x30\x33\x3A\x30\x30\x22\x20\x78\x6D\x70\x4D\x4D\x3A\x49\x6E\x73\x74\x61\x6E\x63\x65\x49\x44\x3D\x22\x78\x6D\x70\x2E\x69\x69\x64\x3A\x34\x61\x34\x35\x31\x65\x63\x66\x2D\x32\x31\x64\x62\x2D\x66\x32\x34\x63\x2D\x39\x64\x35\x39\x2D\x63\x66\x33\x63\x31\x37\x38\x31\x33\x62\x64\x33\x22\x20\x78\x6D\x70\x4D\x4D\x3A\x44\x6F\x63\x75\x6D\x65\x6E\x74\x49\x44\x3D\x22\x61\x64\x6F\x62\x65\x3A\x64\x6F\x63\x69\x64\x3A\x70\x68\x6F\x74\x6F\x73\x68\x6F\x70\x3A\x31\x66\x30\x61\x33\x66\x33\x64\x2D\x65\x37\x30\x36\x2D\x31\x63\x34\x32\x2D\x61\x34\x63\x35\x2D\x31\x61\x36\x66\x35\x66\x30\x31\x38\x39\x65\x39\x22\x20\x78\x6D\x70\x4D\x4D\x3A\x4F\x72\x69\x67\x69\x6E\x61\x6C\x44\x6F\x63\x75\x6D\x65\x6E\x74\x49\x44\x3D\x22\x78\x6D\x70\x2E\x64\x69\x64\x3A\x66\x64\x39\x32\x39\x36\x63\x36\x2D\x39\x39\x32\x66\x2D\x31\x37\x34\x30\x2D\x38\x62\x61\x39\x2D\x64\x30\x38\x64\x33\x37\x66\x38\x61\x36\x35\x31\x22\x20\x64\x63\x3A\x66\x6F\x72\x6D\x61\x74\x3D\x22\x69\x6D\x61\x67\x65\x2F\x70\x6E\x67\x22\x20\x70\x68\x6F\x74\x6F\x73\x68\x6F\x70\x3A\x43\x6F\x6C\x6F\x72\x4D\x6F\x64\x65\x3D\x22\x33\x22\x3E\x20\x3C\x78\x6D\x70\x4D\x4D\x3A\x48\x69\x73\x74\x6F\x72\x79\x3E\x20\x3C\x72\x64\x66\x3A\x53\x65\x71\x3E\x20\x3C\x72\x64\x66\x3A\x6C\x69\x20\x73\x74\x45\x76\x74\x3A\x61\x63\x74\x69\x6F\x6E\x3D\x22\x63\x72\x65\x61\x74\x65\x64\x22\x20\x73\x74\x45\x76\x74\x3A\x69\x6E\x73\x74\x61\x6E\x63\x65\x49\x44\x3D\x22\x78\x6D\x70\x2E\x69\x69\x64\x3A\x66\x64\x39\x32\x39\x36\x63\x36\x2D\x39\x39\x32\x66\x2D\x31\x37\x34\x30\x2D\x38\x62\x61\x39\x2D\x64\x30\x38\x64\x33\x37\x66\x38\x61\x36\x35\x31\x22\x20\x73\x74\x45\x76\x74\x3A\x77\x68\x65\x6E\x3D\x22\x32\x30\x32\x31\x2D\x30\x31\x2D\x32\x33\x54\x32\x30\x3A\x31\x39\x3A\x33\x35\x2B\x30\x33\x3A\x30\x30\x22\x20\x73\x74\x45\x76\x74\x3A\x73\x6F\x66\x74\x77\x61\x72\x65\x41\x67\x65\x6E\x74\x3D\x22\x41\x64\x6F\x62\x65\x20\x50\x68\x6F\x74\x6F\x73\x68\x6F\x70\x20\x43\x43\x20\x32\x30\x31\x39\x20\x28\x57\x69\x6E\x64\x6F\x77\x73\x29\x22\x2F\x3E\x20\x3C\x72\x64\x66\x3A\x6C\x69\x20\x73\x74\x45\x76\x74\x3A\x61\x63\x74\x69\x6F\x6E\x3D\x22\x73\x61\x76\x65\x64\x22\x20\x73\x74\x45\x76\x74\x3A\x69\x6E\x73\x74\x61\x6E\x63\x65\x49\x44\x3D\x22\x78\x6D\x70\x2E\x69\x69\x64\x3A\x34\x61\x34\x35\x31\x65\x63\x66\x2D\x32\x31\x64\x62\x2D\x66\x32\x34\x63\x2D\x39\x64\x35\x39\x2D\x63\x66\x33\x63\x31\x37\x38\x31\x33\x62\x64\x33\x22\x20\x73\x74\x45\x76\x74\x3A\x77\x68\x65\x6E\x3D\x22\x32\x30\x32\x31\x2D\x30\x31\x2D\x32\x33\x54\x32\x30\x3A\x31\x39\x3A\x33\x35\x2B\x30\x33\x3A\x30\x30\x22\x20\x73\x74\x45\x76\x74\x3A\x73\x6F\x66\x74\x77\x61\x72\x65\x41\x67\x65\x6E\x74\x3D\x22\x41\x64\x6F\x62\x65\x20\x50\x68\x6F\x74\x6F\x73\x68\x6F\x70\x20\x43\x43\x20\x32\x30\x31\x39\x20\x28\x57\x69\x6E\x64\x6F\x77\x73\x29\x22\x20\x73\x74\x45\x76\x74\x3A\x63\x68\x61\x6E\x67\x65\x64\x3D\x22\x2F\x22\x2F\x3E\x20\x3C\x2F\x72\x64\x66\x3A\x53\x65\x71\x3E\x20\x3C\x2F\x78\x6D\x70\x4D\x4D\x3A\x48\x69\x73\x74\x6F\x72\x79\x3E\x20\x3C\x2F\x72\x64\x66\x3A\x44\x65\x73\x63\x72\x69\x70\x74\x69\x6F\x6E\x3E\x20\x3C\x2F\x72\x64\x66\x3A\x52\x44\x46\x3E\x20\x3C\x2F\x78\x3A\x78\x6D\x70\x6D\x65\x74\x61\x3E\x20\x3C\x3F\x78\x70\x61\x63\x6B\x65\x74\x20\x65\x6E\x64\x3D\x22\x72\x22\x3F\x3E\x79\xCA\x50\x2C\x00\x00\x01\xEB\x49\x44\x41\x54\x78\x9C\xED\xD8\xC1\x4E\x83\x40\x14\x40\xD1\x87\x7F\x8B\x1F\x44\x3F\x17\x37\x5D\xB6\x05\xA3\xD7\x5A\x3D\x67\x03\x99\xD9\xBC\x4C\x6E\x26\x81\x65\xDF\xF7\x81\xEF\xF6\xF6\xEC\x01\xF8\x9B\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x75\xDE\x36\x33\xFB\xF5\xC9\x01\x61\x9D\xB3\xCD\xCC\x7A\x7D\x5F\x47\x5C\x87\x16\xFF\xB1\x4E\xB9\x75\x48\xCB\x8F\x4F\xF1\x42\xDC\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x45\x42\x58\x24\x84\x75\x6C\xFB\xE4\x3A\x23\xAC\x23\xDB\xCC\xAC\x77\xF6\xD6\x11\xD7\x5D\xCB\xBE\xEF\xCF\x9E\xE1\x37\x3B\x73\x38\x4B\x3E\xC5\x0B\x72\x63\x91\x10\x16\x09\x61\x3D\x76\xF9\xE2\xFE\xBF\x25\xAC\xC7\xDE\xE7\x7E\x3C\x97\xEB\x3E\x37\x08\xEB\xD8\xAD\xB8\x44\x75\xC0\x57\x21\x09\x37\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x09\x61\x91\x10\x16\x89\x0F\x90\x62\x1B\xA2\x39\x50\x80\x4D\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"
local hourlineimgui = imgui.CreateTextureFromMemory(memory.strptr(hourline), #hourline)
local minuteline = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\xDC\x00\x00\x00\xDC\x08\x06\x00\x00\x00\x1B\x5A\xCF\x81\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x0B\x13\x00\x00\x0B\x13\x01\x00\x9A\x9C\x18\x00\x00\x00\x20\x63\x48\x52\x4D\x00\x00\x7A\x25\x00\x00\x80\x83\x00\x00\xF9\xFF\x00\x00\x80\xE9\x00\x00\x75\x30\x00\x00\xEA\x60\x00\x00\x3A\x98\x00\x00\x17\x6F\x92\x5F\xC5\x46\x00\x00\x03\x25\x49\x44\x41\x54\x78\xDA\xEC\xD9\x41\x8B\x4D\x61\x1C\xC0\xE1\xDF\x1D\x8A\xB2\x10\x16\x63\x33\x16\x92\xAC\x06\xA5\xAC\x58\xD0\x2C\xED\x94\x1A\xE4\x43\xF8\x1C\xBE\x80\xB2\x60\x67\xE1\x13\x10\x59\xC9\x52\xD9\xD8\x59\x88\x58\x8C\x62\x86\x14\x5D\x0B\x67\x4A\x53\x26\x33\x26\xCE\xE4\x79\xEA\x76\xEB\xDC\xF7\x6E\xFE\xA7\xDF\x3D\xEF\x3D\x67\x32\x9D\x4E\x03\xFE\x8E\x19\x23\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x40\x70\x8C\xD1\xA4\x3A\x5F\xDD\xAD\xDE\x54\xCF\xAA\xEB\xD5\xAC\xD1\x08\x0E\x58\x63\xA7\x11\x6C\x1B\xBB\xAA\x33\xD5\xB5\x6A\xA1\xDA\x57\x1D\xAC\x16\xAB\xAF\xD5\xBD\xEA\x95\x31\x09\x8E\xAD\x71\xA0\xBA\x58\x5D\xA8\xF6\xFE\x74\xFC\x64\x35\xAD\x5E\x0A\xCE\x96\x92\xAD\xB3\xA7\x9A\x5F\x13\xDB\xEA\xFF\xBA\x13\xD5\x9C\x11\x09\x8E\xAD\x33\x59\xE7\x7C\xCD\x38\x97\x82\x03\x04\x07\x82\x03\xC1\x01\x82\x03\xC1\x01\x82\x03\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x82\x03\x04\x07\x82\x03\x04\x07\x82\x03\xC1\x01\x82\x03\xC1\x01\x82\x03\xC1\x01\x82\x03\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x82\x03\x04\xC7\x60\x77\x75\xBC\xDA\xFB\x8B\xCF\x27\xD5\x91\xEA\xB0\x51\x8D\xDB\x4E\x23\x18\xBD\xD9\xEA\x54\x75\xB5\x9A\x5B\x67\xDD\x42\xF5\xAE\xBA\x53\x7D\xA9\xDE\x1A\x9D\xE0\xD8\xB8\x2B\xD5\xD9\xEA\x5C\xB5\x67\x9D\x75\xC7\xAA\xCB\xC3\xAE\x65\xA5\xBA\x61\x74\xE3\x33\x99\x4E\xA7\xA6\x30\x6E\x4F\xAB\xF9\x61\x5B\xF9\x3B\x9E\x57\x9F\xAA\xD3\x46\x27\x38\x36\x6E\xA9\xDA\xB7\x81\xF5\x5F\x86\xE0\xF6\x1B\xDD\xF8\xB8\x69\x02\x82\x03\xC1\xF1\x6F\x2C\x6F\x62\xFD\xB2\xB1\x09\x8E\xCD\x79\x58\xBD\xF8\xCD\xB5\x1F\xAB\x47\xC3\x77\x18\x21\x8F\x05\xC6\xEF\xD6\x10\xDC\x95\x7E\xDC\xFA\xFF\xD5\x8F\xE4\xFB\xEA\xFE\xB0\xFE\xB3\xB1\x09\x8E\xCD\x79\x52\xBD\x1E\xCE\xD5\xE2\x10\xDD\x5A\x1F\xAA\x07\xD5\xED\xEA\x71\xF5\xCD\xD8\xC6\xC9\x63\x81\xED\xE3\x50\x75\xAD\xBA\x54\x1D\xAD\x76\x0C\x57\xBB\xA5\x61\x0B\x79\x73\xD8\x4E\x7E\x35\x2A\x57\x38\xFE\xDC\xEA\xF3\xB5\x95\xE1\x7D\x35\xB8\x95\xE1\xF5\x59\x6C\xAE\x70\xC0\x4F\xDC\xA5\x04\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x82\x03\x04\x07\x82\x03\x04\x07\x82\x03\x04\x07\x82\x03\xC1\x01\x82\x03\xC1\x01\x82\x03\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x82\x03\x04\x07\x82\x03\x04\x07\x82\x03\xC1\x01\x82\x03\xC1\x01\x82\x03\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\xE0\xBF\xF0\x1D\x00\x00\xFF\xFF\x03\x00\xA8\x79\x49\x3A\x89\xCB\xC2\xFC\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"
local minutelineimgui = imgui.CreateTextureFromMemory(memory.strptr(minuteline), #minuteline)
local secondline = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\xDC\x00\x00\x00\xDC\x08\x06\x00\x00\x00\x1B\x5A\xCF\x81\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x0B\x13\x00\x00\x0B\x13\x01\x00\x9A\x9C\x18\x00\x00\x00\x20\x63\x48\x52\x4D\x00\x00\x7A\x25\x00\x00\x80\x83\x00\x00\xF9\xFF\x00\x00\x80\xE9\x00\x00\x75\x30\x00\x00\xEA\x60\x00\x00\x3A\x98\x00\x00\x17\x6F\x92\x5F\xC5\x46\x00\x00\x05\x71\x49\x44\x41\x54\x78\xDA\xEC\xDD\x3D\x72\xE3\x36\x18\x80\xE1\x0F\x22\x65\xC9\x72\x32\xD9\xD9\x32\xF5\x1E\x21\x5D\xBA\x9C\x22\x37\xCD\x3D\xD2\xE6\x16\x69\x52\xC4\x16\x52\x48\xDC\xD9\x40\x80\xF2\xB3\x1F\x34\x2E\x9E\x67\x66\x8B\xB5\x5D\x11\xF3\x0E\x01\x12\x24\x4B\xAD\x35\x80\xC7\xD8\x39\x04\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x08\x8E\xF7\xA1\x94\xF6\xFF\x1F\xA3\x94\x5F\xA3\x94\x7A\xFD\xF7\x5B\x94\xF2\xC9\x81\x12\x1C\x73\xBC\x45\x44\x6D\xC6\x70\x7F\x13\x26\x82\x23\xC5\x53\x44\xAC\xCD\x18\x1E\x22\x42\x71\x82\x63\x82\x7D\x33\x6E\x25\x22\x76\x61\x8F\x9E\xE0\x98\x62\x69\xCE\x66\xE5\x3A\xCD\x44\x70\x4C\xF0\xDA\xAC\xE1\xCE\x11\x51\xA3\x58\xC4\x09\x8E\x19\xEA\x35\xB2\x2F\xC7\x50\x6C\x82\x63\xE2\x1A\x6E\x69\xC6\xF0\xE0\xB0\x08\x8E\x39\x9E\x9A\xE0\x8C\xA3\xE0\x98\xC8\x45\x13\xC1\xF1\x40\xE7\xE6\xFF\xDB\x8D\x70\xEB\x38\xC1\x31\x41\x8D\xDB\x9D\x26\x8B\xC3\x22\x38\x1E\xB3\x86\x2B\x11\x71\x6C\x22\x44\x70\x24\x39\x34\xE3\xB6\x0B\xB7\x06\x04\xC7\x34\x6B\x33\x6E\x35\x6E\x37\x34\x23\x38\xBE\xDA\x65\x37\xC9\xB9\x89\xEB\x2D\x5C\xA5\x14\x1C\xD3\xB4\xC1\xAD\x71\xB9\x19\x6E\x4A\x29\x38\x26\xAD\xE1\xDA\xC7\x73\x8E\x0E\x8B\xE0\x98\x30\xA9\xBC\xC6\xD5\x5E\xA5\x74\x76\x13\x1C\x93\xB4\xCF\xC3\x9D\xE3\xF2\x04\x01\x82\x23\xD9\xF6\xA4\xC0\xB9\x39\xC3\x21\x38\x26\x4D\x29\x4B\x27\xC2\xD5\xA1\x11\x1C\x73\x82\x6B\x77\x9A\x2C\xE1\xF1\x1C\xC1\x31\xCD\x29\x6E\x2F\x9A\x2C\xC6\x52\x70\xCC\xB1\xC6\xDF\xEF\xC3\x6D\x3B\x4D\xCE\x0E\x8D\xE0\xC8\xF7\xD6\x59\xC3\x89\x4D\x70\x4C\x50\xE3\x76\xA3\xF2\x72\x5D\xD7\xD9\x4B\x29\x38\x92\x95\x88\x78\x8E\xDB\xE7\xDF\x8E\xC6\x52\x70\xCC\x0B\xEE\xF6\x45\xB0\xEE\xC7\x09\x8E\x29\xC1\xED\x3B\xD3\xC7\x57\x53\x4A\xC1\x91\xB2\x6A\xAB\xED\x1A\xAE\xF7\xFE\x12\xB1\x09\x8E\x9C\x73\x5A\x69\xCF\x70\xBD\xA9\xE3\xDE\x81\x12\x1C\x13\xCE\x77\x11\xF1\xD2\x89\xEE\x64\x2C\x05\x47\xBE\xE5\x1A\xDC\x62\x0C\x05\xC7\x03\x26\x98\x71\xFB\x74\xF7\xF6\xDA\x05\x37\xBF\x05\xC7\xA4\x69\x65\x7B\x91\xE4\x1C\x6E\x0B\x08\x8E\x8C\xBC\x6A\x1B\xD6\xDA\x19\x37\x4F\x0B\x08\x8E\x9C\x49\x64\x69\xC7\xEB\xD4\x99\x52\x0A\x4E\x70\x4C\x1A\xAF\x63\x13\xDC\xF6\xAA\x73\x53\x4A\xC1\x91\x3C\xA5\xDC\xCE\x66\xA5\x99\x66\x7A\x11\xAC\xE0\x98\x91\x5F\xE7\x6C\x56\xC5\x26\x38\xE6\x05\xD7\x6E\x54\x5E\xE3\xF2\x78\x8E\xB1\x14\x1C\x13\xC6\xEB\xD4\x59\xAF\x3D\x3B\x34\x82\x63\xCE\x78\xBD\x34\x3F\xF3\x78\x8E\xE0\x98\x64\x7B\x43\x57\xEF\x69\x01\x3B\x4D\x04\x47\xB2\xED\xC6\xB7\xD8\x04\xC7\x03\xD4\xCE\x98\xF5\xEE\xCD\x21\x38\x12\xA7\x94\xED\x18\xBA\x4A\x29\x38\x26\xD8\x47\xFF\xB5\xE6\x5E\x04\x2B\x38\x26\x8D\xD7\x6E\xB0\x86\xB3\x8E\x13\x1C\xC9\xDA\xAF\x9F\xB6\xE1\x21\x38\x52\x5C\xBE\xEF\x5D\x3A\x67\x32\x4F\x0B\x08\x8E\x74\xB5\x6E\x57\x28\x97\xCE\x18\x1E\x3B\x3F\x47\x70\x7C\xA5\xA7\x41\x58\x6E\x09\x08\x8E\x09\x7A\xCF\xBD\xD5\xF0\xC4\x80\xE0\x98\xE2\x3C\x58\xC3\x21\x38\x66\xAC\xE4\x3A\x67\xB2\xED\xAB\xA8\xC2\x13\x1C\xC9\x46\x37\xBE\x7D\x3D\x47\x70\x4C\xD0\xBB\x1A\x59\xC2\x15\x4A\xC1\x91\xEC\x72\x1F\xAE\x37\x5E\xE5\x8B\xE9\x26\x82\x23\xD1\xE8\x85\xAF\x45\x70\x82\x23\xD3\xE5\xC6\xF7\x28\xAC\x83\x69\xA5\xE0\xC8\xD7\x7B\xEB\xF2\x76\x95\xD2\x58\x0A\x8E\xE4\x35\xDC\x31\x6E\xAF\x52\xBA\x68\x22\x38\x26\x59\xEE\xFC\xDC\xE3\x39\x82\x23\x79\x0D\x37\x7A\xEE\xCD\xD6\x2E\xC1\x31\x61\x4A\x39\x7A\x1D\x9E\x35\x9C\xE0\x98\x60\xB4\xD3\xE4\x60\x2C\x05\x47\xF2\x39\x2E\xC6\x6F\x58\x5E\x8D\xA5\xE0\xC8\x0F\x6E\x1D\x4C\x29\xB7\x2F\xE8\x20\x38\x92\xFC\xD3\x85\x11\x17\x4D\x04\x47\x72\x70\xA3\xB0\xD6\x70\x2F\x4E\x70\xA4\x8F\xD5\x21\xFA\x17\x4D\xE2\xCE\xCF\x11\x1C\xFF\xD3\xF3\x60\x0D\xE7\xEB\x39\x82\x23\xD9\xB6\x67\xB2\x0E\xA6\x9B\x76\x9A\x08\x8E\x64\xE7\xC1\x5A\xCD\x37\xBE\x05\xC7\xA4\xF1\xEA\x85\xE5\xDB\x02\x82\x63\x82\xD1\xBB\x4B\x76\x71\xD9\x85\x82\xE0\x48\x1C\xAB\x6F\x62\xFC\x9A\x05\x17\x4D\x04\x47\xA2\x7A\x3D\x8B\xD9\x69\x22\x38\x1E\x60\x7B\xBD\x42\x1D\x04\xE7\xA2\x89\xE0\x48\x3E\xC3\xED\x06\x63\xB6\x84\x9D\x26\x82\x23\x7D\xAC\x46\xDF\xF2\x5E\xC2\x45\x13\xC1\x91\x3E\xA5\xFC\xF6\xCE\x98\x19\x4B\xC1\x91\x1C\xDC\xFE\xCE\x98\xBD\x3A\x44\x82\x23\x77\x0D\x37\x7A\x2F\xE5\x5B\xD8\xDA\x25\x38\xD2\x83\xDB\xDD\x59\xC3\xB9\x68\x22\x38\x12\x2D\x11\x71\x8A\xF1\x55\xCA\x27\x87\x48\x70\xE4\x06\xF7\x32\xF8\xDD\x39\x22\x76\x51\x6C\x36\x11\x1C\x99\x0E\x31\xDE\xC2\xF5\x67\x54\xF7\xBE\x05\x47\xE6\x1A\x6E\xBD\x13\x9C\x33\x9C\xE0\x48\x36\x0A\xEE\x29\x22\x3E\x3A\x3C\x82\x23\xCF\x4B\x44\x7C\x18\xFC\xEE\xBB\x88\xF8\xD1\x21\x12\x1C\x79\x7E\x88\x88\xEF\x07\xBF\x3B\x45\xC4\xCF\x0E\xD1\xFB\x57\xAA\x85\xF6\x3B\x1F\xA1\xCF\x33\xC8\x5F\x22\xE2\xA7\x18\x5F\xFE\xFF\x23\x22\x4E\x2E\x9C\x08\x8E\x9C\xE0\x7E\x8F\xCB\x5E\xCA\xBB\x7F\x2D\x38\xC1\x91\x13\xDC\xBF\x19\x28\xC1\x59\xC3\x91\xA0\x26\xFF\x1D\x82\x23\x25\xA2\x52\x6A\x94\x22\x3C\xC1\x01\x82\x03\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x40\x70\x40\x3E\xDF\x85\x7E\xFF\xB6\xCD\x94\xF5\x3F\xFE\x3D\xCE\x70\x3C\x28\x4E\xDE\xEB\x00\x79\x5A\x00\x9C\xE1\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x82\x03\x04\x07\x82\x03\x04\x07\x82\x03\xC1\x01\x82\x03\xC1\x01\x82\x03\xC1\x01\x82\x03\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x40\x70\x20\x38\x10\x1C\x20\x38\x10\x1C\x20\x38\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x10\x1C\x08\x0E\x04\x07\x08\x0E\x04\x07\x08\x0E\x04\x07\x82\x03\x04\x07\x82\x03\x04\x07\x82\x03\x04\x07\x82\x03\xC1\x01\x82\x03\xC1\x01\x82\x03\xC1\x81\xE0\x00\xC1\x81\xE0\x00\xC1\x81\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x80\xE0\x40\x70\x20\x38\x20\xD5\x5F\x03\x00\x5A\xBD\xB4\xAB\xC3\x33\x9A\xDA\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"
local secondlineimgui = imgui.CreateTextureFromMemory(memory.strptr(secondline), #secondline)
function Clock()
    local p = imgui.GetCursorScreenPos()
    local angle = 6.25
    local datetime = os.date("*t",os.time())
    local DayOfWeek = tonumber(os.date("%w",os.time({ year=datetime['year'],                                                                -- Получение дня недели по числу
        month = datetime['month'], day = datetime['day']})))
    local NowNameOfDay = NameOfDayOfWeek[DayOfWeek]                                                                                         -- Получение имени дня
    if DayOfWeek == 0 then DayOfWeek = 7 end
    imgui.SetCursorPos(imgui.ImVec2(variables['imgui']['WindowSize']['x']/2-120/2,1))            
    imgui.BeginChild("##Clock", imgui.ImVec2(150,50), true)  
        imgui.SameLine(40)  
        local hour = datetime['hour']   
        local min = datetime['min']        
        if datetime['hour'] < 10 then hour = '0'..tostring(datetime['hour']) end
        if datetime['min'] < 10 then min = '0'..tostring(datetime['min']) end
        imgui.PushFont(fontsize[18])
        imgui.Text(tostring(hour..':'..min))
        imgui.PopFont()
        imgui.PushFont(fontsize[13])
            imgui.Text(u8(tostring(NameOfDayOfWeek[DayOfWeek]..', '..datetime['day'] ..' '..os.date('%B'))))
        imgui.PopFont()
    imgui.EndChild()
    ImageRotated(clocklineimgui, imgui.ImVec2(p.x + 390.0, p.y + 170.0), imgui.ImVec2(248, 350.8), 0, 0xFFFFFFFF)                           -- Циферблат
    ImageRotated(hourlineimgui, imgui.ImVec2(p.x + 390.0, p.y + 170.0), imgui.ImVec2(100, 100), angle/12*datetime['hour'], 0xFFFFFFFF)      -- Часы
    ImageRotated(minutelineimgui, imgui.ImVec2(p.x + 390.0, p.y + 170.0), imgui.ImVec2(120, 120), angle/60*datetime['min'], 0xFFFFFFFF)     -- Минуты
    ImageRotated(secondlineimgui, imgui.ImVec2(p.x + 390.0, p.y + 170.0), imgui.ImVec2(120, 120), angle/60*datetime['sec'], 0xFFFFFFFF)     -- Секунды
    imgui.SetCursorPos(imgui.ImVec2(10,10))
    if imgui.ButtonHex(u8('Будильник'), 0x808080, imgui.ImVec2(100,20)) then variables['imgui']['Alarm'].v = not variables['imgui']['Alarm'].v end
    if imgui.ButtonHex(u8('Таймер'), 0x808080, imgui.ImVec2(100,20)) then variables['imgui']['Timer'].v = not variables['imgui']['Timer'].v end
    if imgui.ButtonHex(u8('Секундомер'), 0x808080, imgui.ImVec2(100,20)) then variables['imgui']['StopWatch'].v = not variables['imgui']['StopWatch'].v end
end

function Alarm() -- Будильник
    if imgui.ButtonHex(u8('Добавить будильник'), 0x808080, imgui.ImVec2(-0.1, 0)) then variables['imgui']['AddAlarm'].v = not variables['imgui']['AddAlarm'].v end
    imgui.Separator()
    if NoteInAlarm ~= nil then
        for Key, Value in pairs(NoteInAlarm) do
            imgui.BeginChild('##'..Key..'alarm',imgui.ImVec2(-0.1, 60),true)
                local hour = Value['hour']
                if hour < 10 then hour = '0'..hour end
                local minute = Value['minute']
                if minute < 10 then minute = '0'..minute end
                imgui.ButtonHex(u8(hour..':'..minute), NoteInAlarm[Key]['active'] and 0x4169E1 or 0x808080, imgui.ImVec2(100,20))
                imgui.SameLine()
                if imadd.ToggleButton("##"..Key,  imgui.ImBool(NoteInAlarm[Key]['active'])) then -- Включен или выключен
                    NoteInAlarm[Key]['active'] = not NoteInAlarm[Key]['active']
                end
                imgui.SameLine()
                if imgui.ButtonHex(u8('Удалить'), 0xff0000, imgui.ImVec2(70,20)) then NoteInAlarm[Key] = nil end -- Удаление будильника
                if NoteInAlarm[Key] ~= nil then
                    for Keys, Values in pairs(NoteInAlarm[Key]['days']) do
                        if Values == true then 
                            imgui.Text(u8(Keys))
                            imgui.SameLine()
                        end
                    end  
                end 
            imgui.EndChild()
        end
    end
end

function AddAlarm() -- Добавление будильника с настройками (Время, дни недели)
    imgui.SliderInt(u8"Час:", variables['imgui']['Hour'], 1, 23) 
    imgui.SliderInt(u8"Минуты:", variables['imgui']['Minute'], 1, 59)
    for Key, Value in ipairs(ActiveDays['name']) do
        imgui.Text(u8(Value))
        imgui.SameLine()
        imadd.ToggleButton("##"..Key..'Add', ActiveDays['imgui'][Key]) 
        if Key ~= 4 and Key < 7 then imgui.SameLine() imgui.Text('   ') imgui.SameLine() end
    end
    if imgui.ButtonHex(u8('Сохранить будильник'), 0x808080, imgui.ImVec2(-0.1, 0)) then 
        sampAddChatMessage('[{FF9900}Phone Apps{FFFFFF}] Будильник сохранён{990000}!', -1) 
        table.insert( NoteInAlarm, {
            ['active'] = false,
            ['days'] = {
                ['ПН'] = ActiveDays['imgui'][1].v, 
                ['ВТ'] = ActiveDays['imgui'][2].v, 
                ['СР'] = ActiveDays['imgui'][3].v, 
                ['ЧТ'] = ActiveDays['imgui'][4].v, 
                ['ПТ'] = ActiveDays['imgui'][5].v, 
                ['СБ'] = ActiveDays['imgui'][6].v, 
                ['ВС'] = ActiveDays['imgui'][7].v, 
            },
            ['hour'] = variables['imgui']['Hour'].v,
            ['minute'] = variables['imgui']['Minute'].v
        })
    end
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		SaveJSON('calendar', NoteInDate)  
        SaveJSON('alarm', NoteInAlarm)  
        table.remove(Playlists,1)
        SaveJSON('music', Playlists)  
	end
end  
-- [ Доп.функции ]
function imgui.Hint(text, delay)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 5 
        if os.clock() >= go_hint then
            imgui.BeginTooltip()
            imgui.PushTextWrapPos(450)
            imgui.TextUnformatted(text)
            if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
            imgui.PopTextWrapPos()
            imgui.EndTooltip()
        end
    end
end

function imgui.BeginTitleChild(str_id, size, color, offset)
    color = color or imgui.GetStyle().Colors[imgui.Col.Border]
    offset = offset or 30
    local DL = imgui.GetWindowDrawList()
    local posS = imgui.GetCursorScreenPos()
    local rounding = imgui.GetStyle().ChildRounding
    local title = str_id:gsub('##.+$', '')
    local sizeT = imgui.CalcTextSize(title)
    local padd = imgui.GetStyle().WindowPadding
    local bgColor = imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.WindowBg])
    imgui.BeginChild(str_id, size, true)
    size.x = size.x == -1.0 and imgui.GetWindowWidth() or size.x
    size.y = size.y == -1.0 and imgui.GetWindowHeight() or size.y
    DL:AddRect(posS, imgui.ImVec2(posS.x + size.x, posS.y + size.y), imgui.ColorConvertFloat4ToU32(color), rounding, _, 1)
    DL:AddLine(imgui.ImVec2(posS.x + offset - 3, posS.y), imgui.ImVec2(posS.x + offset + sizeT.x + 3, posS.y), bgColor, 3)
    DL:AddText(imgui.ImVec2(posS.x + offset, posS.y - (sizeT.y / 2)), imgui.ColorConvertFloat4ToU32(color), title)
end

function imgui.ButtonHex(lable, rgb, size, rounding)
    if rounding == nil then
        rounding = 1
    end
    local r = bit.band(bit.rshift(rgb, 16), 0xFF) / 255
    local g = bit.band(bit.rshift(rgb, 8), 0xFF) / 255
    local b = bit.band(rgb, 0xFF) / 255

    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r, g, b, 0.6))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r, g, b, 0.8))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(r, g, b, 1.0))
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding,rounding)
    local button = imgui.Button(lable, size)
    imgui.PopStyleVar(1)
    imgui.PopStyleColor(3) 
    return button
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

HeaderButton = function(bool, str_id)
    local DL = imgui.GetWindowDrawList()
    local ToU32 = imgui.ColorConvertFloat4ToU32
    local result = false
    local label = string.gsub(str_id, "##.*$", "")
    local duration = { 0.5, 0.3 }
    local cols = {
        idle = imgui.GetStyle().Colors[imgui.Col.TextDisabled],
        hovr = imgui.GetStyle().Colors[imgui.Col.Text],
        slct = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
    }

    if not AI_HEADERBUT then AI_HEADERBUT = {} end
     if not AI_HEADERBUT[str_id] then
        AI_HEADERBUT[str_id] = {
            color = bool and cols.slct or cols.idle,
            clock = os.clock() + duration[1],
            h = {
                state = bool,
                alpha = bool and 1.00 or 0.00,
                clock = os.clock() + duration[2],
            }
        }
    end
    local pool = AI_HEADERBUT[str_id]

    local degrade = function(before, after, start_time, duration)
        local result = before
        local timer = os.clock() - start_time
        if timer >= 0.00 then
            local offs = {
                x = after.x - before.x,
                y = after.y - before.y,
                z = after.z - before.z,
                w = after.w - before.w
            }

            result.x = result.x + ( (offs.x / duration) * timer )
            result.y = result.y + ( (offs.y / duration) * timer )
            result.z = result.z + ( (offs.z / duration) * timer )
            result.w = result.w + ( (offs.w / duration) * timer )
        end
        return result
    end

    local pushFloatTo = function(p1, p2, clock, duration)
        local result = p1
        local timer = os.clock() - clock
        if timer >= 0.00 then
            local offs = p2 - p1
            result = result + ((offs / duration) * timer)
        end
        return result
    end

    local set_alpha = function(color, alpha)
        return imgui.ImVec4(color.x, color.y, color.z, alpha or 1.00)
    end

    imgui.BeginGroup()
        local pos = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
       
        imgui.TextColored(pool.color, label)
        local s = imgui.GetItemRectSize()
        local hovered = imgui.IsItemHovered()
        local clicked = imgui.IsItemClicked()
       
        if pool.h.state ~= hovered and not bool then
            pool.h.state = hovered
            pool.h.clock = os.clock()
        end
       
        if clicked then
            pool.clock = os.clock()
            result = true
        end

        if os.clock() - pool.clock <= duration[1] then
            pool.color = degrade(
                imgui.ImVec4(pool.color),
                bool and cols.slct or (hovered and cols.hovr or cols.idle),
                pool.clock,
                duration[1]
            )
        else
            pool.color = bool and cols.slct or (hovered and cols.hovr or cols.idle)
        end

        if pool.h.clock ~= nil then
            if os.clock() - pool.h.clock <= duration[2] then
                pool.h.alpha = pushFloatTo(
                    pool.h.alpha,
                    pool.h.state and 1.00 or 0.00,
                    pool.h.clock,
                    duration[2]
                )
            else
                pool.h.alpha = pool.h.state and 1.00 or 0.00
                if not pool.h.state then
                    pool.h.clock = nil
                end
            end

            local max = s.x / 2
            local Y = p.y + s.y + 3
            local mid = p.x + max

            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid + (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid - (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
        end

    imgui.EndGroup()
    return result
end

function imgui.CloseButton(rad, bool)
    local pos = imgui.GetCursorScreenPos()
    local poss = imgui.GetCursorPos()
    local a, b, c, d = pos.x - rad, pos.x + rad, pos.y - rad, pos.y + rad
    local e, f = poss.x - rad, poss.y - rad
    local drawList = imgui.GetWindowDrawList()
    drawList:AddLine(imgui.ImVec2(a, d), imgui.ImVec2(b, c), cbcolor and cbcolor or -1)
    drawList:AddLine(imgui.ImVec2(b, d), imgui.ImVec2(a, c), cbcolor and cbcolor or -1)
    imgui.SetCursorPos(imgui.ImVec2(e, f))
    if imgui.InvisibleButton('##closebut', imgui.ImVec2(rad * 2, rad * 2)) then
        bool.v = false
    end
    cbcolor = imgui.IsItemHovered() and 0xFF707070 or nil
end

function SaveJSON(name, table)                                                                                           -- Сохранение JSON файла
    encodedTable = encodeJson(table)                                                                                    -- превращаем наш Lua массив в JSON
    local file = io.open(getWorkingDirectory()..'/config/PhoneApps/'..name..'.json', "w")
    file:write(encodedTable)                                                                                            -- Записываем нашу таблицу
    file:flush()                                                                                                        -- Сохраняем
    file:close()                                                                                                        -- Закрываем
end

function math.eval(str)
    -- Calculate string math expression (without function)
    str = str:gsub(" ", "")
    if str == "" or type(str) ~= "string" then return false end
  
    function pop(t)
      -- Delete the last element of a table and return it
      local d = t[#t];table.remove(t, #t);return d
    end
  
    function styard(str)
      -- Convert infix to post fix with shunting yard algorithm
  
      function fotab (str)
        -- Formula to table
        -- LeftBracket(0 or more) Signe+-(0 or 1) Number(int or float with comma) RightBracket(0 or more) Operator(0 or 1)
        -- Exemple "-4*10.54+((10+8)*3.141592)" -> {"-","4","*","10.54","+","(","(","10",...}
        local t = {}
        for lb, s, n, rb, o in str:gmatch("(%(*)([-+^]?)(%d+%.?%d*)(%)*)([-*/+^]?)") do
          local raw_t = {lb, s, n, rb, o}
          for i=1,#raw_t do
            if raw_t[i] ~= "" then
              table.insert(t, raw_t[i])
            end
          end
        end
        for i=1,#t do
          if #t[i] > 1 and (t[i]:match("%(+") or t[i]:match("%)+")) then
            local h, c = #t[i]-1, t[i]:sub(1, 1)
            t[i] = c
            for j=1,h do
              table.insert(t, i, c)
            end
          end
        end
        return t
      end
  
      local tokens, queue, stack, operators = fotab(str), {}, {}, {}
      operators["^"] = {4, "Right"}
      operators["/"] = {3, "Left"}
      operators["*"] = {3, "Left"}
      operators["+"] = {2, "Left"}
      operators["-"] = {2, "Left"}
  
      for i=1,#tokens do
        if tokens[i]:find('%d') then
          table.insert(queue, tokens[i])
        elseif tokens[i]:find('[+/*^-]') then
          local o1, o2 = tokens[i], stack[#stack]
          while (o2 ~= nil and o2:find('[+/*^-]') and ((operators[o1][2] == "Left" and operators[o1][1] <= operators[o2][1]) or (operators[o1][2] == "Right" and operators[o1][1] < operators[o2][1]))) do
            table.insert(queue, pop(stack))
            o2 = stack[#stack]
          end
          table.insert(stack, o1)
        elseif tokens[i] == '(' then
          table.insert(stack, tokens[i])
        elseif tokens[i] == ')' then
          while(stack[#stack] ~= "(") do
            table.insert(queue, pop(stack))
          end
          pop(stack)
        end
      end
      while #stack > 0 do
        table.insert(queue, pop(stack))
      end
      return queue
    end
  
    local tokens, solution = styard(str), {}
  
    for i=1,#tokens do
      local token = tokens[i]
      if token:find('%d') then
        table.insert(solution, token)
      else
        local o2, o1 = pop(solution), pop(solution)
        if token == "+" then
          table.insert(solution, o1+o2)
        elseif token == "-" then
          table.insert(solution, o1-o2)
        elseif token == "*" then
          table.insert(solution, o1*o2)
        elseif token == "/" then
          table.insert(solution, o1/o2)
        elseif token == "^" then
          table.insert(solution, o1^o2)
        end
      end
    end
    return solution[1]
end

function darkgreentheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding       = ImVec2(10, 10)
    style.WindowRounding      = 15
    style.ChildWindowRounding = 10
    style.FramePadding        = ImVec2(5, 4)
    style.FrameRounding       = 15
    style.ItemSpacing         = ImVec2(4, 4)
    style.TouchExtraPadding   = ImVec2(0, 0)
    style.IndentSpacing       = 21
    style.ScrollbarSize       = 16
    style.ScrollbarRounding   = 16
    style.GrabMinSize         = 11
    style.GrabRounding        = 16
    style.WindowTitleAlign    = ImVec2(0.5, 0.5)
    style.ButtonTextAlign     = ImVec2(0.5, 0.5)

    colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 0.78)
    colors[clr.TextDisabled]         = ImVec4(0.36, 0.42, 0.47, 1.00)
    colors[clr.WindowBg]             = ImVec4(0.11, 0.15, 0.17, 1.00)
    colors[clr.ChildWindowBg]        = ImVec4(0.11, 0.15, 0.17, 1.00)
    colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]              = ImVec4(0.25, 0.29, 0.20, 1.00)
    colors[clr.FrameBgHovered]       = ImVec4(0.12, 0.20, 0.28, 1.00)
    colors[clr.FrameBgActive]        = ImVec4(0.09, 0.12, 0.14, 1.00)
    colors[clr.TitleBg]              = ImVec4(0.09, 0.12, 0.14, 0.65)
    colors[clr.TitleBgActive]        = ImVec4(0.35, 0.58, 0.06, 1.00)
    colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.MenuBarBg]            = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab]        = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
    colors[clr.ScrollbarGrabActive]  = ImVec4(0.09, 0.21, 0.31, 1.00)
    colors[clr.ComboBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.CheckMark]            = ImVec4(0.72, 1.00, 0.28, 1.00)
    colors[clr.SliderGrab]           = ImVec4(0.43, 0.57, 0.05, 1.00)
    colors[clr.SliderGrabActive]     = ImVec4(0.55, 0.67, 0.15, 1.00)
    colors[clr.Button]               = ImVec4(0.01, 0.40, 0.10, 1.00)
    colors[clr.ButtonHovered]        = ImVec4(0.45, 0.69, 0.07, 1.00)
    colors[clr.ButtonActive]         = ImVec4(0.27, 0.50, 0.00, 1.00)
    colors[clr.Header]               = ImVec4(0.20, 0.25, 0.29, 0.55)
    colors[clr.HeaderHovered]        = ImVec4(0.72, 0.98, 0.26, 0.80)
    colors[clr.HeaderActive]         = ImVec4(0.74, 0.98, 0.26, 1.00)
    colors[clr.Separator]            = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.SeparatorHovered]     = ImVec4(0.60, 0.60, 0.70, 1.00)
    colors[clr.SeparatorActive]      = ImVec4(0.70, 0.70, 0.90, 1.00)
    colors[clr.ResizeGrip]           = ImVec4(0.68, 0.98, 0.26, 0.25)
    colors[clr.ResizeGripHovered]    = ImVec4(0.72, 0.98, 0.26, 0.67)
    colors[clr.ResizeGripActive]     = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton]          = ImVec4(0.40, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered]   = ImVec4(0.40, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg]       = ImVec4(0.25, 1.00, 0.00, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)

end
darkgreentheme()

function ImRotate(v, cos_a, sin_a) return imgui.ImVec2(v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a); end
function calcAddImVec2(l, r) return imgui.ImVec2(l.x + r.x, l.y + r.y) end
function ImageRotated(tex_id, center, size, angle, color)
   local color = color or 0xFFFFFFFF
   local drawlist = imgui.GetWindowDrawList()
   local cos_a = math.cos(angle)
   local sin_a = math.sin(angle)
   local pos = {
      calcAddImVec2(center, ImRotate(imgui.ImVec2(-size.x * 0.5, -size.y * 0.5), cos_a, sin_a)),
      calcAddImVec2(center, ImRotate(imgui.ImVec2(size.x * 0.5, -size.y * 0.5), cos_a, sin_a)),
      calcAddImVec2(center, ImRotate(imgui.ImVec2(size.x * 0.5, size.y * 0.5), cos_a, sin_a)),
      calcAddImVec2(center, ImRotate(imgui.ImVec2(-size.x * 0.5, size.y * 0.5), cos_a, sin_a))
    }
    local uvs =
    {
      imgui.ImVec2(0.0, 0.0),
      imgui.ImVec2(1.0, 0.0),
      imgui.ImVec2(1.0, 1.0),
      imgui.ImVec2(0.0, 1.0)
    }
    drawlist:AddImageQuad(tex_id, pos[1], pos[2], pos[3], pos[4], uvs[1], uvs[2], uvs[3], uvs[4], color)
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

function imgui.GetCenter()
    local width = imgui.GetWindowWidth()
    return width / 2
end
