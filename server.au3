#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.2
	Date...........:	02.05.2019
	Title..........:	SmartHome - Server
	Filename.......:	Server.au3
	Description....:	Система "Умный дом". Скрипт управления сервером
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Параметры командной строки, обрабатываемые программой:
						/? - краткая справка о параметрах командной строки
						off - выключение сервера
						reboot - перезагрузка сервера
						mute - отключение звука
						unmute - включение звука
						play {filename} - проигрывание wav-файла
						sysinfo - обновление информации об аппаратных ресурсах сервера
						/debug - режим отлажки (подробный отчет о выполнении)

    Versions.......:    0.0.0.1 (21.09.2017) - первая версия программы
	                    0.0.0.4 (20.10.2017) - добавлена команда "alloff"
	                    0.0.1.0 (17.06.2018) - добавлено управление звуком
	                    0.0.2.0 (07.02.2019) - добавлено обновление информации об аппаратных ресурсах
						0.2.0.0 (26.04.2019) - программа адаптированна под версию сервера 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\server.exe)
#pragma compile(Icon, ..\resources\icons\server.ico)
#pragma compile(ProductName, Smart Home Server - Server Driver)
#pragma compile(FileVersion, 0.2.0.2)
#pragma compile(LegalCopyright, (c)2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <UDFs\_AudioEndpointVolume.au3>
#include <UDFs\_SMART.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; Настройка параметров приложения
		$sAppShortName			= 'Server Control'						; краткое название программы

; Прочие переменные, используемые в приложении
Global	$sSoundFilesSubDir		= '\resources\sound\'					; подкаталог размещения звуковых файлов
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
    Return _LogWrite("Система 'Умный дом'. Скрипт управления сервером." & @CRLF & _
		    "Параметры командной строки:" & @CRLF & _
            "server.exe [off|reboot|mute|unmute|play|sysinfo] {filename} {/debug}" & @CRLF & _
		    " off - выключение сервера" & @CRLF & _
		    " reboot - перезагрузка сервера" & @CRLF & _
		    " mute - отключение звука" & @CRLF & _
		    " unmute - включение звука" & @CRLF & _
		    " play {filename} - проигрывание wav-файла" & @CRLF & _
		    " sysinfo - обновление информации об аппаратных ресурсах сервера" & @CRLF & _
		    " /debug - режим отлажки (подробный отчет о выполнении)")
   Case "off"
    _PowerOff()
    Return
   Case "reboot"
    _Reboot()
    Return
   Case "mute"
    _Mute()
    Return
   Case "unmute"
    _Unmute()
    Return
   Case "play"
    _Play($sParameter)
    Return
   Case "sysinfo"
    _SysInfo()
    Return
  EndSwitch
 EndIf
 _LogWrite(" Ошибка в синтаксисе команды." & @CRLF & " Используйте 'server.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region Server Control Functions
;------------------------------------------------ ФУНКЦИИ УПРАВЛЕНИЯ СЕРВЕРОМ -----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Reboot
; Description....:	Перезагрузка сервера
; Syntax.........:	_Reboot()
; ===============================================================================================================
Func _Reboot()
 Shutdown(BitOR($SD_REBOOT, $SD_FORCE, $SD_FORCEHUNG))
EndFunc ;==>_Reboot

; #FUNCTION# ====================================================================================================
; Name...........:	_PowerOff
; Description....:	Выключение сервера
; Syntax.........:	_PowerOff()
; ===============================================================================================================
Func _PowerOff()
 Shutdown(BitOR($SD_SHUTDOWN, $SD_FORCE, $SD_FORCEHUNG))
EndFunc ;==>_PowerOff
#EndRegion Server Control Functions

#Region Sound Control Functions
;-------------------------------------------- ФУНКЦИИ УПРАВЛЕНИЯ ЗВУКОМ НА СЕРВЕРЕ ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Mute
; Description....:	Выключение звука
; Syntax.........:	_Mute()
; ===============================================================================================================
Func _Mute()
 _SetMute(1)
 If _GetMute() == 1 Then
  _LogWrite(" Звук отключен")
  _MySQL_Query("UPDATE `" & $sDB_TableDevices & "` SET state = 1, updated = NOW() WHERE name = 'Server';")
 Else
  _LogWrite(" Ошибка: Невозможно отключить звук на сервере")
  _SysyemLogWrite(0, 1, "Невозможно отключить звук на сервере")
 EndIf
EndFunc ;==>_Mute

; #FUNCTION# ====================================================================================================
; Name...........:	_Unmute
; Description....:	Включение звука
; Syntax.........:	_Unmute()
; ===============================================================================================================
Func _Unmute()
 _SetMute(0)
 Sleep(500)
 If _GetMute() == 0 Then
  _LogWrite(" Звук включен")
  _MySQL_Query("UPDATE `" & $sDB_TableDevices & "` SET state = 3, updated = NOW() WHERE name = 'Server';")
 Else
  _LogWrite(" Ошибка: Невозможно включить звук на сервере")
  _SysyemLogWrite(0, 1, "Невозможно включить звук на сервере")
 EndIf
EndFunc ;==>_Unmute

; #FUNCTION# ====================================================================================================
; Name...........:	_Play
; Description....:	Проигрывание файла
; Syntax.........:	_Play()
; ===============================================================================================================
Func _Play($sFileName)
 Local $sFullFileName = $sServerAppDir & $sSoundFilesSubDir & $sFileName
 If Not FileExists($sFullFileName) Then
  _LogWrite(" Ошибка: не найден файл '" & $sFullFileName & "'")
  _SysyemLogWrite(0, 1, "Не найден файл alarm.wav")
  _AppExit()
 EndIf
 _LogWrite(" Проигрывание файла: '" & $sFullFileName & "'")
 SoundPlay($sFullFileName, 1)
EndFunc ;==>_Play
#EndRegion Sound Control Functions

#Region System Information Functions
;---------------------------------------- ФУНКЦИИ ПОЛУЧЕНИЯ ИНФОРМАЦИИ О СИСТЕМЕ --------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_SysInfo
; Description....:	Сбор и запись в базу данных информации об аппаратных ресурсах сервера
; Syntax.........:	_SysInfo()
; ===============================================================================================================
Func _SysInfo()
 _CreateTableSysInfo()
 Local $i, $ObjItem, $ObjSubItem, $ObjWMIService = ObjGet("winmgmts:\\" & @ComputerName & "\root\CIMV2")
 Local $sSectionName = "Processor"
 Local $ColItems = $objWMIService.ExecQuery("SELECT * FROM Win32_Processor", "WQL", 0x30)
 $i = 1
 If IsObj($ColItems) Then
  For $ObjItem In $ColItems
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Name,						$sSectionName& ".Name")
   _SaveSysInfoData($ObjItem.NumberOfCores,				$sSectionName& ".NumberOfCores")
   _SaveSysInfoData($ObjItem.MaxClockSpeed,				$sSectionName& ".MaxClockSpeed")
   _SaveSysInfoData($ObjItem.AddressWidth,				$sSectionName& ".AddressWidth")
   _SaveSysInfoData($ObjItem.L2CacheSize,				$sSectionName& ".L2CacheSize")
   _SaveSysInfoData($ObjItem.L3CacheSize,	 			$sSectionName& ".L3CacheSize")
   _SaveSysInfoData($ObjItem.LoadPercentage,			$sSectionName& ".LoadPercentage")
   $i += 1
  Next
 EndIf
 $sSectionName = "BaseBoard"
 $ColItems = $objWMIService.ExecQuery("SELECT * FROM Win32_BaseBoard", "WQL", 0x30)
 $i = 1
 If IsObj($ColItems) Then
  For $ObjItem In $ColItems
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Manufacturer,					$sSectionName & ".Manufacturer")
   _SaveSysInfoData($ObjItem.Product,						$sSectionName & ".Product")
   $i += 1
  Next
 EndIf
 $sSectionName = "DiskDrive"
 Local $aDisks = _SMART_LoadDisksList()
 For $i = 0 To UBound($aDisks, 1) - 1
  If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
  _SaveSysInfoData($aDisks[$i][$_DISK_ATTR_MODEL],					$sSectionName & ".Model", $i)
  _SaveSysInfoData($aDisks[$i][$_DISK_ATTR_SERIAL],					$sSectionName & ".SerialNumber", $i)
  _SaveSysInfoData(Round($aDisks[$i][$_DISK_ATTR_SIZE] / 1048576, 2), $sSectionName & ".Size", $i)
  _SaveSysInfoData($aDisks[$i][$_DISK_ATTR_LOGICALS],				$sSectionName & ".LogicalDisks", $i)
 Next
 $sSectionName = "LogicalDisk"
 $ColItems = $objWMIService.ExecQuery("SELECT * FROM Win32_LogicalDisk", "WQL", 0x30)
 $i = 1
 If IsObj($ColItems) Then
  For $ObjItem In $ColItems
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Name,									$sSectionName & ".Name", $i)
   _SaveSysInfoData(Round($ObjItem.Size / 1073741824, 2),			$sSectionName & ".Size", $i)
   _SaveSysInfoData(Round($ObjItem.FreeSpace / 1073741824, 2),		$sSectionName & ".FreeSpace", $i)
   _SaveSysInfoData($ObjItem.FileSystem,							$sSectionName & ".FileSystem", $i)
   $i += 1
  Next
 EndIf
 $sSectionName = "NetworkAdapter"
 Local $Adapters = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter", "WQL", 0x30)
 Local $Config = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration", "WQL", 0x30)
 $i = 1
 If IsObj($Adapters) And IsObj($Config) Then
  For $ObjItem In $Config
   If Not $ObjItem.IPEnabled Then ContinueLoop
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Description, $sSectionName & ".Name", $i)
   _SaveSysInfoData(_ObjArrayToString($ObjItem.IPAddress), $sSectionName & ".IPAddress", $i)
   _SaveSysInfoData($ObjItem.MACAddress, $sSectionName & ".MACAddress", $i)
   For $ObjSubItem In $Adapters
    If $ObjSubItem.Index <> $ObjItem.Index Then ContinueLoop
     _SaveSysInfoData($ObjSubItem.Speed, $sSectionName & ".Speed", $i)
    ExitLoop
   Next
   $i += 1
  Next
 EndIf
 $sSectionName = "OperatingSystem"
 $ColItems = $objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL", 0x30)
 $i = 1
 If IsObj($ColItems) Then
  For $ObjItem In $ColItems
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Caption, $sSectionName & ".Name")
   _SaveSysInfoData($ObjItem.Version, $sSectionName & ".Version")
   _SaveSysInfoData(Round($ObjItem.TotalVisibleMemorySize / 1048576, 2), $sSectionName & ".TotalVisibleMemorySize")
   _SaveSysInfoData(Round($ObjItem.TotalVirtualMemorySize / 1048576, 2), $sSectionName & ".TotalVirtualMemorySize")
   _SaveSysInfoData($ObjItem.InstallDate, $sSectionName & ".InstallDate")
   _SaveSysInfoData($ObjItem.LastBootUpTime, $sSectionName & ".LastBootUpTime")
   $i += 1
  Next
 EndIf
 Local $iCount = _MySQL_GetCount($sDB_TableSysInfo, "name")
 If $iCount > 0 Then
  _LogWrite(" В таблицу '" & $sDB_TableSysInfo & "' добавлено записей: " & $iCount)
 _SysyemLogWrite($iCount, 0, "System Information. Добавлено записей: " & $iCount)
 Else
  _SysyemLogWrite($iCount, 1, "Не получилось обновить информацию о системе")
 EndIf
EndFunc ;==>_SysInfo
#EndRegion System Information Functions

#Region MySQL Functions
;-------------------------------------------- ФУНКЦИИ РАБОТЫ С БАЗОЙ ДАННЫХ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateTableSysInfo
; Description....:	Создание в базе данных пустой таблицы с информацией о параметрах системы
; Syntax.........:	_CreateTableSysInfo()
; ===============================================================================================================
Func _CreateTableSysInfo()
 _MySQL_DropTable($sDB_TableSysInfo)
 _MySQL_Query("CREATE TABLE `" & $sDB_TableSysInfo & "` (" & _
  "name TEXT, " & _					; наименование параметра
  "device TEXT, " & _				; ID устройства в системе
  "value TEXT, " & _				; значение параметра
  "time TIMESTAMP);")				; метка времени занесения информации в таблицу
 If Not @error Then
  _LogWrite(" Создана (либо создана заново) таблица '" & $sDB_TableSysInfo & "'")
 Else
  _LogWrite(" Ошибка: Невозможно создать таблицу '" & $sDB_TableSysInfo & "'")
  _SysyemLogWrite(0, 1, "Ошибка базы данных")
  _AppExit()
 EndIf
EndFunc ;==>_CreateTableSysInfo

; #FUNCTION# ====================================================================================================
; Name...........:	_SaveSysInfoData
; Description....:	Запись строки в таблицу с информацией о параметрах системы
; Syntax.........:	_SaveSysInfoData($Value, $sName[, $id])
; Parameters.....:	$Value	- значение параметра
;					$sName	- наименование параметра
;					$id		- ID устройства в системе
; ===============================================================================================================
Func _SaveSysInfoData($Value, $sName, $id = 1)
 If $DEBUG Then _LogWrite(" > " & $sName & " = " & $Value)
 _MySQL_Query("INSERT INTO `" & $sDB_TableSysInfo & "` " & _
  "(name, device, value) VALUES (" & _
  "'" & _MySQL_StringCode($sName) & "'," & _									; name
  "'" & $id & "'," & _															; device
  "'" & _MySQL_StringCode($Value) &"');")										; value
EndFunc ;==>_SaveSysInfoData

; #FUNCTION# ====================================================================================================
; Name...........:	_ObjArrayToString
; Description....:	Представление объекта-массива в виде строки
; Syntax.........:	_ObjArrayToString($aStrings)
; Parameters.....:	$aStrings	- объект-массив
; Return value(s):	Строка, содержащая все элементы объекта, перечисленные через разделитель
; ===============================================================================================================
Func _ObjArrayToString($aStrings)
 Local $i, $sString = ""
 For $i = 0 To UBound($aStrings) - 1
  $sString &= " | " & $aStrings[$i]
 Next
 Return StringTrimLeft($sString, 3)
EndFunc ;==>_ObjArrayToString
#EndRegion MySQL Functions
