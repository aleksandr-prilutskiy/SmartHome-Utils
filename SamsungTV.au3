#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.1.0
	Date...........:	03.05.2019
	Title..........:	SmartHome - Samsung TV
	Filename.......:	SamsungTV.au3
	Description....:	Система "Умный дом". Драйвер управления телевизорами Samsung
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Параметры командной строки, обрабатываемые программой:
						/? - краткая справка о параметрах командной строки
						off {devicename} - выключение телевизора
						play {devicename } {url} - проиграть на телевизоре медиаконтент (видео или музыку)
						channel_up {devicename} - переключение на следующий канал
						channel_down {devicename} - переключение на предыдущий канал
						channel	{devicename} {N} - переключение на заданный канал
						volume_up {devicename} - увеличение громкости
						volume_down {devicename} - уменьшение громкости
						mute {devicename} - отключение / включение звука
						pause {devicename} - остановка воспроизведения
						return {devicename} - отмена текущего действия (возврат в основное состояние)
						/debug - режим отлажки (подробный отчет о выполнении)

						Для работы скрипта в базе данных, в таблице 'devices' должна быть запись, поле которой
						'name' должно соотвествовать параметру {devicename} в командной строке.
						В этой записе должны быть заполнены поля 'addr' и 'parameters':
						addr - ip-адрес телевизова в локальной сети;
						parameters - DLNA UUID устройства (можно посмотреть в программе медиа-сервера).

    Versions.......:    0.0.1.5 (11.07.2017) - исправлены ошибки при передачи медиаконтента DLNA на телефизоры
					    0.0.1.12(03.10.2017) - добавлено переключение каналов, управление громкостью и др
	                    0.0.2.0 (15.06.2018) - изменена структура базы данных
						0.2.0.0 (26.04.2019) - программа адаптированна под версию сервера 2.0.0
						0.2.1.0 (02.05.2019) - программа переделана под "Домашний медиа-сервер" версии 3.xx
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\SamsungTV.exe)
#pragma compile(Icon, ..\resources\icons\Samsung.ico)
#pragma compile(ProductName, Smart Home Server - Samsung TV E7x Series Driver)
#pragma compile(FileVersion, 0.2.1.0)
#pragma compile(LegalCopyright, (c)2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <InetConstants.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; Настройка параметров приложения
		$sAppShortName			= 'Samsung TV Driver'					; краткое название программы

; Прочие переменные, используемые в приложении
Global  $sServerURL				= ''									; URL запроса Web-интерфейса DLNA-сервера
Global	$sSamTV_AppName 		= "autoit.samsung.remote"				;
Global	$sSamTV_Port			= 55000
Global	$sSamTV_UserIPAddr		= @IPAddress1
Global	$sSamTV_UserMacAddr		= "00-00-00-00-00-00"
Global	$sDeviceName			= ''
Global	$sDeviceUUID			= ''
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
; Modified.......:	04.02.2019
; ===============================================================================================================
Func _Main()
 If $CmdLine[0] > 0 Then
  If $CmdLine[1] == "/?" Then _
   Return _LogWrite("Система 'Умный дом'. Драйвер управления телевизорами Samsung." & @CRLF & _
		   "Параметры командной строки:" & @CRLF & _
           "SamsungTV.exe [off|play|channel_up|channel_down|volume_up|volume_down|mute|" & _
                          "pause|return|channel] {devicename} {URL} {N} {/debug}" & @CRLF & _
		   " off {devicename} - выключение телевизора" & @CRLF & _
		   " play {devicename} {url} - проиграть на телевизоре медиаконтент (видео или музыку)" & @CRLF & _
		   " channel_up {devicename} - переключение на следующий канал" & @CRLF & _
		   " channel_down {devicename} - переключение на предыдущий канал" & @CRLF & _
		   " channel {devicename} {N} - переключение на заданный канал" & @CRLF & _
		   " volume_up {devicename} - увеличение громкости" & @CRLF & _
		   " volume_down {devicename} - уменьшение громкости" & @CRLF & _
		   " mute {devicename} - отключение / включение звука" & @CRLF & _
		   " pause {devicename} - остановка воспроизведения" & @CRLF & _
		   " return {devicename} - отмена текущего действия (возврат в основное состояние)" & @CRLF & _
		   " /debug - режим отлажки (подробный отчет о выполнении)")
  $sDeviceName = ($CmdLine[0] > 1 ? $CmdLine[2] : "")
  If StringLen($sDeviceName) == 0 Then
   _LogWrite("Ошибка: не указано имя устройства")
   _SysyemLogWrite(0, 1, "Не указано имя устройства")
   Return
  EndIf
  Local $Addr = '', $Data = ($CmdLine[0] > 2 ? $CmdLine[3] : "")
  Local $Query = _MySQL_Query("SELECT addr, parameters FROM `" & $sDB_TableDevices & "` " & _
   "WHERE name = '" &$sDeviceName & "';")
  If IsObj($Query) Then
   $Addr		= $Query.Fields(0).value
   $sDeviceUUID = $Query.Fields(1).value
  EndIf
  If StringLen($Addr) == 0 Then
   _LogWrite("Ошибка: невозможно получить адрес устройства '" & $sDeviceName & "'. " & _
             "Проверте таблицу '" & $sDB_TableDevices & "' в базе данных.")
   _SysyemLogWrite(0, 1, "Невозможно получить адрес устройства")
   _AppExit()
  EndIf
  Switch $CmdLine[1]
   Case "off"
    Return _SamsungTV_PowerOff($Addr)
   Case "play"
    Return _SamsungTV_Play($Addr, $Data)
   Case "channel_up"
    Return _SamsungTV_SendCommand($Addr, "KEY_CHUP")
   Case "channel_down"
    Return _SamsungTV_SendCommand($Addr, "KEY_CHDOWN")
   Case "channel"
    Return _SamsungTV_SetChannel($Addr, $Data)
   Case "volume_up"
    Return _SamsungTV_SendCommand($Addr, "KEY_VOLUP")
   Case "volume_down"
    Return _SamsungTV_SendCommand($Addr, "KEY_VOLDOWN")
   Case "mute"
    Return _SamsungTV_SendCommand($Addr, "KEY_MUTE")
   Case "pause"
    Return _SamsungTV_SendCommand($Addr, "KEY_PAUSE")
   Case "return"
    Return _SamsungTV_SendCommand($Addr, "KEY_RETURN")
  EndSwitch
 EndIf
 _LogWrite(" Ошибка в синтаксисе команды." & @CRLF & " Используйте 'SamsungTV.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region Read Config
;-------------------------------------------- ФУНКЦИИ ЗАГРУЗКИ НАСТРОЕК ПРИЛОЖЕНИЯ ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ReadServerConfig
; Description....:	Чтение настроек системы "Умный дом" из базы данных
; Syntax.........:	_ReadServerConfig($Addr)
; Parameter(s)...:	$Addr		- ip-адрес телевизора в сети
; Return values .:	On Success - True
;					On Failure - False, переменная @error принимает следующие значения:
; 						1: ошибка получения параметров сервера из базы данных
;						2: ошибка получения параметров DLNA-параметров устройства
; ===============================================================================================================
Func _ReadServerConfig($Addr)
 Local $sServerAddr = _MySQL_ReadConfig('ServerAddr')
 Local $sPortDLNA   = _MySQL_ReadConfig('PortDLNA')
 If (StringLen($sServerAddr) == 0) OR (StringLen($sPortDLNA) == 0) Then
  _LogWrite("Ошибка получения параметров DLNA сервера" & @CRLF & _
			"Проверьте записи 'ServerAddr' и 'PortDLNA' в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Ошибка параметров DLNA-сервера")
  _AppExit()
 EndIf
 If (StringLen($sDeviceUUID) == 0) Then
  _LogWrite("Ошибка: Ошибка UUID устройства" & @CRLF & _
   " Проверьте настройки устройства '" & $sDeviceName & "'" & @CRLF & _
   " Строка 'Дополнительные параметры' должна содержвть UUID устройства.")
  _SysyemLogWrite(0, 1, "Ошибка: не указан UUID устройства")
  Return False
 EndIf
 $sServerURL = 'http://' & $sServerAddr & (StringLen($sPortDLNA) > 0 ? ':' & $sPortDLNA : '')
 If $DEBUG Then _
  _LogWrite("Были получены следующие настройки системы 'Умный дом':" & @CRLF & _
			" Адрес сервера DLNA = " & $sServerURL & @CRLF & _
			" UUID устройства = " & $sDeviceUUID & @CRLF)
 Return True
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region TV Control Commands
;----------------------------------------------- ФУНКЦИИ УПРАВЛЕНИЯ ТЕЛЕВИЗОРОМ ---------------------------------

; #FUNCTION# ======================================================================================================
; Name...........:	_SamsungTV_SendCommand
; Description....:	Отправка команды на телевизор
; Syntax.........:	_SamsungTV_SendCommand($Addr, $sCommand)
; Parameter(s)...:	$Addr		- ip-адрес телевизора в сети
;					$sCommand	- команда
; Version .......:	0.0.2
; Modified.......:	04.10.2017
; =================================================================================================================
Func _SamsungTV_SendCommand($Addr, $sCommand)
 TCPStartup()
 Local $iSocket = TCPConnect($Addr, $sSamTV_Port)
 If @error Then
  _LogWrite(" Ошибка: Невозможно установить соединение с телевизором: " & $Addr)
  Return SetError(1)
 EndIf
 _LogWrite(" Отправка команды '" & $sCommand & "' на телевизор с адресом: " & $Addr)
 Local $Datagram = Chr(0x00) & _SamsungTV_StringAddHeader($sSamTV_AppName) & _
  _SamsungTV_StringAddHeader(Chr(0x64) & Chr(0x00) & _
  _SamsungTV_StringAddHeader(_Base64Encode($sSamTV_UserIPAddr)) & _
  _SamsungTV_StringAddHeader(_Base64Encode($sSamTV_UserMacAddr)) & _
  _SamsungTV_StringAddHeader(_Base64Encode($sSamTV_AppName))) & _
  Chr(0x00) & _SamsungTV_StringAddHeader($sSamTV_AppName) & _
  _SamsungTV_StringAddHeader(Chr(50) & Chr(48) & Chr (48)) & _
  Chr(0x00) & _SamsungTV_StringAddHeader($sSamTV_AppName) & _
  _SamsungTV_StringAddHeader(Chr(0x00) & Chr(0x00) & Chr(0x00) & _
  _SamsungTV_StringAddHeader(_Base64Encode($sCommand)))
 TCPSend($iSocket, StringToBinary($Datagram))
 TCPShutdown()
EndFunc ;==>_SamsungTV_SendCommand

; #FUNCTION# ====================================================================================================
; Name...........:	_SamsungTV_SetChannel
; Description....:	Сменить канал на заданный
; Syntax.........:	_SamsungTV_SetChannel($Addr, $sChannel)
; Parameter(s)...:	$Addr		- ip-адрес телевизора в сети
;					$sChannel	- номер канала
; Remarks .......:	Номер канала передается в 3-м параметре командной строки
; ===============================================================================================================
Func _SamsungTV_SetChannel($Addr, $sChannel)
 If $sChannel == "" Then Return
 Local $i
 For $i = 1 To StringLen($sChannel)
  _SamsungTV_SendCommand($Addr, "KEY_" & StringMid($sChannel, $i, 1))
  Sleep(250)
 Next
 _SamsungTV_SendCommand($Addr, "KEY_ENTER")
EndFunc ;==>_SamsungTV_SetChannel

; #FUNCTION# ====================================================================================================
; Name...........:	_SamsungTV_PowerOff
; Description....:	Выключение телевизора
; Syntax.........:	_SamsungTV_PowerOff($Addr)
; Parameter(s)...:	$Addr		- ip-адрес телевизора в сети
; ===============================================================================================================
Func _SamsungTV_PowerOff($Addr)
 Local $OffCount = 0, $Timer = TimerInit()
 While True
  _SamsungTV_SendCommand($Addr, "KEY_POWEROFF")
  Local $iPing = Ping($Addr, 100)
  If $iPing == 0 Then
   $OffCount = $OffCount + 1
  Else
   $OffCount = 0
  EndIf
  If $OffCount > 4 Then ExitLoop
  If TimerDiff($Timer) > 10000 Then Return _LogWrite("Ошибка: Невозможно отключить телевизор.")
  Sleep(250)
 WEnd
 _MySQL_Query("UPDATE `" & $sDB_TableDevices & "` SET ping = '0' WHERE id = " & $Addr & ";")
 _LogWrite("Телевизор отключен.")
EndFunc ;==>_SamsungTV_PowerOff

; #FUNCTION# ====================================================================================================
; Name...........:	_SamsungTV_Play
; Description....:	Запуск воспроизведения DLNA-медиаконтента на телевизоре
; Syntax.........:	_SamsungTV_Play($Addr{, $sCurrentURI})
; Parameter(s)...:	$Addr		- ip-адрес телевизора в сети
;					$sID		- ID медиаконтента (если = '', то отправляется событие 'KEY_PLAY')
; ===============================================================================================================
Func _SamsungTV_Play($Addr, $sID = "")
 If $sID == "" Then Return _SamsungTV_SendCommand($Addr, "KEY_PLAY")
 If Not _ReadServerConfig($Addr) Then Return
 Local $sURL = $sServerURL & '/MediaServer/Folders/0?action%3Dplayto%3Bitemid%3D' & _
  $sID & '%3Bdeviceuuid%3D' & $sDeviceUUID
 If $DEBUG Then _LogWrite('Отправка запроса медиасерверу ' & $sURL)
 InetRead($sURL, $INET_FORCERELOAD)
EndFunc ;==>_SamsungTV_Play
#EndRegion TV Control Commands

#Region Additional Functions
;------------------------------------------------ ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---------------------------------------

; #FUNCTION# ======================================================================================================
; Name...........:	_SamsungTV_StringAddHeader
; Description....:	Добавление к строке заголовка, содержащего длину строки
; Syntax.........:	_SamsungTV_StringAddHeader($sString)
; Parameter(s)...:	$sString	- исходная строка
; Return value(s):	строка, вначале которой добавлено 2 байта, соотвествующих длине строки
; Version .......:	0.0.1
; Modified.......:	27.12.2016
; =================================================================================================================
Func _SamsungTV_StringAddHeader($sString)
 Local $n = StringLen($sString)
 Local $sHeader = Chr(BitAND($n, 0xFF)) & Chr(BitAND(Floor($n / 0x100), 0xFF))
 Return $sHeader & $sString
EndFunc ;==>_SamsungTV_StringAddHeader

; #FUNCTION# ======================================================================================================
; Name...........:	_Base64Encode
; Description....:	Кодирует данные по алгоритму MIME base64
; Syntax.........:	_Base64Encode($sDdata)
; Parameter(s)...:	$sDdata		- данные для кодирования
; Return value(s):	Success: кодированные данные, в виде строки
;					Failure: пустая строка и переменная @error = 1
; Return value(s):	кодированные данные, как строку или FALSE в случае возникновения ошибки.
; Version .......:	0.0.1
; Modified.......:	27.12.2016
; =================================================================================================================
Func _Base64Encode($sDdata)
 $sDdata = Binary($sDdata)
 Local $dllStruct = DllStructCreate("byte[" & BinaryLen($sDdata) & "]")
 DllStructSetData($dllStruct, 1, $sDdata)
 Local $strc = DllStructCreate("int")
 Local $a_Call = DllCall("Crypt32.dll", _
  "int", "CryptBinaryToString", _
  "ptr", DllStructGetPtr($dllStruct), _
  "int", DllStructGetSize($dllStruct), _
  "int", 1, _
  "ptr", 0, _
  "ptr", DllStructGetPtr($strc))
 If @error Or Not $a_Call[0] Then Return SetError(1, 0, "")
 Local $a = DllStructCreate("char[" & DllStructGetData($strc, 1) & "]")
 $a_Call = DllCall("Crypt32.dll", _
  "int", "CryptBinaryToString", _
  "ptr", DllStructGetPtr($dllStruct), _
  "int", DllStructGetSize($dllStruct), _
  "int", 1, _
  "ptr", DllStructGetPtr($a), _
  "ptr", DllStructGetPtr($strc))
 If @error Or Not $a_Call[0] Then Return SetError(1, 0, "")
 Return StringTrimRight(DllStructGetData($a, 1), 2)
EndFunc ;==>_Base64Encode
#EndRegion Additional Functions
