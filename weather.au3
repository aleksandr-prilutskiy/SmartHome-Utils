#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	SmartHome - Weather Forecast
	Filename.......:	weather.au3
	Description....:	Система "Умный дом". Скрипт загрузки прогноза погоды
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Параметры командной строки, обрабатываемые программой:
						/? - краткая справка о параметрах командной строки
						update - обновление прогноза погоды
						/debug - режим отлажки (подробный отчет о выполнении)

						Скрипт получает информацию с сайта 'openweathermap.org'.
						Для корректной работы скрипта в базе данных системы "Умный дом" в таблице `config`
						должна быть запись `WeatherCity`, в которой должен быть код города, и запись
						'OpenWeatherMapAPIID', содержащая ключ API для запросов к этому ресурсу.
						Результатом работы скрипта является заполнение данных в таблице `weather_forecast`.

	Versions.......:	0.0.1.1 (xx.xx.2017) - первая корректная версия (получение информации с 'eurometeo.ru')
						0.0.1.2 (19.04.2017) - оптимизирован текст программы
						0.0.1.3 (26.05.2017) - добавлена работа с журналом собыйтий системы
						0.0.1.4 (19.07.2017) - исправлена работа с журналом собыйтий системы
						0.0.1.8 (12.02.2018) - добавлен режим отладки
						0.0.2.0 (22.06.2018) - изменен поставщик данных (на 'openweathermap.org')
						0.0.2.4 (15.01.2019) - исправлены коды погоды на коды иконок погоды
						0.0.3.0 (05.02.2019) - добавлена обработка параметров командной строки
						0.2.0.0 (26.04.2019) - программа адаптированна под версию сервера 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\weather.exe)
#pragma compile(Icon, ..\resources\icons\weather.ico)
#pragma compile(ProductName, Smart Home Server - Weather Forecast)
#pragma compile(FileVersion, 0.2.0.1)
#pragma compile(LegalCopyright, (c) 2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <InetConstants.au3>
#include <UDFs\XML.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; Настройка параметров приложения
		$sAppShortName			= 'Weather Forecast'					; краткое название программы

; Прочие переменные, используемые в приложении
Global	$sAPPID					= ''									; ключ API на сайте 'openweathermap.org'
Global	$sWeatherCity			= ''									; код города на сайте 'openweathermap.org'
Global	$iChangeCount			= 0										; кол-во измененных записей в базе данных
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
  If $CmdLine[1] == "/?" Then _
   Return _LogWrite("Система 'Умный дом'. Скрипт загрузки прогноза погоды." & @CRLF & _
		   "Параметры командной строки:" & @CRLF & _
           "weather.exe [update] {/debug}" & @CRLF & _
		   " update - обновление прогноза погоды" & @CRLF & _
		   " /debug - режим отлажки (подробный отчет о выполнении)")
  If StringLower($CmdLine[1]) == "update" Then
   _ReadServerConfig()
   _LoadWeatherInfo()
   _CheckErrors()
   Return
  EndIf
 EndIf
 _LogWrite(" Ошибка в синтаксисе команды." & @CRLF & " Используйте 'weather.exe /?'")
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
 $sWeatherCity	= _MySQL_ReadConfig('WeatherCity')
 $sAPPID		= _MySQL_ReadConfig('OpenWeatherMapAPIID')
 If StringLen($sWeatherCity) == 0 Then
  _LogWrite(" Ошибка: Неправильно указан город для получения погоды" & @CRLF & _
			" Проверьте запись 'WeatherCity' в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Не указан город")
  _AppExit()
 EndIf
 If StringLen($sAPPID) == 0 Then
  _LogWrite(" Ошибка: Не задан API ID для сайта 'openweathermap.org'" & @CRLF & _
			" Проверьте запись 'OpenWeatherMapAPIID' в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Не задан ключ API")
  _AppExit()
 EndIf
 If $DEBUG Then _
  _LogWrite("Были получены следующие настройки системы 'Умный дом':" & @CRLF & _
			" Код города = " & $sWeatherCity & @CRLF & _
			" Ключ API   = " & $sAPPID & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region MySQL Functions
;-------------------------------------------- ФУНКЦИИ РАБОТЫ С БАЗОЙ ДАННЫХ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateTableWeather
; Description....:	Создание в базе данных пустой таблицы с информацией о погоде
; Syntax.........:	_CreateTableWeather()
; ===============================================================================================================
Func _CreateTableWeather()
 _MySQL_DropTable($sDB_TableWeather)
 _MySQL_Query("CREATE TABLE `" & $sDB_TableWeather & "` (" & _
  "period DATETIME, " & _					; время прогноза погоды
  "temperature DECIMAL(5,2), " & _			; температура воздуха (°C)
  "pressure DECIMAL(6,2), " & _				; атмосферное давление (мм рт.столба)
  "humidity DECIMAL(4,1), " & _				; относительная влажность (%)
  "symbol TEXT);")							; код изображения погодного явления
  If Not @error Then
   _LogWrite(" Создана (либо создана заново) таблица: '" & $sDB_TableWeather & "'")
  Else
   _LogWrite(" Ошибка: Невозможно создать таблицу '" & $sDB_TableWeather & "'")
   _SysyemLogWrite(0, 1, "Ошибка доступа к базе данных")
   _AppExit()
  EndIf
EndFunc ;==>_CreateTableWeather
#EndRegion MySQL Functions

#Region Load Weather Forecast
;------------------------------------ ФУНКЦИИ ЗАГРУЗКИ ПРОГНОЗА ПОГОДЫ ИЗ ИНТЕРНЕТА -----------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_LoadWeatherInfo
; Description....:	Загрузка прогноза погоды
; Syntax.........:	_LoadWeatherInfo()
; ===============================================================================================================
Func _LoadWeatherInfo()
 Local $i, $oXML = _XML_CreateDOMDocument(Default)
 If @error Then
  _LogWrite(' Ошибка: Невозможно создать DOM-объект обработки XML')
  _SysyemLogWrite(0, 1, "Ошибка объекта обработки XML")
  _AppExit()
 EndIf
 Local $sUrl = 'http://api.openweathermap.org/data/2.5/forecast?id=' & $sWeatherCity & '&mode=xml&' & _
  'units=metric&APPID=' & $sAPPID
 Local $sXML = BinaryToString(InetRead($sUrl, $INET_FORCERELOAD))
 If $DEBUG Then _LogWrite(@CRLF & "Чтение данных о погоде по адресу '" & $sUrl & "'" & @CRLF & $sXML & @CRLF)
 _XML_LoadXML($oXML, $sXML)
 Local $fError = True
 If Not @error Then
  Local $oNodesColl = _XML_SelectNodes($oXML, "//time")
  If Not @error Then
   Local $aNodesColl = _XML_Array_GetNodesProperties($oNodesColl)
   If Not @error Then $fError = False
  EndIf
 EndIf
 If $fError Then
  _LogWrite(' Ошибка: Невозможно получить информацию о погоде из XML-файла:')
  _LogWrite(_XML_ErrorParser_GetDescription($oXML))
  _SysyemLogWrite(0, 1, "Ошибка в формате XML полученных данных")
  _AppExit()
 EndIf
 _CreateTableWeather()
 _LogWrite(@CRLF & "Обновление данных...")
 For $i = 1 To UBound($aNodesColl) - 1
  _XML_LoadXML($oXML, $aNodesColl[$i][$__g_eARRAY_NODE_XML])
  Local $period			= _StringGetKey($aNodesColl[$i][$__g_eARRAY_ATTR_ARRAYCOLCOUNT], 'from')
  Local $temperature	= Number(_StringGetKey(_XML_NodeReadAttr($oXML, 'temperature'), 'value'))
  Local $pressure		= Number(_StringGetKey(_XML_NodeReadAttr($oXML, 'pressure'), 'value'))
  Local $humidity		= Number(_StringGetKey(_XML_NodeReadAttr($oXML, 'humidity'), 'value'))
  Local $symbol			= _StringGetKey(_XML_NodeReadAttr($oXML, 'symbol'), 'var')
  If (StringInStr($period, "T00") > 0) Or (StringInStr($period, "T03") > 0) Or _
	 (StringInStr($period, "T18") > 0) Or (StringInStr($period, "T21") > 0) Then
   $symbol = StringTrimRight($symbol, 1) & "n"
  Else
   $symbol = StringTrimRight($symbol, 1) & "d"
  EndIf
  _LogWrite($period & ": " & 'temperature = ' & $temperature & "; " & 'pressure = ' & _
   $pressure & "; " & 'humidity = ' & $humidity & "; " & 'symbol = ' & $symbol)
  _MySQL_Query("INSERT INTO `" & $sDB_TableWeather & "` " & _
   "(period, temperature, pressure, humidity, symbol) VALUES (" & _
      "'" & $period & "', " & _						; period
			$temperature & ", " & _					; temperature
			$pressure & ", " & _					; pressure
			$humidity &", " & _						; humidity
	  "'" & $symbol & "');")						; symbol
  If @error Then
   $iErrorCount += 1
  Else
   $iChangeCount += 1
  EndIf
 Next
EndFunc ;==>_LoadWeatherInfo

; #FUNCTION# ====================================================================================================
; Name...........:	_XML_NodeReadAttr
; Description....:	Получение атрибутов элемента из XML-файла
; Syntax.........:	_XML_NodeReadAttr($oXML, $sNodeName)
; Parameter(s)...:	$oXML		- объект XML
;					$sNodeName	- имя элемента
; Remarks .......:	Например, для записи '<pressure unit="hPa" value="100"/>' вернет 'unit="hPa" value="100"'
; ===============================================================================================================
Func _XML_NodeReadAttr(ByRef $oXML, $sNodeName)
 Local $oNodesColl = _XML_SelectNodes($oXML, '//' & $sNodeName)
 If @error Then Return ''
 Local $aNodesColl = _XML_Array_GetNodesProperties($oNodesColl)
 If @error Then Return ''
 Return $aNodesColl[1][$__g_eARRAY_ATTR_ARRAYCOLCOUNT]
EndFunc ;==>_XML_NodeReadAttr
#EndRegion Load Weather Forecast

#Region Check Errors Functions
;----------------------------------------------- ФУНКЦИИ САМОДИАГНОСТИКИ ----------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CheckErrors
; Description....:	Проверка на ошибки по результатам работы программы
; Syntax.........:	_CheckErrors()
; ===============================================================================================================
Func _CheckErrors()
 If $iErrorCount == 0 Then
  If $DEBUG Then _LogWrite(" Во время выполнения программы ошибок не возникло")
 Else
  _LogWrite(" Всего ошибок во время выполнения программы: " & $iErrorCount)
 EndIf
 Local $sText = ""
 If $iChangeCount > 0 Then $sText &= "Добавлено записей: " & $iChangeCount
 If $iErrorCount > 0  Then $sText &= (StringLen($sText) > 0 ? ". " : "" ) & "Ошибок: " & $iErrorCount
 _SysyemLogWrite($iChangeCount, $iErrorCount, $sText)
 _LogWrite()
EndFunc ;==>_CheckErrors
#EndRegion Check Errors Functions
