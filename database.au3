#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	SmartHome - Database Service Tool
	Filename.......:	database.au3
	Description....:	Система "Умный дом". Утилита обслуживания базы данных
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Параметры командной строки, обрабатываемые программой:
						/? - краткая справка о параметрах командной строки
						clean - очистка устаревших записей в базе данных
						/debug - режим отлажки (подробный отчет о выполнении)

    Versions.......:    0.0.0.1 (xx.xx.xxxx) - первая версия
						0.0.2.0 (07.02.2019) - добавлена обработка параметров командной строки
						0.2.0.0 (26.04.2019) - программа адаптированна под версию сервера 2.0.0

$sDB_TableConfig		= "config"				- очищать не нужно
$sDB_TableUser			= "user"				- очищать не нужно
$sDB_TableEvents		= "events"				- очищать записи, хранящиеся свыше определенного срока
$sDB_TableShedule		= "shedule"				- очищать не нужно
$sDB_TableScripts		= "scripts"				- очищать не нужно
$sDB_TableStates		= "variables"			- очищать не нужно
$sDB_TableLog			= "system_log"			- очищать записи, хранящиеся свыше определенного срока
$sDB_TableDevices		= "devices"				- очищать не нужно
$sDB_TableSensors		= "sensors"				- очищать не нужно
$sDB_TableSensorsData	= "sensors_data"		- очищать записи, хранящиеся свыше определенного срока
$sDB_TableUserWidgets	= "user_widgets"		- очищать данные удаленных пользователей
$sDB_TableMediaFavorite	= "media_favorite"		- очищать данные удаленных пользователей и удаленных ресурсов
$sDB_TableMediaBrowsed	= "media_browsed"		- очищать данные удаленных пользователей и удаленных ресурсов
$sDB_TableMusicFiles	= "music_files"			- обрабатывается утилитой Music.exe
$sDB_TableMusicAlbums	= "music_albums"		- полностью обновляется  утилитой Music.exe
$sDB_TableMusicArtists	= "music_artists"		- полностью обновляется  утилитой Music.exe
$sDB_TableMoviesFiles	= "movies_files"		- обрабатывается утилитой Movies.exe
$sDB_TableMoviesInfo	= "movies_info"			- обрабатывается утилитой Movies.exe
$sDB_TableMoviesMeta	= "movies_metadata"		- обрабатывается утилитой Movies.exe
$sDB_TableSeriesFiles	= "series_files"		- обрабатывается утилитой Series.exe
$sDB_TableSeriesSeasons	= "series_seasons"		- обрабатывается утилитой Series.exe
$sDB_TableSeries		= "series_names"		- обрабатывается утилитой Series.exe
$sDB_TablePhotoFiles	= "photo_files"			- обрабатывается утилитой Photo.exe
$sDB_TablePhotoAlbums	= "photo_albums"		- обрабатывается утилитой Photo.exe
$sDB_TableTVChannels	= "tv_channel"			- очищать не нужно
$sDB_TableTVChannelMap	= "tv_channel_map"		- очищать данные удаленных устройств
$sDB_TableTVProgram		= "tv_program"			- полностью обновляется утилитой TV_Program.exe
$sDB_TableSysInfo		= "server_sysinfo"		- полностью обновляется утилитой SysInfo.exe
$sDB_TableSysSMART		= "server_smart_hdd"	- очищать записи, хранящиеся свыше определенного срока
$sDB_TableWeather		= "weather_forecast"	- полностью обновляется утилитой Weather.exe
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\database.exe)
#pragma compile(Icon, ..\resources\icons\database.ico)
#pragma compile(ProductName, Smart Home Server - Clean Database)
#pragma compile(FileVersion, 0.2.0.1)
#pragma compile(LegalCopyright, (c)2016-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; Настройка параметров приложения
		$sAppShortName			= 'database'							; краткое название программы
; Прочие переменные, используемые в приложении
Global  $iStorageTime			= 7										; время хранения записей в таблицах
Global	$iRecordsCount			= 0										; счетчик удаленных записей
Global	$iErrorCount			= 0										; счетчик ошибок
#EndRegion Initialization

#Region Main Script
_AppStart()																; подготовка программы к работе
_Main()																	; основное выполение программы
_AppExit()																; завершение работы программы
#EndRegion Main Script

#Region Main
;------------------------------------------------ ОСНОВНОЕ ВЫПОЛНЕНИЕ ПРОГРАММЫ----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Main
; Description....:	Проверка и обработка параметров командной строки.
; Syntax.........:	_Main()
; ===============================================================================================================
Func _Main()
 If $CmdLine[0] > 0 Then
  Local $sParameter = $CmdLine[0] > 1 ? $CmdLine[2] : ''
  Switch ($CmdLine[0] > 0 ? $CmdLine[1] : "")
   Case "/?"
    Return _LogWrite("Система 'Умный дом'. Утилита обслуживания базы данных." & @CRLF & _
		    "Параметры командной строки:" & @CRLF & _
            "database.exe [clean] {/debug}" & @CRLF & _
		    " clean - очистка устаревших записей в базе данных" & @CRLF & _
		    " /debug - режим отлажки (подробный отчет о выполнении)")
   Case "clean"
    _CleanDatabase()
    Return
  EndSwitch
 EndIf
 _LogWrite(" Ошибка в синтаксисе команды." & @CRLF & " Используйте 'database.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region MySQL Functions
;-------------------------------------------- ФУНКЦИИ РАБОТЫ С БАЗОЙ ДАННЫХ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CleanDatabase
; Description....:	Очистка устаревших записей в базе данных
; Syntax.........:	_CleanDatabase()
; ===============================================================================================================
Func _CleanDatabase()
 Local $iCountStart, $iCountEnd
 $iCountStart = _MySQL_GetCount($sDB_TableEvents)
 If $iCountStart > 0 Then ; очистка сраых записей в таблице 'events'
  _MySQL_Query("DELETE FROM `" & $sDB_TableEvents & "` " & _
   "WHERE updated < TIMESTAMP(DATE_SUB(NOW(), INTERVAL " & $iStorageTime & " DAY));")
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableEvents)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" Из таблицы '" & $sDB_TableEvents & "' удалено " & $iCountStart - $iCountEnd & " записей")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableLog)
 If $iCountStart > 0 Then ; очистка сраых записей в таблице 'server_log'
  _MySQL_Query("DELETE FROM `" & $sDB_TableLog & "` " & _
   "WHERE time < TIMESTAMP(DATE_SUB(NOW(), INTERVAL " & $iStorageTime & " DAY));")
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableLog)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" Из таблицы '" & $sDB_TableLog & "' удалено " & $iCountStart - $iCountEnd & " записей")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableSensorsData)
 If $iCountStart > 0 Then ; очистка сраых записей в таблице 'sensors_data'
  _MySQL_Query("DELETE FROM `" & $sDB_TableSensorsData & "` " & _
   "WHERE updated < TIMESTAMP(DATE_SUB(NOW(), INTERVAL " & $iStorageTime & " DAY));")
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableSensorsData)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" Из таблицы '" & $sDB_TableSensorsData & "' удалено " & $iCountStart - $iCountEnd & " записей")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableUserWidgets)
 If $iCountStart > 0 Then ; очистка записей удаленных пользователей в таблице 'user_widgets'
  Local $Query = _MySQL_Query("SELECT id, user_id FROM `" & $sDB_TableUserWidgets & "`;")
  If IsObj($Query) Then
   While Not $Query.EOF
    Local $iID		= $Query.Fields(0).value
    Local $iUser	= $Query.Fields(1).value
    $Query.MoveNext
	If _MySQL_GetCount($sDB_TableUser, 'id', "WHERE id = '" & $iUser & "'") == 0 Then _
    _MySQL_Query("DELETE FROM `" & $sDB_TableUserWidgets & "` WHERE id =  " & $iID & ";")
   WEnd
  EndIf
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableUserWidgets)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" Из таблицы '" & $sDB_TableUserWidgets & "' удалено " & $iCountStart - $iCountEnd & " записей")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableMediaFavorite)
 If $iCountStart > 0 Then ; очистка записей удаленных пользователей в таблице 'media_favorite'
  Local $Query = _MySQL_Query("SELECT id, user_id, dlna_id FROM `" & $sDB_TableMediaFavorite & "`;")
  If IsObj($Query) Then
   While Not $Query.EOF
    Local $iID		= $Query.Fields(0).value
    Local $iUser	= $Query.Fields(1).value
	Local $iDLNA	= $Query.Fields(2).value
    $Query.MoveNext
	If _MySQL_GetCount($sDB_TableUser, 'id', "WHERE id = '" & $iUser & "'") == 0 Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableMediaFavorite & "` WHERE id =  " & $iID & ";")
	If (_MySQL_GetCount($sDB_TableMusicFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) And  _
	   (_MySQL_GetCount($sDB_TableMoviesFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) And _
	   (_MySQL_GetCount($sDB_TableSeriesFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableMediaFavorite & "` WHERE id =  " & $iID & ";")
   WEnd
  EndIf
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableMediaFavorite)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" Из таблицы '" & $sDB_TableMediaFavorite & "' удалено " & $iCountStart - $iCountEnd & " записей")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableMediaBrowsed)
 If $iCountStart > 0 Then ; очистка записей удаленных пользователей в таблице 'media_browsed'
  Local $Query = _MySQL_Query("SELECT id, user_id, dlna_id FROM `" & $sDB_TableMediaBrowsed & "`;")
  If IsObj($Query) Then
   While Not $Query.EOF
    Local $iID		= $Query.Fields(0).value
    Local $iUser	= $Query.Fields(1).value
	Local $iDLNA	= $Query.Fields(2).value
    $Query.MoveNext
	If _MySQL_GetCount($sDB_TableUser, 'id', "WHERE id = '" & $iUser & "'") == 0 Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableMediaBrowsed & "` WHERE id =  " & $iID & ";")
	If (_MySQL_GetCount($sDB_TableMusicFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) And  _
	   (_MySQL_GetCount($sDB_TableMoviesFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) And _
	   (_MySQL_GetCount($sDB_TableSeriesFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableMediaBrowsed & "` WHERE id =  " & $iID & ";")
   WEnd
  EndIf
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableMediaBrowsed)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" Из таблицы '" & $sDB_TableMediaBrowsed & "' удалено " & $iCountStart - $iCountEnd & " записей")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableTVChannelMap)
 If $iCountStart > 0 Then ; очистка записей удаленных пользователей в таблице 'tv_channel_map'
  Local $Query = _MySQL_Query("SELECT id, device FROM `" & $sDB_TableTVChannelMap & "`;")
  If IsObj($Query) Then
   While Not $Query.EOF
    Local $iID		= $Query.Fields(0).value
    Local $sDevice	= $Query.Fields(1).value
    $Query.MoveNext
	If _MySQL_GetCount($sDB_TableDevices, 'id', "WHERE name = '" & $sDevice & "'") == 0 Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableTVChannelMap & "` WHERE id =  " & $iID & ";")
   WEnd
  EndIf
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableTVChannelMap)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" Из таблицы '" & $sDB_TableTVChannelMap & "' удалено " & $iCountStart - $iCountEnd & " записей")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableSysSMART)
 If $iCountStart > 0 Then ; очистка сраых записей в таблице 'server_smart_hdd'
  _MySQL_Query("DELETE FROM `" & $sDB_TableSysSMART & "` " & _
   "WHERE time < TIMESTAMP(DATE_SUB(NOW(), INTERVAL " & $iStorageTime & " DAY));")
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableSysSMART)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" Из таблицы '" & $sDB_TableSysSMART & "' удалено " & $iCountStart - $iCountEnd & " записей")
 EndIf
 If $iErrorCount == 0 Then
  _LogWrite(" Во время выполнения программы ошибок не возникло")
 Else
  _LogWrite(" Всего ошибок во время выполнения программы: " & $iErrorCount)
 EndIf
 Local $sText = "Всего удалено записей: " & $iRecordsCount
 If $iErrorCount > 0  Then $sText &= ". Ошибок: " & $iErrorCount
 _SysyemLogWrite($iRecordsCount, $iErrorCount, $sText)
 _LogWrite()
EndFunc ;==>_CleanDatabase
#EndRegion MySQL Functions
