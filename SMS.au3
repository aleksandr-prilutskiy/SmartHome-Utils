#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.0
	Date...........:	30.04.2019
	Title..........:	SmartHome - SMS Bot
	Filename.......:	SMS.au3
	Description....:	Система "Умный дом". Скрипт отправки SMS-сообщений
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Параметры командной строки, обрабатываемые программой:
						/? - краткая справка о параметрах командной строки
						send {номера телефонов} {сообщение} - отправка сообщения
						/debug - режим отлажки (подробный отчет о выполнении)

						Внимание! Номера телефонов должны быть указаны через запятую,
						10 цифр номера, без '+7' или '8' в начале.
						Для работы скрипта в базе данных, в таблице 'config' нужно заполнить запись
						'SMS_API_Key', указав токен с сайта 'sms.ru'.

	Versions.......:	0.0.0.1 (04.07.2018) - первая версия
						0.2.0.0 (30.04.2019) - программа адаптированна под версию сервера 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\SMS.exe)
#pragma compile(Icon, ..\resources\icons\SMS.ico)
#pragma compile(ProductName, Smart Home Server - SMS Bot)
#pragma compile(FileVersion, 0.2.0.0)
#pragma compile(LegalCopyright, (c) 2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <InetConstants.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; Настройка параметров приложения
		$sAppShortName			= 'SMS Bot'								; краткое название программы
		$iMultiRunMode			= $_MULTIRUN_MODE_ENABLE				; режим контроля многократного запуска

; Прочие переменные, используемые в приложении
Global	$sAPPID					= ''									; ключ API на сайте 'sms.ru'
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
  If $CmdLine[1] == "/?" Then _
   Return _LogWrite("Система 'Умный дом'. Скрипт отправки сообщений в Telegram." & @CRLF & _
		   "Параметры командной строки:" & @CRLF & _
           "SMS.exe [send] {phone#1,phone#2,...,phone#N} {message} {/debug}" & @CRLF & _
		   " send {phones # list} {message} - отправка сообщения на телефоны по списку (через ',')" & @CRLF & _
		   " /debug - режим отлажки (подробный отчет о выполнении)")
  If $CmdLine[1] == "send" Then
   If $CmdLine[0] < 3 Then Return
   _ReadServerConfig()
   _SendMessage()
   Return
  EndIf
 EndIf
 _LogWrite(" Ошибка в синтаксисе команды." & @CRLF & " Используйте 'SMS.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region Read Config
;-------------------------------------------- ФУНКЦИИ ЗАГРУЗКИ НАСТРОЕК ПРИЛОЖЕНИЯ ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ReadServerConfig
; Description....:	Чтение настроек системы "Умный дом" из базы данных
; Syntax.........:	_ReadServerConfig()
; ===============================================================================================================
Func _ReadServerConfig()
 $sAPPID = _MySQL_ReadConfig("SMS_API_Key")
 If StringLen($sAPPID) == 0 Then
  _LogWrite(" Ошибка получения параметров отправки сообщений" & @CRLF & _
			" Проверьте запись 'SMS_API_Key' в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Ошибка SMS_API_Key")
  _AppExit()
 EndIf
 If $DEBUG Then _
  _LogWrite("Были получены следующие настройки системы 'Умный дом':" & @CRLF & _
			" API Key = " & $sAPPID & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region SMS Send Message
;------------------------------------------------- ФУНКЦИИ ОТПРАВКИ СООБЩЕНИЯ -----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_SendMessage
; Description....:	Отправка сообщения в мессенджер Telegram
; Syntax.........:	_SendMessage()
; ===============================================================================================================
Func _SendMessage()
 $aPhones = _StringExplode($CmdLine[2], ",")
 If UBound($aPhones) < 1 Then
  _LogWrite(' Ошибка в ID пользователя')
  _SysyemLogWrite(0, 1, 'Ошибка ID пользователя')
  _AppExit()
 EndIf
 Local $i, $sMessage = ""
 For $i = 3 To $CmdLine[0]
  $sMessage &= $CmdLine[$i] & " "
 Next
 While StringRight($sMessage, 1) == ' '
  $sMessage = StringTrimRight($sMessage, 1)
 WEnd
 If StringLower(StringRight($sMessage, 7)) == ' /debug' Then $sMessage = StringTrimRight($sMessage, 7)
 For $i = 0 To UBound($aPhones) - 1
  $sURL = 'https://sms.ru/sms/send?api_id=' & $sAPPID & '&to=7' & $aPhones[$i] & '&msg=' & $sMessage & '&json=1'
  $sResponse = BinaryToString(InetRead($sURL, $INET_FORCERELOAD), 4)
  If Not @error Then
   If $DEBUG Then _
    _LogWrite(' >' & $sURL & @CRLF & ' Ответ сервера:' & @CRLF & $sResponse & @CRLF)
   If StringInStr($sResponse, '"status_code": 100,') Then
    _LogWrite(' Отправлено сообщение "' & $sMessage & '" на номер +7' & $aPhones[$i])
    ContinueLoop
   EndIf
  EndIf
  _LogWrite(' Ошибка: Невозможно отправить сообщение на номер +7' & $aPhones[$i])
  _SysyemLogWrite(0, 1, 'Ошибка при отправке сообщения на номер +7' & $aPhones[$i])
 Next
EndFunc ;==>_SendMessage
#EndRegion SMS Send Message
