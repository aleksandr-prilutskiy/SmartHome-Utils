#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	SmartHome - Test Mesage Box
	Filename.......:	msgbox.au3
	Description....:	Система "Умный дом". Скрипт тестирования запуска приложений
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Скрипт может быть запущен вместо другой программы, входящей в систему "Умный дом" для
						диагностики запуска и отслеживания параметров вызова программы.
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\msgbox.exe)
#pragma compile(Icon, ..\resources\icons\window.ico)
#pragma compile(ProductName, Smart Home Server - Test App)
#pragma compile(FileVersion, 0.2.0.1)
#pragma compile(LegalCopyright, (c) 2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#include <InetConstants.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; Настройка параметров приложения
		$sAppShortName			= 'Test Mesage Box'						; краткое название программы
		$iMultiRunMode			= $_MULTIRUN_MODE_ENABLE				; режим контроля многократного запуска
#EndRegion Initialization

#Region Main Script
$sText = 'Тестирование запуска приложений.' & @CRLF & _
 'Параметры вызова:' & @CRLF & @CRLF
if $CmdLine[0] > 0 Then $sText &= '#1: ' & $CmdLine[1] & @CRLF
if $CmdLine[0] > 1 Then $sText &= '#2: ' & $CmdLine[2] & @CRLF
if $CmdLine[0] > 2 Then $sText &= '#3: ' & $CmdLine[3] & @CRLF
if $CmdLine[0] > 3 Then $sText &= '#4: ' & $CmdLine[4] & @CRLF
if $sText <> '' Then MsgBox(0x40, 'Система "Умный дом"', $sText, 10)
#EndRegion Main Script
