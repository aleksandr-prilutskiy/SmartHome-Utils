#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.0
	Date...........:	30.04.2019
	Title..........:	SmartHome - Telegram Bot
	Filename.......:	Telegram.au3
	Description....:	Система "Умный дом". Скрипт отправки сообщений в Telegram
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Параметры командной строки, обрабатываемые программой:
						/? - краткая справка о параметрах командной строки
						send {id пользователей} {сообщение} - отправка сообщения
						/debug - режим отлажки (подробный отчет о выполнении)

						Внимание! id пользователей должны быть указаны через запятую, без пробелов.
						Для работы скрипта в базе данных, в таблице 'config' нужно заполнить запись
						'TelegramToken', указав токен бота.
						Если  в базе данных, в таблице 'config' задан параметр 'TelegramProxy',
						то при отправке сообщений будет использоваться соотвествующий прокси-сервер.
						Для получения токена бота необходимо создать бота, для чего в приложении
						telegram нужно найти канал @BotFather и ввести команду /newbot
						Для получения id пользователя необходимо в приложении найти созданого бота
						(по имени), отправить ему сообщение и в браузере в адресной строке ввести:
						https://api.telegram.org/bot{token}/getUpdates, где {token} - токен бота.
						Должна быть получен массив оюъектов, в котором id пользователя можно получить
						после ключевых слов '"from":{"id":' в соотвествующем сообщении.

	Versions.......:	0.0.0.1 (09.11.2017) - первая версия
						0.0.1.0 (30.07.2018) - добавлена возможность работы с прокси-серверами
						0.2.0.0 (30.04.2019) - программа адаптированна под версию сервера 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\Telegram.exe)
#pragma compile(Icon, ..\resources\icons\Telegram.ico)
#pragma compile(ProductName, Smart Home Server - Telegram Bot)
#pragma compile(FileVersion, 0.2.0.0)
#pragma compile(LegalCopyright, (c) 2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <InetConstants.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; Настройка параметров приложения
		$sAppShortName			= 'Telegram Bot'						; краткое название программы
		$iMultiRunMode			= $_MULTIRUN_MODE_ENABLE				; режим контроля многократного запуска

; Прочие переменные, используемые в приложении
Global	$sTelegramToken			= ''									; токен бота сервиса Telegram
Global	$sTelegramProxy			= ''									; адрес прокси-сервера
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
           "Telegram.exe [send] {user1,user2,...,userN} {message} {/debug}" & @CRLF & _
		   " send {users id list} {message} - отправка сообщения пользователям по списку (через ',')" & @CRLF & _
		   " /debug - режим отлажки (подробный отчет о выполнении)")
  If $CmdLine[1] == "send" Then
   If $CmdLine[0] < 3 Then Return
   _ReadServerConfig()
   _SendMessage()
   Return
  EndIf
 EndIf
 _LogWrite(" Ошибка в синтаксисе команды." & @CRLF & " Используйте 'Telegram.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region Read Config
;-------------------------------------------- ФУНКЦИИ ЗАГРУЗКИ НАСТРОЕК ПРИЛОЖЕНИЯ ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ReadServerConfig
; Description....:	Чтение настроек системы "Умный дом" из базы данных.
; Syntax.........:	_ReadServerConfig()
; ===============================================================================================================
Func _ReadServerConfig()
 $sTelegramToken = _MySQL_ReadConfig("TelegramToken")
 $sTelegramProxy = _MySQL_ReadConfig("TelegramProxy")
 If StringLen($sTelegramToken) == 0 Then
  _LogWrite(" Ошибка получения параметров отправки сообщений" & @CRLF & _
			" Проверьте запись 'TelegramToken' в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Ошибка Telegram API Token")
  _AppExit()
 EndIf
 If $DEBUG Then _
  _LogWrite("Были получены следующие настройки системы 'Умный дом':" & @CRLF & _
			" TelegramToken = " & $sTelegramToken & @CRLF & _
			" Proxy-сервер  = " & $sTelegramProxy & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region Telegram Send Message
;------------------------------------------------- ФУНКЦИИ ОТПРАВКИ СООБЩЕНИЯ -----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_SendMessage
; Description....:	Отправка сообщения в мессенджер Telegram
; Syntax.........:	_SendMessage()
; ===============================================================================================================
Func _SendMessage()
 $aTelegramUsers = _StringExplode($CmdLine[2], ",")
 If UBound($aTelegramUsers) < 1 Then
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
 If StringLen($sTelegramProxy) > 0 Then
  _LogWrite(' Используется прокси-сервер:' & $sTelegramProxy)
  HttpSetProxy(2, $sTelegramProxy)
 EndIf
 For $i = 0 To UBound($aTelegramUsers) - 1
  Local $sResponse = InetRead('https://api.telegram.org/bot' & $sTelegramToken & '/sendMessage?chat_id=' & _
	    $aTelegramUsers[$i] & '&text=' & _StringURLEncode(_StringToUTF8($sMessage)), $INET_FORCERELOAD)
  If @error Then
   _LogWrite(' Ошибка: Невозможно отправить сообщение пользователю id=' & $aTelegramUsers[$i])
   _LogWrite($sResponse)
   _SysyemLogWrite(0, 1, 'Ошибка при отправке сообщения пользователю id=' & $aTelegramUsers[$i])
  Else
   _LogWrite(' Отправлено сообщение "' & $sMessage & '" пользователю id=' & $aTelegramUsers[$i])
  EndIf
 Next
EndFunc ;==>_SendMessage
#EndRegion Telegram Send Message
