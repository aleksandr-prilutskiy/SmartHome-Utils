#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	Smart Home Framework
	Filename.......:	SmartHomeFramework.au3
	Description....:	Система "Умный дом". Фреймворк для создания утилит системы "Умный дом"
	Author(s)......:	Aleksandr Prilutskiy

	Remarks........:	Шаблон типового приложения-утилиты:
=================================================================================================================
#Region Initialization
#pragma compile(Out, ..\Bin\{имя файла}.exe)
#pragma compile(Icon, ..\Resources\Icons\{пиктограмма}.ico)
#pragma compile(ProductName, Smart Home Server - {название})
#pragma compile(FileVersion, {версия})
#pragma compile(LegalCopyright, {copyright})
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <..\UDFs\SmartHomeFramework.au3>
...
Opt("TrayIconHide", 1)
		$sAppTitle				= '{имя файла}'							; имена файлов приложения (exe, log..)
		$sAppShortName			= '{название}'							; краткое название приложения
...
#EndRegion Initialization

#Region Main Script
_AppStart('{каталог}\')													; подготовка приложения к работе
_Main()																	; основное выполение приложения
_AppExit()																; завершение работы приложения
#EndRegion Main Script
=================================================================================================================

#CURRENT# =======================================================================================================

Функции организации работы приложений:
_AppStart				- Подготовка программы к работе
_LoadConfigFile			- Загрузка настроек программы из файла конфигурации
_CreateTempDir			- Создание каталога размещения временных файлов
_AppExit				- Завершение работы программы

Функции ведения журналов событий:
_LogWrite				- Вывод сообщения на экран и запись его в файл журнала
_SysyemLogWrite			- Добавление записи в журнал событий системы "Умный дом"
_GetTimeStamp			- Получение текущего времени в стандартном виде

Функции работы с базой данных:
_MySQL_Start			- Инициализация работы с базой данных и создание файла журнала
_MySQL_CheckTable		- Проверка существования таблицы в базе данных
_MySQL_DropTable		- Удаление таблицы из базы данных
_MySQL_GetCount			- Подсчет количества элементов в таблице
_MySQL_ReadConfig		- Чтение строки из таблицы настроек системы "Умный дом"
_MySQL_Query			- Выполнение запроса к базе данных
_MySQL_StringCode		- Преобразование текстовой строки в формат MySQL
_MySQL_Log				- Добавление записи в журнал работы с базой данных
_MySQL_End				- Завершение работы с базой данных

Строковые функции:
_StringGetKey			- Получение значения тэга в строке
_StringURLEncode		- Кодирование текстовой строки в формате URL
_String_LiteralsDecode	- Декодирование текстовой строки, содержащей символьные литералы
_String_ANSIToOEM		- Преобразование строки из кодировки ANSI в OEM
_StringToUTF8			- Преобразование строки в кодировку UTF8
_StringToUTF8_X			- Заменяет в строке символы, кодируемые 2мя байтами и более
_TimeToString			- Отображение временного интервала в виде текстовой строки

Фунцкии обработки чисел:
_Max					- Выбор наибольшего значения из двух чисел
_Min					- Выбор наименьшего значения из двух чисел
=================================================================================================================
#CE
#EndRegion Header

#Region Initialization
#include <String.au3>
#include <Array.au3>
#include <Crypt.au3>
#include <AutoItConstants.au3>
#include <FileConstants.au3>

; константы режима отладки
Global Enum _
 $_DEBUG_MODE_OFF, _													; без протоколирования работы
 $_DEBUG_MODE_ERROR, _													; запись только ошибок
 $_DEBUG_MODE_ALL														; запись всех SQL-запросов

; константы режима контроля многократного запуска приложения
Global Enum _
 $_MULTIRUN_MODE_DISABLE, _												; многократный запуск запрещен
 $_MULTIRUN_MODE_ENABLE													; многократный запуск разрешен

; константы свойст сетевых устройств
Global	$device_option_Ping			= 0x0001;
Global	$device_option_Can_Off		= 0x0002;
Global	$device_option_Can_On		= 0x0004;
Global	$device_option_All_Off		= 0x0008;
Global	$device_option_Play_Music	= 0x0010;
Global	$device_option_Play_Video	= 0x0020;

Global	$sProjectName			= "Smart Home Server"					; наименование проекта
Global	$sAppTitle				= ''									; заголовок программы
Global	$sAppShortName			= ''									; краткое название программы
Global	$sAppName				= $sProjectName & '. '					; полное название программы
Global	$AppVersion				= ''									; текущая версия программы
Global	$sIniFileName			= @ScriptDir & "\SmartHomeServer.ini"	; имя файла конфигурации программы
Global	$sLogFileName			= ''									; имя файла журнала
Global	$DEBUG					= False									; признак режима отладки
Global	$sEncryptKey			= 'pgXQt5oXDA'							; ключ шифрования пароля в ini-файле
Global	$sServerAppDir			= @ScriptDir							; корневой каталог сервера
Global	$sAppTempDir			= ''									; каталог размещения временных файлов
Global	$AppTimer				= TimerInit()							; таймер времени выполнения программы
Global	$sSQL_Driver			= "{MySQL ODBC 3.51 Driver}"			; имя используемого драйвера баз данных
Global	$sSQL_Host				= "127.0.0.1"							; адрес сервера баз данных
Global	$sSQL_Database			= "test"								; имя базы данных
Global	$sSQL_Username			= "root"								; логин для подключения к базе данных
Global	$sSQL_Password			= ""									; пароль для подключения к базе данных
Global	$sSQL_LogFileName		= ""									; имя файла журнала операций с базой данных
Global	$SQL					= -1									; экземпляр объекта для работы с СУБД
Global	$iSQL_DebugMode			= $_DEBUG_MODE_ERROR					; выбор уровня протоколирования работы
Global	$iMultiRunMode			= $_MULTIRUN_MODE_DISABLE				; режим контроля многократного запуска
Global	$oMySQLError			= ObjEvent("AutoIt.Error","_MySQLError"); обработка ошибок при работе с СУБД
#EndRegion Initialization

#Region Database Tables
;------------------------------------------ Наименования таблиц в базе данных -----------------------------------
; 1. Основные таблицы системы
Global	$sDB_TableConfig			= "config"							; таблица настроек системных переменных
Global	$sDB_TableUser				= "user"							; таблица со списком пользователей
Global	$sDB_TableEvents			= "events"							; таблица событий системы
Global	$sDB_TableShedule			= "shedule"							; таблица рассписания событий системы
Global	$sDB_TableScripts			= "scripts"							; таблица сценариев
Global	$sDB_TableStates			= "variables"						; таблица переменных системы
Global	$sDB_TableLog				= "system_log"						; таблица журнала событий системы

; 2. Таблицы для работы с устройствами и датчиками в сети
Global	$sDB_TableDevices			= "devices"							; список устройств "Умного дома"
Global	$sDB_TableSensors			= "sensors"							; список датчиков "Умного дома"
Global	$sDB_TableSensorsData		= "sensors_data"					; значения показаний датчиков "Умного дома"
Global	$sDB_Table_nooLite		    = "noolite"							; для устройств nooLite

; 3. Таблицы настройки веб-интерфейса системы
Global	$sDB_TableUserWidgets		= "user_widgets"					; таблица настроек виджетов главной страницы
Global	$sDB_TableMediaFavorite		= "media_favorite"					; таблица избранного медиаконтента пользователей
Global	$sDB_TableMediaBrowsed		= "media_browsed"					; таблица просмотреного медиаконтента

; 4. Таблицы для мультимедиа контента
; создаются утилитой Music.au3
Global	$sDB_TableMusicFiles		= "music_files"						; таблица музыкальных файлов
Global	$sDB_TableMusicAlbums		= "music_albums"					; таблица альбомов музыкальных файлов
Global	$sDB_TableMusicArtists		= "music_artists"					; таблица исполнителей музыкальных файлов
; создаются утилитой Movies.au3
Global	$sDB_TableMoviesFiles		= "movies_files"					; таблица файлов с фильмами
Global	$sDB_TableMoviesInfo		= "movies_info"						; таблица информации о фильмах
Global	$sDB_TableMoviesCollections	= "movies_collections"				; таблица коллекций фильмов
Global	$sDB_TableMoviesMetadata	= "movies_metadata"					; таблица метаданных, связанных с фильмами
; создаются утилитой Series.au3
Global	$sDB_TableSeriesFiles		= "series_files"					; таблица файлов сериалов
Global	$sDB_TableSeriesInfo		= "series_info"						; таблица информации о сериалах
Global	$sDB_TableSeriesSeasons		= "series_seasons"					; таблица сезонов сериалов
; создаются утилитой Photo.au3
Global	$sDB_TablePhotoFiles		= "photo_files"						; таблица файлов фотографий
Global	$sDB_TablePhotoAlbums		= "photo_albums"					; таблица альбомов фотографий
; создаются утилитой TV_Program.au3
Global	$sDB_TableTVChannels		= "tv_channel"						; таблица списка телевизионных каналов
Global	$sDB_TableTVChannelMap		= "tv_channel_map"					; привязка телевизионных каналов к телевизорам
Global	$sDB_TableTVProgram			= "tv_program"						; таблица списка телевизионных програм

; 5. Прочие таблицы
; создаются утилитой SysInfo.au3
Global	$sDB_TableSysInfo		= "server_sysinfo"						; информация об аппаратных ресурсах сервера
; создаются утилитой SMART.au3
Global	$sDB_TableSysSMART		= "server_smart_hdd"					; таблица S.M.A.R.T. жестких дисков
; создаются утилитой Weather.au3
Global	$sDB_TableWeather		= "weather_forecast"					; таблица с прогнозом погоды
#EndRegion Database Tables

#Region Application Functions
;---------------------------------------- ФУНКЦИИ ОРГАНИЗАЦИИ РАБОТЫ ПРИЛОЖЕНИЙ ---------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_AppStart
; Description....:	Подготовка программы к работе
; Syntax.........:	_AppStart()
; Date...........:	08.02.2019
; ===============================================================================================================
Func _AppStart()
 Local $i
 If $sAppTitle == '' Then
  $sAppTitle = @ScriptName
  $i = StringInStr($sAppTitle, ".", -1)
  If $i > 0 Then $sAppTitle = StringLeft($sAppTitle, $i - 1)
 EndIf
 If $sAppShortName == '' Then $sAppShortName = $sAppTitle
 $sAppName &= $sAppShortName
 _LoadConfigFile()
 _MySQL_Start()
 $copycount = 0
 If $iMultiRunMode <> $_MULTIRUN_MODE_ENABLE Then
  Local $aProcess = ProcessList(@ScriptName)
  For $i = 1 To UBound($aProcess) - 1
   If $aProcess[$i][1] <> @AutoItPID Then ContinueLoop
   $copycount += 1
   If $copycount > 1 Then
    _LogWrite("Копия программы уже запущена.")
    _SysyemLogWrite(0, 1, "Предотвращен повторный запуск программы")
    _AppExit()
   EndIf
  Next
 EndIf
 $sLogFileName = $sServerAppDir & '\logs\' & $sAppTitle & '.log'
 If FileExists($sLogFileName) Then FileDelete($sLogFileName)
 _LogWrite($sAppName & ' v.' & $AppVersion)
 For $i = 2 To $CmdLine[0]
  If $CmdLine[$i] == '/debug' Then
   $DEBUG = True
   $iSQL_DebugMode = $_DEBUG_MODE_ALL
   _LogWrite("Активирован режим отладки!")
   ExitLoop
  EndIf
 Next
 _LogWrite()
EndFunc ;==>_AppStart

; #FUNCTION# ====================================================================================================
; Name...........:	LoadConfigFile
; Description....:	Загрузка настроек программы из файла конфигурации
; Syntax.........:	LoadConfigFile()
; ===============================================================================================================
Func _LoadConfigFile()
 Local $n = StringInStr($sIniFileName, "\", 0, -1)
 If $n > 0 Then $sIniFileName = StringTrimLeft($sIniFileName, $n)
 $sServerAppDir = @ScriptDir
 While True
  Local $sNewIniFileName = $sServerAppDir & "\" & $sIniFileName
  If FileExists($sNewIniFileName) Then ExitLoop
  $pos = StringInStr($sServerAppDir, "\", 0, -1)
  If $pos == 0 Then
   _LogWrite("Ошибка: не найден файл '" & $sIniFileName & "'")
   Exit
  EndIf
  $sServerAppDir = StringLeft($sServerAppDir, $pos - 1)
 WEnd
 $sIniFileName 	    = $sNewIniFileName
 $sSQL_Host			= IniRead($sIniFileName, 'Database', 'Host', $sSQL_Host)
 $sSQL_Database		= IniRead($sIniFileName, 'Database', 'Name', $sSQL_Database)
 $sSQL_Username		= IniRead($sIniFileName, 'Database', 'User', $sSQL_Username)
 $sSQL_Password		= IniRead($sIniFileName, 'Database', 'Password', '')
 $AppVersion		= FileGetVersion(@ScriptFullPath, 'FileVersion')
EndFunc ;==>LoadConfigFile

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateTempDir
; Description....:	Создание каталога размещения временных файлов
; Syntax.........:	_CreateTempDir()
; Return Value(s):  On Success	- True
;                   On Failure	- False
; ===============================================================================================================
Func _CreateTempDir()
 Local $i = 0
 While True
  Local $sTempDir = @TempDir & "\smart_home_temp_dir_#" & $i
  If Not FileExists($sTempDir) Then ExitLoop
  $i += 1
 WEnd
 DirCreate($sTempDir)
 If FileExists($sTempDir) Then
  _LogWrite("Создан каталог размещения временных файлов: " & $sTempDir)
  $sAppTempDir = $sTempDir
  Return True
 EndIf
 _LogWrite("Ошибка: Невозможно создать каталог размещения временных файлов")
 Return False
EndFunc ;==>_CreateTempDir

; #FUNCTION# ====================================================================================================
; Name...........:	_AppExit
; Description....:	Завершение работы программы
; Syntax.........:	_AppExit()
; ===============================================================================================================
Func _AppExit()
 _MySQL_End()
 If ($sAppTempDir <> '') And FileExists($sAppTempDir) Then
  DirRemove($sAppTempDir, $DIR_REMOVE)
  If Not FileExists($sAppTempDir) Then
   _LogWrite("Каталог размещения временных файлов удален")
   $sAppTempDir = ''
  Else
   _LogWrite("Ошибка: Невозможно удалить каталог размещения временных файлов")
  EndIf
 EndIf
 _LogWrite("Время выполнения программы: " & _TimeToString(TimerDiff($AppTimer)))
 Exit
EndFunc ;==>_AppExit
#EndRegion Application Functions

#Region Log Functions
;------------------------------------------- ФУНКЦИИ ВЕДЕНИЯ ЖУРНАЛОВ СОБЫТИЙ -----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_LogWrite
; Description....:	Вывод сообщения на экран и запись его в файл журнала
; Syntax.........:	_LogWrite()
; ===============================================================================================================
Func _LogWrite($sText = "")
 ConsoleWrite(@Compiled ? _String_ANSIToOEM($sText & @CRLF) : $sText & @CRLF)
 If $sLogFileName == '' Then Return
 Local $hLogFile = FileOpen($sLogFileName, BitOR($FO_CREATEPATH, $FO_APPEND))
 If @error Then Return
 FileWrite($hLogFile, $sText & @CRLF)
 FileClose($hLogFile)
EndFunc ;==>_LogWrite

; #FUNCTION# ====================================================================================================
; Name...........:	_SysyemLogWrite
; Description....:	Добавление записи в журнал событий системы "Умный дом" (в базе данных)
; Syntax.........:	_SysyemLogWrite($iRecords, $iErrors[, $sText[, $sEvent, [, $fSaveFile]]])
; Parameter(s)...:	$iRecords	- количество успешно изменныных записей в базе данных
;					$iErrors	- количество выявленных ошибок
;					$sText		- краткое описание события
;					$sEvent		- название события
;					$fSaveFile	- если TRUE, то в журнал событий записывается файл журнала работы программы
; ===============================================================================================================
Func _SysyemLogWrite($iRecords, $iErrors, $sText = "", $sEvent = "", $fSaveFile = True)
 Local $ErrorFlag = 0
 If $iErrors <> 0 Then
  $ErrorFlag = 1
  If $sEvent == "" Then $sEvent = "Выполнено с ошибками"
 EndIf
 If $sEvent == "" Then $sEvent = "Успешное завершение"
 If $sText == "" Then
  If $iRecords > 0 Then $sText = "Обновлено записей: " & $iRecords
  If $iErrors > 0 Then
   If $sText <> "" Then $sText &= ". "
   $sText &= "Всего ошибок: " & $iErrors
  EndIf
 EndIf
 Local $sLogFile = ""
 If $fSaveFile Then
  Local $hLogFile = FileOpen($sLogFileName, $FO_READ)
  If $hLogFile <> -1 Then
   $sLogFile = FileRead($hLogFile)
   FileClose($hLogFile)
  EndIf
 EndIf
 _MySQL_Query("INSERT INTO `" & $sDB_TableLog & "` " & _
 "(creator, event, description, error, logfile) VALUES (" & _
      "'" & _MySQL_StringCode($sAppShortName) & "'," & _	; creator
      "'" & _MySQL_StringCode($sEvent) & "'," & _			; event
      "'" & _MySQL_StringCode($sText) & "'," & _			; description
      "'" & $ErrorFlag & "'," & _							; error
      "'" & _MySQL_StringCode($sLogFile)  & "');")			; logfile
EndFunc ;==>_SysyemLogWrite

; #FUNCTION# ====================================================================================================
; Name...........:	_GetTimeStamp
; Description....:	Получение текущего времени в стандартном виде (день.месяц.год часы:минуты:секунды)
; Syntax.........:	_GetTimeStamp()
; Return values..:	Строка в формате: "день.месяц.год часы:минуты:секунды"
; ===============================================================================================================
Func _GetTimeStamp()
 Return @MDAY & "." & @MON & "." & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC
EndFunc ;==>_GetTimeStamp
#EndRegion Log Functions

#Region MySQL Functions
;-------------------------------------------- ФУНКЦИИ РАБОТЫ С БАЗОЙ ДАННЫХ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_Start
; Description....:	Инициализация работы с базой данных и создание файла журнала
; Syntax.........:	_MySQL_Start([$sLogFileName])
; Parameters.....:	$sLogFileName	- имя файла журнала операций с базой данных
; Date...........:	26.06.2018
; ===============================================================================================================
Func _MySQL_Start($sLogFileName = 'MySQL.log')
 If $sLogFileName <> '' Then $sSQL_LogFileName = $sServerAppDir & "\Logs\" & $sLogFileName
 $SQL = ObjCreate("ADODB.Connection")
 $SQL.open("DRIVER=" & $sSQL_Driver & ";SERVER=" & $sSQL_Host & ";DATABASE=" & $sSQL_Database & ";" & _
  "UID=" & $sSQL_Username & ";PWD=" & $sSQL_Password & ";PORT=3306")
 Local $iSQLError = @error
 Switch $iSQLError
  Case 0
   _MySQL_Log('Успешное подключение к базе данных :' & $sSQL_Database, $_DEBUG_MODE_ALL)
   _MySQL_Query("SET NAMES 'cp1251'")
   If $iSQL_DebugMode == $_DEBUG_MODE_ALL Then _
   _LogWrite(_GetTimeStamp() & ": Успешное подключение к базе данных '" & $sSQL_Database & "'")
   Return
  Case 1
   _MySQL_Log('Ошибка установки соеденения с базой данных')
   _LogWrite('Ошибка: Не установлено соеденение с базой данных')
  Case 2
   _MySQL_Log('Драйвер MySQL ODBC не установлен')
   _LogWrite('Ошибка: Не установлен драйвер MySQL ODBC')
  Case Else
   _MySQL_Log('Ошибка базы данных #' & $iSQLError)
   _LogWrite('Ошибка: Ошибка базы данных #' & $iSQLError)
 EndSwitch
 _AppExit()
EndFunc ;==>_MySQL_Start

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_CheckTable
; Description....:	Проверка существования таблицы в базе данных
; Syntax.........:	_MySQL_CheckTable($sTableName)
; Parameters.....:	$sTableName	- наименование таблицы
; Return Value(s):  On Success	- результат проверки:
;						True	- если указанная таблица существует
;						False	- если указанная таблица не существует
; Date...........:	22.12.2016
; ===============================================================================================================
Func _MySQL_CheckTable($sTableName)
 If Not IsObj($SQL) Then Return
 Local $sQuery = $SQL.execute("SHOW TABLES;")
 While Not $sQuery.eof
  If $sQuery.fields(0).value == $sTableName Then Return True
  $sQuery.movenext
 WEnd
 Return False
EndFunc ;==>_MySQL_CheckTable

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_DropTable
; Description....:	Удаление таблицы из базы данных
; Syntax.........:	_MySQL_DropTable($sTableName)
; Parameters.....:	$sTableName	- наименование таблицы
; Date...........:	22.12.2016
; ===============================================================================================================
Func _MySQL_DropTable($sTableName)
 If Not IsObj($SQL) Then Return
 If _MySQL_CheckTable($sTableName) Then _MySQL_Query("DROP TABLE `" & $sTableName & "`;")
EndFunc ;==>_MySQL_DropTable

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_GetCount
; Description....:	Подсчет количества элементов в таблице
; Syntax.........:	_MySQL_GetCount($sTableName{, $sFieldName}{, $sWhereStr})
; Parameter(s)...:	$sTableName	- имя таблицы в базе данных
;					$sFieldName	- имя поля в таблице, по которому будет происходить подсчет
;					$sWhereStr	- поисковый запрос (включая 'WHERE', но без ';' в конце)
; Return values..:	On Success	- Количество элементов в таблице
;                   On Failure	- 0
; Modified.......:	09.02.2018
; ===============================================================================================================
Func _MySQL_GetCount($sTableName, $sFieldName = "*", $sWhereStr = "")
 Local $iCount = 0
 If $sWhereStr <> "" Then $sWhereStr = " " & $sWhereStr
 Local $Query = _MySQL_Query("SELECT COUNT(" & $sFieldName & ") " & _
  "FROM `" & $sTableName & "`" & $sWhereStr & ";")
 If IsObj($Query) Then $iCount = $Query.Fields(0).value
 Return $iCount
EndFunc ;==>_MySQL_GetCount

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_ReadConfig
; Description....:	Чтение строки из таблицы настроек системы "Умный дом"
; Syntax.........:	_MySQL_ReadConfig($sParameter)
; Parameter(s)...:	$sParameter	- имя параметра (записи) в таблице настроек
; Return values..:	On Success	- Количество элементов в таблице
;                   On Failure	- Пустую строку
; Modified.......:	13.02.2018
; ===============================================================================================================
Func _MySQL_ReadConfig($sParameter)
 Local $Query = _MySQL_Query("SELECT data FROM `" & $sDB_TableConfig & "` WHERE name = '" & $sParameter& "';")
 If IsObj($Query) Then Return $Query.Fields(0).value
 Return ""
EndFunc ;==>_MySQL_ReadConfig

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_Query
; Description....:	Выполнение запроса к базе данных
; Syntax.........:	_MySQL_Query($sQuery)
; Parameters.....:	$sQuery	    - строка, содержащая запрос на языке SQL
; Return Value(s):  On Success	- результат выполнения запроса
;                   On Failure	- пустую строку и утснанавливает @error = 1
; Date...........:	26.06.2018
; ===============================================================================================================
Func _MySQL_Query($sQuery)
 If Not IsObj($SQL) Then Return SetError(1)
 _MySQL_Log($sQuery, $_DEBUG_MODE_ALL)
 $Result = $SQL.execute($sQuery)
 If @error Then
  _MySQL_Log("Невозможно выполнить запрос")
  Return SetError(1, 0, "")
 EndIf
 Return $Result
EndFunc ;==>_MySQL_Query

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_StringCode
; Description....:	Преобразование текстовой строки в формат MySQL
; Syntax.........:	_MySQL_StringCode($sText)
; Parameters.....:	$sText	    - исходная строка
; Return Value(s):  Строка, удовлетворяющая синтаксису MySQL
; Date...........:	12.02.2018
; ===============================================================================================================
Func _MySQL_StringCode($sText)
 While StringInStr($sText, "\") > 0
  $sText = StringReplace($sText, "\", "{?SLASH?}")
 WEnd
 $sText = StringReplace($sText, "{?SLASH?}",	"\\")
 $sText = StringReplace($sText, '"',	 		'\"')
 $sText = StringReplace($sText, "'", 	 		"\'")
 $sText = StringReplace($sText, Chr(0),  		"\0")
 $sText = StringReplace($sText, Chr(9),  		"\t")
 $sText = StringReplace($sText, Chr(13), 		"\r")
 $sText = StringReplace($sText, Chr(10), 		"\n")
 $sText = StringReplace($sText, Chr(26), 		"\z")
 $sText = StringReplace($sText, "%",	 		"\%")
 $sText = StringReplace($sText, "&amp;", 		"&")
 Return $sText
EndFunc ;==>_MySQL_StringCode

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_Log
; Description....:	Добавление записи в журнал работы с базой данных
; Syntax.........:	_MySQL_Log($sMessage{, $ErrorLevel})
; Parameter(s)...:	$sMessage	- текст для записи в журнал
;					$ErrorLevel	- уровень протоколирования, разрешающий запись этого события в журнал
; Date...........:	26.06.2018
; ===============================================================================================================
Func _MySQL_Log($sMessage, $ErrorLevel = $_DEBUG_MODE_ERROR)
 If $sSQL_LogFileName == '' Then Return
 If ($iSQL_DebugMode = $_DEBUG_MODE_OFF) Or ($ErrorLevel > $iSQL_DebugMode) Then Return
 Local $hLogFile = FileOpen($sSQL_LogFileName, BitOR($FO_CREATEPATH, $FO_APPEND))
 If @error Then Return
 FileWrite($hLogFile, $sMessage & @CRLF)
 FileClose($hLogFile)
EndFunc ;==>_MySQL_Log

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQLError
; Description....:	Обработка ошибок при работе с базой данных
; Syntax.........:	_MySQLError()
; Remarks .......:	Привязывается один раз командой ObjEvent("AutoIt.Error","_MySQLError")
; ===============================================================================================================
Func _MySQLError()
 _MySQL_Log($oMySQLError.description)
EndFunc ;==>_MySQLError

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_End
; Description....:	Завершение работы с базой данных
; Syntax.........:	_MySQL_End()
; ===============================================================================================================
Func _MySQL_End()
 If $SQL == -1 Then Return
 If Not IsObj($SQL) Then Return SetError(1)
 $SQL.close
EndFunc ;==>_MySQL_End
#EndRegion MySQL Functions

#Region String Functions
;-------------------------------------------------- СТРОКОВЫЕ ФУНКЦИИ -------------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_StringGetKey
; Description....:	Получение значения тэга в строке
; Syntax.........:	_StringGetKey($sStr, $sKey)
; Parameter(s)...:	$sStr		- исходная строка
;					$sKey		- ключ тега для поиска
; Remarks .......:	Например, для строки 'unit="hPa" value="100"' и ключа 'value' вернет '100'
; ===============================================================================================================
Func _StringGetKey($sStr, $sKey)
 $pos = StringInStr($sStr, $sKey & '="')
 If $pos == 0 Then Return ''
 Local $s = StringTrimLeft($sStr, $pos + StringLen($sKey) + 1)
 $pos = StringInStr($s, '"')
 If $pos == 0 Then Return ''
 Return StringLeft($s, $pos - 1)
EndFunc ;==>_StringGetKey

; #FUNCTION# ====================================================================================================
; Name...........:	_StringURLEncode
; Description....:	Кодирование текстовой строки в формате URL
; Syntax.........:	_StringURLEncode($sText)
; Remarks .......:	Результат работы функции - текстовая строка в формате URL
; ===============================================================================================================
Func _StringURLEncode($sText)
 Local $i, $sURL = ""
 For $i = 1 To StringLen($sText)
  $iCode = Asc(StringMid($sText, $i, 1))
  Select
   Case ($iCode >= 40 And $iCode <= 41) Or _
        ($iCode >= 45 And $iCode <= 46) Or _
	    ($iCode >= 48 And $iCode <= 57) Or _
		($iCode >= 65 And $iCode <= 90) Or _
		($iCode >= 97 And $iCode <= 122)
    $sURL &= StringMid($sText, $i, 1)
   Case $iCode == 32
    $sURL &= "+"
   Case Else
    $sURL &= "%" & Hex($iCode, 2)
  EndSelect
 Next
 Return $sURL
EndFunc ;==>_StringURLEncode

; #FUNCTION# ====================================================================================================
; Name...........:	_String_LiteralsDecode
; Description....:	Декодирование текстовой строки, содержащей символьные литералы
; Syntax.........:	_String_LiteralsDecode($sText)
; Remarks .......:	Результат работы функции - декодированная текстовая строка
; ===============================================================================================================
Func _String_LiteralsDecode($sText)
 Local $i, $j, $c, $iCode, $s = $sText
 $s = StringReplace($s, "&nbsp;",	" ")
 $s = StringReplace($s, "&apos;",	"'")
 $s = StringReplace($s, "&quot;",	'"')
 $s = StringReplace($s, "&ndash;",	"-")
 $s = StringReplace($s, "&amp;",	"&")
 $s = StringReplace($s, "&lt;",		"<")
 $s = StringReplace($s, "&gt;",		">")
 $s = StringReplace($s, "&amp;",	"&")
 $s = StringReplace($s, "&laquo;",	"«")
 $s = StringReplace($s, "&raquo;",	"»")
 $s = StringReplace($s, "&sect;",	"§")
 $s = StringReplace($s, "&deg;",	"°")
 $s = StringReplace($s, "&para;",	"¶")
 $s = StringReplace($s, "&middot;",	"-")
 While True
  $iCode = -1
  $i = StringInStr($s, '&#')
  If $i > 0 Then
   $j = StringInStr($s, ';')
   If $j >= $i Then
    $iCode = Number(StringMid($s, $i + 2, $j - $i - 2))
   Else
	$j = $i + 1
   EndIf
  Else
   $i = StringInStr($s, '\u')
   If $i == 0 Then ExitLoop
   $j = $i + 5
   $iCode = Dec(StringMid($s, $i + 2, 4))
  EndIf
  Switch $iCode
   Case -1
	$c = ''
   Case 0x0026
    $c = '&'
   Case 0x0027
    $c = "'"
   Case 0x00A0
    $c = ' '
   Case 0x00AB
    $c = '«'
   Case 0x00B0
    $c = '°'
   Case 0x00B2
    $c = '2'
   Case 0x00B3
    $c = '3'
   Case 0x00B7
    $c = '-'
   Case 0x00BB
    $c = '»'
   Case 0x00C6
    $c = 'AE'
   Case 0x00E0, 0x00E2, 0x00E4
    $c = 'a'
   Case 0x00E8, 0x00E9, 0x00EA
    $c = 'e'
   Case 0x00F3, 0x00F4, 0x00F6
    $c = 'o'
   Case 0x0401
    $c = 'Ё'
   Case 0x0410 To 0x042F
    $c = Chr(Asc('А') + $iCode - 0x0410)
   Case 0x0430 To 0x044F
    $c = Chr(Asc('а') + $iCode - 0x0430)
   Case 0x0451
    $c = 'ё'
   Case 0x00DE
    $c = 'P'
   Case 0x2116
    $c = '№'
   Case Else
    $c = "(#0x" & Hex($iCode, 4) & ")"
  EndSwitch
  $s = StringLeft($s, $i - 1) & $c & StringTrimLeft($s, $j)
 WEnd
 Return $s
EndFunc ;==>_String_LiteralsDecode

; #FUNCTION# ====================================================================================================
; Name...........:	_String_ANSIToOEM
; Description....:	Преобразование строки из кодировки ANSI в OEM
; Syntax.........:	_String_ANSIToOEM($sString)
; Parameter(s)...:	$sString	- исходная строка
; Return values .: 	Success:	преобразованная строка
;					Failure:	пустая строка, переменная @error устанавливается в следующие значения:
;						1 - ошибка DLL
;						2 - невозможно перекодировать строку
; ===============================================================================================================
Func _String_ANSIToOEM($sString)
 Local $sBuffer = DllStructCreate('char[' & StringLen($sString) + 1 & ']')
 Local $aRet = DllCall('User32.dll', 'int', 'CharToOem', 'str', $sString, 'ptr', DllStructGetPtr($sBuffer))
 If Not IsArray($aRet) Then Return SetError(1, 0, '')  ; DLL error
 If $aRet[0] = 0 Then Return SetError(2, $aRet[0], '') ; Function error
 Return DllStructGetData($sBuffer, 1)
EndFunc ;==>_String_ANSIToOEM

; #FUNCTION# ====================================================================================================
; Name...........:	_StringToUTF8
; Description....:	Преобразование строки в кодировку UTF8
; Syntax.........:	_StringToUTF8($sString)
; Parameter(s)...:	$sString	- исходная строка в формате ANSI
; Return values .: 	Success:	преобразованная строка
; ===============================================================================================================
Func _StringToUTF8($sString)
 Local $sResult = '', $iCode
 Local $aSplit = StringSplit($sString, '')
 For $i = 1 To $aSplit[0]
  $iCode = Asc($aSplit[$i])
  Switch $iCode
   Case 192 To 239
    $aSplit[$i] = Chr(208) & Chr($iCode - 48)
   Case 240 To 255
    $aSplit[$i] = Chr(209) & Chr($iCode - 112)
   Case 168
    $aSplit[$i] = Chr(208) & Chr(129)
   Case 184
    $aSplit[$i] = Chr(209) & Chr(145)
   Case Else
    $aSplit[$i] = Chr($iCode)
  EndSwitch
  $sResult &= $aSplit[$i]
 Next
 Return $sResult
EndFunc ;==>_StringToUTF8

; #FUNCTION# ====================================================================================================
; Name...........:	_StringToUTF8_X
; Description....:	Заменяет в строке символы, кодируемые 2мя байтами и более на последовательности /x{код}
; Syntax.........:	_StringToUTF8_X($sString)
; Parameter(s)...:	$sString	- исходная строка в формате ANSI
; Return values .: 	Success:	преобразованная строка
; Remarks .......:	Кроме символов кирилицы
; ===============================================================================================================
Func _StringToUTF8_X($sString)
 Local $i, $sTxt = '', $iSkip = 0, $bin = StringToBinary($sString, 4)
 For $i = 3 To StringLen($bin) step 2
  Local $hex = StringMid($bin, $i,  2)
  Local $dec = Dec($hex)
  If $iSkip > 0 Then
   $sTxt &= '\x' & $hex
   $iSkip -= 1
   ContinueLoop
  EndIf
  If BitAND($dec, 0x80) == 0x00 Then
   $sTxt &= Chr($dec)
  ElseIf BitAND($dec, 0xE0) == 0xC0 Then
   $sTxt &= '\x' & $hex
   $iSkip = 1
  ElseIf BitAND($dec, 0xF0) == 0xE0 Then
   $sTxt &= '\x' & $hex
   $iSkip = 2
  ElseIf BitAND($dec, 0xF8) == 0xF0 Then
   $sTxt &= '\x' & $hex
   $iSkip = 3
  EndIf
 Next
 $sTxt = StringReplace($sTxt, '\xD0\x90', 'А')
 $sTxt = StringReplace($sTxt, '\xD0\x91', 'Б')
 $sTxt = StringReplace($sTxt, '\xD0\x92', 'В')
 $sTxt = StringReplace($sTxt, '\xD0\x93', 'Г')
 $sTxt = StringReplace($sTxt, '\xD0\x94', 'Д')
 $sTxt = StringReplace($sTxt, '\xD0\x95', 'Е')
 $sTxt = StringReplace($sTxt, '\xD0\x01', 'Ё')
 $sTxt = StringReplace($sTxt, '\xD0\x96', 'Ж')
 $sTxt = StringReplace($sTxt, '\xD0\x97', 'З')
 $sTxt = StringReplace($sTxt, '\xD0\x98', 'И')
 $sTxt = StringReplace($sTxt, '\xD0\x99', 'Й')
 $sTxt = StringReplace($sTxt, '\xD0\x9A', 'К')
 $sTxt = StringReplace($sTxt, '\xD0\x9B', 'Л')
 $sTxt = StringReplace($sTxt, '\xD0\x9C', 'М')
 $sTxt = StringReplace($sTxt, '\xD0\x9D', 'Н')
 $sTxt = StringReplace($sTxt, '\xD0\x9E', 'О')
 $sTxt = StringReplace($sTxt, '\xD0\x9F', 'П')
 $sTxt = StringReplace($sTxt, '\xD0\xA0', 'Р')
 $sTxt = StringReplace($sTxt, '\xD0\xA1', 'С')
 $sTxt = StringReplace($sTxt, '\xD0\xA2', 'Т')
 $sTxt = StringReplace($sTxt, '\xD0\xA3', 'У')
 $sTxt = StringReplace($sTxt, '\xD0\xA4', 'Ф')
 $sTxt = StringReplace($sTxt, '\xD0\xA5', 'Х')
 $sTxt = StringReplace($sTxt, '\xD0\xA6', 'Ц')
 $sTxt = StringReplace($sTxt, '\xD0\xA7', 'Ч')
 $sTxt = StringReplace($sTxt, '\xD0\xA8', 'Ш')
 $sTxt = StringReplace($sTxt, '\xD0\xA9', 'Щ')
 $sTxt = StringReplace($sTxt, '\xD0\xAA', 'Ъ')
 $sTxt = StringReplace($sTxt, '\xD0\xAB', 'Ы')
 $sTxt = StringReplace($sTxt, '\xD0\xAC', 'Ь')
 $sTxt = StringReplace($sTxt, '\xD0\xAD', 'Э')
 $sTxt = StringReplace($sTxt, '\xD0\xAE', 'Ю')
 $sTxt = StringReplace($sTxt, '\xD0\xAF', 'Я')
 $sTxt = StringReplace($sTxt, '\xD0\xB0', 'а')
 $sTxt = StringReplace($sTxt, '\xD0\xB1', 'б')
 $sTxt = StringReplace($sTxt, '\xD0\xB2', 'в')
 $sTxt = StringReplace($sTxt, '\xD0\xB3', 'г')
 $sTxt = StringReplace($sTxt, '\xD0\xB4', 'д')
 $sTxt = StringReplace($sTxt, '\xD0\xB5', 'е')
 $sTxt = StringReplace($sTxt, '\xD1\x91', 'ё')
 $sTxt = StringReplace($sTxt, '\xD0\xB6', 'ж')
 $sTxt = StringReplace($sTxt, '\xD0\xB7', 'з')
 $sTxt = StringReplace($sTxt, '\xD0\xB8', 'и')
 $sTxt = StringReplace($sTxt, '\xD0\xB9', 'й')
 $sTxt = StringReplace($sTxt, '\xD0\xBA', 'к')
 $sTxt = StringReplace($sTxt, '\xD0\xBB', 'л')
 $sTxt = StringReplace($sTxt, '\xD0\xBC', 'м')
 $sTxt = StringReplace($sTxt, '\xD0\xBD', 'н')
 $sTxt = StringReplace($sTxt, '\xD0\xBE', 'о')
 $sTxt = StringReplace($sTxt, '\xD0\xBF', 'п')
 $sTxt = StringReplace($sTxt, '\xD1\x80', 'р')
 $sTxt = StringReplace($sTxt, '\xD1\x81', 'с')
 $sTxt = StringReplace($sTxt, '\xD1\x82', 'т')
 $sTxt = StringReplace($sTxt, '\xD1\x83', 'у')
 $sTxt = StringReplace($sTxt, '\xD1\x84', 'ф')
 $sTxt = StringReplace($sTxt, '\xD1\x85', 'х')
 $sTxt = StringReplace($sTxt, '\xD1\x86', 'ц')
 $sTxt = StringReplace($sTxt, '\xD1\x87', 'ч')
 $sTxt = StringReplace($sTxt, '\xD1\x88', 'ш')
 $sTxt = StringReplace($sTxt, '\xD1\x89', 'щ')
 $sTxt = StringReplace($sTxt, '\xD1\x8A', 'ъ')
 $sTxt = StringReplace($sTxt, '\xD1\x8B', 'ы')
 $sTxt = StringReplace($sTxt, '\xD1\x8C', 'ь')
 $sTxt = StringReplace($sTxt, '\xD1\x8D', 'э')
 $sTxt = StringReplace($sTxt, '\xD1\x8E', 'ю')
 $sTxt = StringReplace($sTxt, '\xD1\x8F', 'я')
 Return $sTxt
EndFunc ;==>_StringToUTF8_X

; #FUNCTION# ======================================================================================================
; Name...........:	_TimeToString($iNum1, $iNum2)
; Description....:	Отображение временного интервала в виде текстовой строки
; Syntax.........:	_TimeToString($Timer)
; Parameter(s)...:	$Timer		- временной интервал (в миллисекундах)
; Return value(s):	Строка в формате: 'XX час. XX мин. XX.XXX сек.'
; Modified.......:  12.02.2018
; =================================================================================================================
Func _TimeToString($Timer)
 If $Timer > 3600000 Then Return Floor($Timer / 3600000) & " час. " & _TimeToString(Mod($Timer, 3600000))
 If $Timer > 60000 Then Return Floor($Timer / 60000) & " мин. " & _TimeToString(Mod($Timer, 60000))
 Return Round($Timer /  1000, 3) & " сек."
EndFunc ;==>_TimeToString
#EndRegion String Functions

#Region Numeric Functions
;----------------------------------------------- ФУНКЦИИ ОБРАБОТКИ ЧИСЕЛ ----------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Max($iNum1, $iNum2)
; Description....:	Выбор наибольшего значения из двух чисел
; Syntax.........:	_Max($iNum1, $iNum2)
; Parameter(s)...:	$iNum1		- перевое число
;					$iNum2		- пторое число
; Return value(s):	наибольшее значение двух чисел
; Modified.......:  05.10.2017
; ===============================================================================================================
Func _Max($iNum1, $iNum2)
 Return ($iNum1 > $iNum2) ? $iNum1 : $iNum2
EndFunc ;==>_Max

; #FUNCTION# ====================================================================================================
; Name...........:	_Min($iNum1, $iNum2)
; Description....:	Выбор наименьшего значения из двух чисел
; Syntax.........:	_Min($iNum1, $iNum2)
; Parameter(s)...:	$iNum1		- перевое число
;					$iNum2		- пторое число
; Return value(s):	наименьшее значение двух чисел
; Modified.......:  05.10.2017
; ===============================================================================================================
Func _Min($iNum1, $iNum2)
 Return ($iNum1 < $iNum2) ? $iNum1 : $iNum2
EndFunc ;==>_Min
#EndRegion Numeric Functions
