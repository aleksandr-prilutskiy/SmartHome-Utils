#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	SmartHome - DDNS Update
	Filename.......:	DDNS.au3
	Description....:	Система "Умный дом". Скрипт обновления записи DDNS
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Параметры командной строки, обрабатываемые программой:
						/? - краткая справка о параметрах командной строки
						test - проверка доменов DDNS
						update - обновление записи DDNS
						/debug - режим отлажки (подробный отчет о выполнении)

						Для работы скрипта в базе данных, в таблице 'config' нужно заполнить записи:
						'DDNS_Domains', 'DDNS_User' и 'DDNS_Password', в которых нужно указать
						соотвественно домен, имя пользователя и пароль на сайте 'ddns.net'.
						В поле 'DDNS_Domains' можно указывать несколько доменов, привязанных к
						указанной учетной записи, через точку с зяпятой ';'.

	Versions.......:	0.0.1.0 (19.07.2017) - первая версия программы
						0.0.2.0 (06.02.2019) - добавлена обработка параметров командной строки
						0.0.2.3 (11.02.2019) - добавлена команда test и отчет о выполнении скрипта
						0.2.0.0 (26.04.2019) - программа адаптированна под версию сервера 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\DDNS.exe)
#pragma compile(Icon, ..\resources\icons\DNS.ico)
#pragma compile(ProductName, Smart Home Server - Weather Forecast)
#pragma compile(FileVersion, 0.2.0.1)
#pragma compile(LegalCopyright, (c) 2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <UDFs\NoIP.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; Настройка параметров приложения
		$sAppShortName			= 'DDNS Update'							; краткое название программы

; Прочие переменные, используемые в приложении
Global	$sDDNS_Domains			= ''									; имя домена
Global	$sDDNS_User				= ''									; имя пользователя
Global	$sDDNS_Password			= ''									; пароль
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
   Return _LogWrite("Система 'Умный дом'. Скрипт обновления динамической записи DNS (DDNS)." & @CRLF & _
		   "Параметры командной строки:" & @CRLF & _
           "DDNS.exe [update] {/debug}" & @CRLF & _
		   " test - проверка доменов DDNS" & @CRLF & _
		   " update - обновление записи DDNS" & @CRLF & _
		   " /debug - режим отлажки (подробный отчет о выполнении)")
  If $CmdLine[1] == "test" Then
   _ReadServerConfig()
   _TestRecordDDNS()
   Return
  ElseIf $CmdLine[1] == "update" Then
   _ReadServerConfig()
   _UpdateRecordDDNS()
   Return
  EndIf
 EndIf
 _LogWrite(" Ошибка в синтаксисе команды." & @CRLF & " Используйте 'DDNS.exe /?'")
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
 Local $i, $Query, $sDir
 $sDDNS_User	 = _MySQL_ReadConfig('DDNS_User')
 $sDDNS_Password = _MySQL_ReadConfig('DDNS_Password')
 $sDDNS_Domains	 = _MySQL_ReadConfig('DDNS_Domains')
 If (StringLen($sDDNS_User) == 0) Or (StringLen($sDDNS_Password) == 0) Or (StringLen($sDDNS_Domains) == 0) Then
  _LogWrite(" Ошибка получения параметров DDNS сервера" & @CRLF & _
			" Проверьте записи 'DDNS_User', 'DDNS_Password' и 'DDNS_Domains'" & _
			" в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Ошибка параметров DDNS сервера")
  _AppExit()
 EndIf
 If $DEBUG Then _
  _LogWrite("Были получены следующие настройки системы 'Умный дом':" & @CRLF & _
			" DDNS_User =     " & $sDDNS_User & @CRLF & _
			" DDNS_Password = " & $sDDNS_Password & @CRLF & _
			" DDNS_Domains  = " & $sDDNS_Domains & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region DDNS Functions
;-------------------------------------------- ФУНКЦИИ РАБОТЫ С ЗАПИСЬЮ DDNS -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_TestRecordDDNS
; Description....:	Проверка записи DDNS сервера
; Syntax.........:	_TestRecordDDNS()
; ===============================================================================================================
Func _TestRecordDDNS()
 _LogWrite("Проверка записи домена (доменов):")
 Local $aDomain = _StringExplode($sDDNS_Domains, ";")
 For $i = 0 To UBound($aDomain) - 1
  Local $sDDNS_IP_Old = _NOIP_HostnameResolve($aDomain[$i])
  If @error Then
   _LogWrite(" " & $aDomain[$i] & @CRLF & "  не приязан к IP-адресу" & @CRLF)
  Else
   _LogWrite(" " & $aDomain[$i] & @CRLF & "  ->" & $sDDNS_IP_Old & @CRLF)
  EndIf
 Next
 _LogWrite()
EndFunc ;==>_TestRecordDDNS

; #FUNCTION# ====================================================================================================
; Name...........:	_UpdateRecordDDNS
; Description....:	Обновление записи DDNS сервера
; Syntax.........:	_UpdateRecordDDNS()
; ===============================================================================================================
Func _UpdateRecordDDNS()
 Local $i, $iErrorCount = 0, $iChangeCount = 0
 _LogWrite("Обновление записи домена (доменов): '" & $sDDNS_Domains & "'")
 If $DEBUG Then _LogWrite(" Домены были связаны со следующими адресами:")
 Local $aDomain = _StringExplode($sDDNS_Domains, ";")
 Dim $aIP[UBound($aDomain)]
 For $i = 0 To UBound($aDomain) - 1
  $aIP[$i] = _NOIP_HostnameResolve($aDomain[$i])
  If $DEBUG Then _LogWrite(" " & $aDomain[$i] & " = " & ($aIP[$i] == "" ? "адрес не указан" : $aIP[$i]))
 Next
 If $DEBUG Then _LogWrite()
 For $i = 0 To UBound($aDomain) - 1
  _NOIP_DNSUpdate($sDDNS_User, $sDDNS_Password, $aDomain[$i])
  If @error Then
   _LogWrite(" Ошибка обновления записи DDNS сервера для домена: '" & $aDomain[$i] & "'")
   $aIP[$i] = ""
   $iErrorCount += 1
  Else
   _LogWrite(" Запись домена: '" & $aDomain[$i] & "' - успешно обновлена")
  EndIf
 Next
 _LogWrite()
 Local $sText = ""
 Local $sIP = __NOIP_GetIpAddress()
 For $i = 0 To UBound($aDomain) - 1
  If StringLen($aIP[$i]) > 0 Then
   If ($sIP <> $aIP[$i]) Or $DEBUG Then _
    _LogWrite(" Домен '" & $aDomain[$i] & "' теперь связан с IP-адресом: " & $sIP)
   If $sIP <> $aIP[$i] Then $iChangeCount += 1
  Else
   _LogWrite(" Ошибка. Домен '" & $aDomain[$i] & "' - не отвечает")
  EndIf
 Next
 If $iChangeCount > 0 Then $sText &= "Изменено записей: " & $iChangeCount
 If $iErrorCount > 0 Then $sText &= (StringLen($sText) > 0 ? "; " : "") & "Всего ошибок: " & $iErrorCount
 If StringLen($sText) > 0 Then _SysyemLogWrite($iChangeCount, $iErrorCount, $sText)
EndFunc ;==>_UpdateRecordDDNS
#EndRegion DDNS Functions
