#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	SmartHome - Weather Forecast
	Filename.......:	weather.au3
	Description....:	������� "����� ���". ������ �������� �������� ������
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						update - ���������� �������� ������
						/debug - ����� ������� (��������� ����� � ����������)

						������ �������� ���������� � ����� 'openweathermap.org'.
						��� ���������� ������ ������� � ���� ������ ������� "����� ���" � ������� `config`
						������ ���� ������ `WeatherCity`, � ������� ������ ���� ��� ������, � ������
						'OpenWeatherMapAPIID', ���������� ���� API ��� �������� � ����� �������.
						����������� ������ ������� �������� ���������� ������ � ������� `weather_forecast`.

	Versions.......:	0.0.1.1 (xx.xx.2017) - ������ ���������� ������ (��������� ���������� � 'eurometeo.ru')
						0.0.1.2 (19.04.2017) - ������������� ����� ���������
						0.0.1.3 (26.05.2017) - ��������� ������ � �������� �������� �������
						0.0.1.4 (19.07.2017) - ���������� ������ � �������� �������� �������
						0.0.1.8 (12.02.2018) - �������� ����� �������
						0.0.2.0 (22.06.2018) - ������� ��������� ������ (�� 'openweathermap.org')
						0.0.2.4 (15.01.2019) - ���������� ���� ������ �� ���� ������ ������
						0.0.3.0 (05.02.2019) - ��������� ��������� ���������� ��������� ������
						0.2.0.0 (26.04.2019) - ��������� ������������� ��� ������ ������� 2.0.0
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

; ��������� ���������� ����������
		$sAppShortName			= 'Weather Forecast'					; ������� �������� ���������

; ������ ����������, ������������ � ����������
Global	$sAPPID					= ''									; ���� API �� ����� 'openweathermap.org'
Global	$sWeatherCity			= ''									; ��� ������ �� ����� 'openweathermap.org'
Global	$iChangeCount			= 0										; ���-�� ���������� ������� � ���� ������
Global	$iErrorCount			= 0										; ������� ������
#EndRegion Initialization

#Region Main Script
_AppStart()																; ���������� ��������� � ������
_Main()																	; �������� ��������� ���������
_AppExit()																; ���������� ������ ���������
#EndRegion Main Script

#Region Main
;------------------------------------------------ �������� ���������� ���������----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Main
; Description....:	�������� � ��������� ���������� ��������� ������.
; Syntax.........:	_Main()
; ===============================================================================================================
Func _Main()
 If $CmdLine[0] > 0 Then
  If $CmdLine[1] == "/?" Then _
   Return _LogWrite("������� '����� ���'. ������ �������� �������� ������." & @CRLF & _
		   "��������� ��������� ������:" & @CRLF & _
           "weather.exe [update] {/debug}" & @CRLF & _
		   " update - ���������� �������� ������" & @CRLF & _
		   " /debug - ����� ������� (��������� ����� � ����������)")
  If StringLower($CmdLine[1]) == "update" Then
   _ReadServerConfig()
   _LoadWeatherInfo()
   _CheckErrors()
   Return
  EndIf
 EndIf
 _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'weather.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region Read Config
;-------------------------------------------- ������� �������� �������� ���������� ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ReadServerConfig
; Description....:	������ �������� ������� "����� ���" �� ���� ������
; Syntax.........:	_ReadServerConfig()
; ===============================================================================================================
Func _ReadServerConfig()
 $sWeatherCity	= _MySQL_ReadConfig('WeatherCity')
 $sAPPID		= _MySQL_ReadConfig('OpenWeatherMapAPIID')
 If StringLen($sWeatherCity) == 0 Then
  _LogWrite(" ������: ����������� ������ ����� ��� ��������� ������" & @CRLF & _
			" ��������� ������ 'WeatherCity' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "�� ������ �����")
  _AppExit()
 EndIf
 If StringLen($sAPPID) == 0 Then
  _LogWrite(" ������: �� ����� API ID ��� ����� 'openweathermap.org'" & @CRLF & _
			" ��������� ������ 'OpenWeatherMapAPIID' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "�� ����� ���� API")
  _AppExit()
 EndIf
 If $DEBUG Then _
  _LogWrite("���� �������� ��������� ��������� ������� '����� ���':" & @CRLF & _
			" ��� ������ = " & $sWeatherCity & @CRLF & _
			" ���� API   = " & $sAPPID & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region MySQL Functions
;-------------------------------------------- ������� ������ � ����� ������ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateTableWeather
; Description....:	�������� � ���� ������ ������ ������� � ����������� � ������
; Syntax.........:	_CreateTableWeather()
; ===============================================================================================================
Func _CreateTableWeather()
 _MySQL_DropTable($sDB_TableWeather)
 _MySQL_Query("CREATE TABLE `" & $sDB_TableWeather & "` (" & _
  "period DATETIME, " & _					; ����� �������� ������
  "temperature DECIMAL(5,2), " & _			; ����������� ������� (�C)
  "pressure DECIMAL(6,2), " & _				; ����������� �������� (�� ��.������)
  "humidity DECIMAL(4,1), " & _				; ������������� ��������� (%)
  "symbol TEXT);")							; ��� ����������� ��������� �������
  If Not @error Then
   _LogWrite(" ������� (���� ������� ������) �������: '" & $sDB_TableWeather & "'")
  Else
   _LogWrite(" ������: ���������� ������� ������� '" & $sDB_TableWeather & "'")
   _SysyemLogWrite(0, 1, "������ ������� � ���� ������")
   _AppExit()
  EndIf
EndFunc ;==>_CreateTableWeather
#EndRegion MySQL Functions

#Region Load Weather Forecast
;------------------------------------ ������� �������� �������� ������ �� ��������� -----------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_LoadWeatherInfo
; Description....:	�������� �������� ������
; Syntax.........:	_LoadWeatherInfo()
; ===============================================================================================================
Func _LoadWeatherInfo()
 Local $i, $oXML = _XML_CreateDOMDocument(Default)
 If @error Then
  _LogWrite(' ������: ���������� ������� DOM-������ ��������� XML')
  _SysyemLogWrite(0, 1, "������ ������� ��������� XML")
  _AppExit()
 EndIf
 Local $sUrl = 'http://api.openweathermap.org/data/2.5/forecast?id=' & $sWeatherCity & '&mode=xml&' & _
  'units=metric&APPID=' & $sAPPID
 Local $sXML = BinaryToString(InetRead($sUrl, $INET_FORCERELOAD))
 If $DEBUG Then _LogWrite(@CRLF & "������ ������ � ������ �� ������ '" & $sUrl & "'" & @CRLF & $sXML & @CRLF)
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
  _LogWrite(' ������: ���������� �������� ���������� � ������ �� XML-�����:')
  _LogWrite(_XML_ErrorParser_GetDescription($oXML))
  _SysyemLogWrite(0, 1, "������ � ������� XML ���������� ������")
  _AppExit()
 EndIf
 _CreateTableWeather()
 _LogWrite(@CRLF & "���������� ������...")
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
; Description....:	��������� ��������� �������� �� XML-�����
; Syntax.........:	_XML_NodeReadAttr($oXML, $sNodeName)
; Parameter(s)...:	$oXML		- ������ XML
;					$sNodeName	- ��� ��������
; Remarks .......:	��������, ��� ������ '<pressure unit="hPa" value="100"/>' ������ 'unit="hPa" value="100"'
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
;----------------------------------------------- ������� ��������������� ----------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CheckErrors
; Description....:	�������� �� ������ �� ����������� ������ ���������
; Syntax.........:	_CheckErrors()
; ===============================================================================================================
Func _CheckErrors()
 If $iErrorCount == 0 Then
  If $DEBUG Then _LogWrite(" �� ����� ���������� ��������� ������ �� ��������")
 Else
  _LogWrite(" ����� ������ �� ����� ���������� ���������: " & $iErrorCount)
 EndIf
 Local $sText = ""
 If $iChangeCount > 0 Then $sText &= "��������� �������: " & $iChangeCount
 If $iErrorCount > 0  Then $sText &= (StringLen($sText) > 0 ? ". " : "" ) & "������: " & $iErrorCount
 _SysyemLogWrite($iChangeCount, $iErrorCount, $sText)
 _LogWrite()
EndFunc ;==>_CheckErrors
#EndRegion Check Errors Functions
