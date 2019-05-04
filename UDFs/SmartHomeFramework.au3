#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	Smart Home Framework
	Filename.......:	SmartHomeFramework.au3
	Description....:	������� "����� ���". ��������� ��� �������� ������ ������� "����� ���"
	Author(s)......:	Aleksandr Prilutskiy

	Remarks........:	������ �������� ����������-�������:
=================================================================================================================
#Region Initialization
#pragma compile(Out, ..\Bin\{��� �����}.exe)
#pragma compile(Icon, ..\Resources\Icons\{�����������}.ico)
#pragma compile(ProductName, Smart Home Server - {��������})
#pragma compile(FileVersion, {������})
#pragma compile(LegalCopyright, {copyright})
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <..\UDFs\SmartHomeFramework.au3>
...
Opt("TrayIconHide", 1)
		$sAppTitle				= '{��� �����}'							; ����� ������ ���������� (exe, log..)
		$sAppShortName			= '{��������}'							; ������� �������� ����������
...
#EndRegion Initialization

#Region Main Script
_AppStart('{�������}\')													; ���������� ���������� � ������
_Main()																	; �������� ��������� ����������
_AppExit()																; ���������� ������ ����������
#EndRegion Main Script
=================================================================================================================

#CURRENT# =======================================================================================================

������� ����������� ������ ����������:
_AppStart				- ���������� ��������� � ������
_LoadConfigFile			- �������� �������� ��������� �� ����� ������������
_CreateTempDir			- �������� �������� ���������� ��������� ������
_AppExit				- ���������� ������ ���������

������� ������� �������� �������:
_LogWrite				- ����� ��������� �� ����� � ������ ��� � ���� �������
_SysyemLogWrite			- ���������� ������ � ������ ������� ������� "����� ���"
_GetTimeStamp			- ��������� �������� ������� � ����������� ����

������� ������ � ����� ������:
_MySQL_Start			- ������������� ������ � ����� ������ � �������� ����� �������
_MySQL_CheckTable		- �������� ������������� ������� � ���� ������
_MySQL_DropTable		- �������� ������� �� ���� ������
_MySQL_GetCount			- ������� ���������� ��������� � �������
_MySQL_ReadConfig		- ������ ������ �� ������� �������� ������� "����� ���"
_MySQL_Query			- ���������� ������� � ���� ������
_MySQL_StringCode		- �������������� ��������� ������ � ������ MySQL
_MySQL_Log				- ���������� ������ � ������ ������ � ����� ������
_MySQL_End				- ���������� ������ � ����� ������

��������� �������:
_StringGetKey			- ��������� �������� ���� � ������
_StringURLEncode		- ����������� ��������� ������ � ������� URL
_String_LiteralsDecode	- ������������� ��������� ������, ���������� ���������� ��������
_String_ANSIToOEM		- �������������� ������ �� ��������� ANSI � OEM
_StringToUTF8			- �������������� ������ � ��������� UTF8
_StringToUTF8_X			- �������� � ������ �������, ���������� 2�� ������� � �����
_TimeToString			- ����������� ���������� ��������� � ���� ��������� ������

������� ��������� �����:
_Max					- ����� ����������� �������� �� ���� �����
_Min					- ����� ����������� �������� �� ���� �����
=================================================================================================================
#CE
#EndRegion Header

#Region Initialization
#include <String.au3>
#include <Array.au3>
#include <Crypt.au3>
#include <AutoItConstants.au3>
#include <FileConstants.au3>

; ��������� ������ �������
Global Enum _
 $_DEBUG_MODE_OFF, _													; ��� ���������������� ������
 $_DEBUG_MODE_ERROR, _													; ������ ������ ������
 $_DEBUG_MODE_ALL														; ������ ���� SQL-��������

; ��������� ������ �������� ������������� ������� ����������
Global Enum _
 $_MULTIRUN_MODE_DISABLE, _												; ������������ ������ ��������
 $_MULTIRUN_MODE_ENABLE													; ������������ ������ ��������

; ��������� ������ ������� ���������
Global	$device_option_Ping			= 0x0001;
Global	$device_option_Can_Off		= 0x0002;
Global	$device_option_Can_On		= 0x0004;
Global	$device_option_All_Off		= 0x0008;
Global	$device_option_Play_Music	= 0x0010;
Global	$device_option_Play_Video	= 0x0020;

Global	$sProjectName			= "Smart Home Server"					; ������������ �������
Global	$sAppTitle				= ''									; ��������� ���������
Global	$sAppShortName			= ''									; ������� �������� ���������
Global	$sAppName				= $sProjectName & '. '					; ������ �������� ���������
Global	$AppVersion				= ''									; ������� ������ ���������
Global	$sIniFileName			= @ScriptDir & "\SmartHomeServer.ini"	; ��� ����� ������������ ���������
Global	$sLogFileName			= ''									; ��� ����� �������
Global	$DEBUG					= False									; ������� ������ �������
Global	$sEncryptKey			= 'pgXQt5oXDA'							; ���� ���������� ������ � ini-�����
Global	$sServerAppDir			= @ScriptDir							; �������� ������� �������
Global	$sAppTempDir			= ''									; ������� ���������� ��������� ������
Global	$AppTimer				= TimerInit()							; ������ ������� ���������� ���������
Global	$sSQL_Driver			= "{MySQL ODBC 3.51 Driver}"			; ��� ������������� �������� ��� ������
Global	$sSQL_Host				= "127.0.0.1"							; ����� ������� ��� ������
Global	$sSQL_Database			= "test"								; ��� ���� ������
Global	$sSQL_Username			= "root"								; ����� ��� ����������� � ���� ������
Global	$sSQL_Password			= ""									; ������ ��� ����������� � ���� ������
Global	$sSQL_LogFileName		= ""									; ��� ����� ������� �������� � ����� ������
Global	$SQL					= -1									; ��������� ������� ��� ������ � ����
Global	$iSQL_DebugMode			= $_DEBUG_MODE_ERROR					; ����� ������ ���������������� ������
Global	$iMultiRunMode			= $_MULTIRUN_MODE_DISABLE				; ����� �������� ������������� �������
Global	$oMySQLError			= ObjEvent("AutoIt.Error","_MySQLError"); ��������� ������ ��� ������ � ����
#EndRegion Initialization

#Region Database Tables
;------------------------------------------ ������������ ������ � ���� ������ -----------------------------------
; 1. �������� ������� �������
Global	$sDB_TableConfig			= "config"							; ������� �������� ��������� ����������
Global	$sDB_TableUser				= "user"							; ������� �� ������� �������������
Global	$sDB_TableEvents			= "events"							; ������� ������� �������
Global	$sDB_TableShedule			= "shedule"							; ������� ����������� ������� �������
Global	$sDB_TableScripts			= "scripts"							; ������� ���������
Global	$sDB_TableStates			= "variables"						; ������� ���������� �������
Global	$sDB_TableLog				= "system_log"						; ������� ������� ������� �������

; 2. ������� ��� ������ � ������������ � ��������� � ����
Global	$sDB_TableDevices			= "devices"							; ������ ��������� "������ ����"
Global	$sDB_TableSensors			= "sensors"							; ������ �������� "������ ����"
Global	$sDB_TableSensorsData		= "sensors_data"					; �������� ��������� �������� "������ ����"
Global	$sDB_Table_nooLite		    = "noolite"							; ��� ��������� nooLite

; 3. ������� ��������� ���-���������� �������
Global	$sDB_TableUserWidgets		= "user_widgets"					; ������� �������� �������� ������� ��������
Global	$sDB_TableMediaFavorite		= "media_favorite"					; ������� ���������� ������������� �������������
Global	$sDB_TableMediaBrowsed		= "media_browsed"					; ������� ������������� �������������

; 4. ������� ��� ����������� ��������
; ��������� �������� Music.au3
Global	$sDB_TableMusicFiles		= "music_files"						; ������� ����������� ������
Global	$sDB_TableMusicAlbums		= "music_albums"					; ������� �������� ����������� ������
Global	$sDB_TableMusicArtists		= "music_artists"					; ������� ������������ ����������� ������
; ��������� �������� Movies.au3
Global	$sDB_TableMoviesFiles		= "movies_files"					; ������� ������ � ��������
Global	$sDB_TableMoviesInfo		= "movies_info"						; ������� ���������� � �������
Global	$sDB_TableMoviesCollections	= "movies_collections"				; ������� ��������� �������
Global	$sDB_TableMoviesMetadata	= "movies_metadata"					; ������� ����������, ��������� � ��������
; ��������� �������� Series.au3
Global	$sDB_TableSeriesFiles		= "series_files"					; ������� ������ ��������
Global	$sDB_TableSeriesInfo		= "series_info"						; ������� ���������� � ��������
Global	$sDB_TableSeriesSeasons		= "series_seasons"					; ������� ������� ��������
; ��������� �������� Photo.au3
Global	$sDB_TablePhotoFiles		= "photo_files"						; ������� ������ ����������
Global	$sDB_TablePhotoAlbums		= "photo_albums"					; ������� �������� ����������
; ��������� �������� TV_Program.au3
Global	$sDB_TableTVChannels		= "tv_channel"						; ������� ������ ������������� �������
Global	$sDB_TableTVChannelMap		= "tv_channel_map"					; �������� ������������� ������� � �����������
Global	$sDB_TableTVProgram			= "tv_program"						; ������� ������ ������������� �������

; 5. ������ �������
; ��������� �������� SysInfo.au3
Global	$sDB_TableSysInfo		= "server_sysinfo"						; ���������� �� ���������� �������� �������
; ��������� �������� SMART.au3
Global	$sDB_TableSysSMART		= "server_smart_hdd"					; ������� S.M.A.R.T. ������� ������
; ��������� �������� Weather.au3
Global	$sDB_TableWeather		= "weather_forecast"					; ������� � ��������� ������
#EndRegion Database Tables

#Region Application Functions
;---------------------------------------- ������� ����������� ������ ���������� ---------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_AppStart
; Description....:	���������� ��������� � ������
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
    _LogWrite("����� ��������� ��� ��������.")
    _SysyemLogWrite(0, 1, "������������ ��������� ������ ���������")
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
   _LogWrite("����������� ����� �������!")
   ExitLoop
  EndIf
 Next
 _LogWrite()
EndFunc ;==>_AppStart

; #FUNCTION# ====================================================================================================
; Name...........:	LoadConfigFile
; Description....:	�������� �������� ��������� �� ����� ������������
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
   _LogWrite("������: �� ������ ���� '" & $sIniFileName & "'")
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
; Description....:	�������� �������� ���������� ��������� ������
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
  _LogWrite("������ ������� ���������� ��������� ������: " & $sTempDir)
  $sAppTempDir = $sTempDir
  Return True
 EndIf
 _LogWrite("������: ���������� ������� ������� ���������� ��������� ������")
 Return False
EndFunc ;==>_CreateTempDir

; #FUNCTION# ====================================================================================================
; Name...........:	_AppExit
; Description....:	���������� ������ ���������
; Syntax.........:	_AppExit()
; ===============================================================================================================
Func _AppExit()
 _MySQL_End()
 If ($sAppTempDir <> '') And FileExists($sAppTempDir) Then
  DirRemove($sAppTempDir, $DIR_REMOVE)
  If Not FileExists($sAppTempDir) Then
   _LogWrite("������� ���������� ��������� ������ ������")
   $sAppTempDir = ''
  Else
   _LogWrite("������: ���������� ������� ������� ���������� ��������� ������")
  EndIf
 EndIf
 _LogWrite("����� ���������� ���������: " & _TimeToString(TimerDiff($AppTimer)))
 Exit
EndFunc ;==>_AppExit
#EndRegion Application Functions

#Region Log Functions
;------------------------------------------- ������� ������� �������� ������� -----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_LogWrite
; Description....:	����� ��������� �� ����� � ������ ��� � ���� �������
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
; Description....:	���������� ������ � ������ ������� ������� "����� ���" (� ���� ������)
; Syntax.........:	_SysyemLogWrite($iRecords, $iErrors[, $sText[, $sEvent, [, $fSaveFile]]])
; Parameter(s)...:	$iRecords	- ���������� ������� ���������� ������� � ���� ������
;					$iErrors	- ���������� ���������� ������
;					$sText		- ������� �������� �������
;					$sEvent		- �������� �������
;					$fSaveFile	- ���� TRUE, �� � ������ ������� ������������ ���� ������� ������ ���������
; ===============================================================================================================
Func _SysyemLogWrite($iRecords, $iErrors, $sText = "", $sEvent = "", $fSaveFile = True)
 Local $ErrorFlag = 0
 If $iErrors <> 0 Then
  $ErrorFlag = 1
  If $sEvent == "" Then $sEvent = "��������� � ��������"
 EndIf
 If $sEvent == "" Then $sEvent = "�������� ����������"
 If $sText == "" Then
  If $iRecords > 0 Then $sText = "��������� �������: " & $iRecords
  If $iErrors > 0 Then
   If $sText <> "" Then $sText &= ". "
   $sText &= "����� ������: " & $iErrors
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
; Description....:	��������� �������� ������� � ����������� ���� (����.�����.��� ����:������:�������)
; Syntax.........:	_GetTimeStamp()
; Return values..:	������ � �������: "����.�����.��� ����:������:�������"
; ===============================================================================================================
Func _GetTimeStamp()
 Return @MDAY & "." & @MON & "." & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC
EndFunc ;==>_GetTimeStamp
#EndRegion Log Functions

#Region MySQL Functions
;-------------------------------------------- ������� ������ � ����� ������ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_Start
; Description....:	������������� ������ � ����� ������ � �������� ����� �������
; Syntax.........:	_MySQL_Start([$sLogFileName])
; Parameters.....:	$sLogFileName	- ��� ����� ������� �������� � ����� ������
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
   _MySQL_Log('�������� ����������� � ���� ������ :' & $sSQL_Database, $_DEBUG_MODE_ALL)
   _MySQL_Query("SET NAMES 'cp1251'")
   If $iSQL_DebugMode == $_DEBUG_MODE_ALL Then _
   _LogWrite(_GetTimeStamp() & ": �������� ����������� � ���� ������ '" & $sSQL_Database & "'")
   Return
  Case 1
   _MySQL_Log('������ ��������� ���������� � ����� ������')
   _LogWrite('������: �� ����������� ���������� � ����� ������')
  Case 2
   _MySQL_Log('������� MySQL ODBC �� ����������')
   _LogWrite('������: �� ���������� ������� MySQL ODBC')
  Case Else
   _MySQL_Log('������ ���� ������ #' & $iSQLError)
   _LogWrite('������: ������ ���� ������ #' & $iSQLError)
 EndSwitch
 _AppExit()
EndFunc ;==>_MySQL_Start

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_CheckTable
; Description....:	�������� ������������� ������� � ���� ������
; Syntax.........:	_MySQL_CheckTable($sTableName)
; Parameters.....:	$sTableName	- ������������ �������
; Return Value(s):  On Success	- ��������� ��������:
;						True	- ���� ��������� ������� ����������
;						False	- ���� ��������� ������� �� ����������
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
; Description....:	�������� ������� �� ���� ������
; Syntax.........:	_MySQL_DropTable($sTableName)
; Parameters.....:	$sTableName	- ������������ �������
; Date...........:	22.12.2016
; ===============================================================================================================
Func _MySQL_DropTable($sTableName)
 If Not IsObj($SQL) Then Return
 If _MySQL_CheckTable($sTableName) Then _MySQL_Query("DROP TABLE `" & $sTableName & "`;")
EndFunc ;==>_MySQL_DropTable

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_GetCount
; Description....:	������� ���������� ��������� � �������
; Syntax.........:	_MySQL_GetCount($sTableName{, $sFieldName}{, $sWhereStr})
; Parameter(s)...:	$sTableName	- ��� ������� � ���� ������
;					$sFieldName	- ��� ���� � �������, �� �������� ����� ����������� �������
;					$sWhereStr	- ��������� ������ (������� 'WHERE', �� ��� ';' � �����)
; Return values..:	On Success	- ���������� ��������� � �������
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
; Description....:	������ ������ �� ������� �������� ������� "����� ���"
; Syntax.........:	_MySQL_ReadConfig($sParameter)
; Parameter(s)...:	$sParameter	- ��� ��������� (������) � ������� ��������
; Return values..:	On Success	- ���������� ��������� � �������
;                   On Failure	- ������ ������
; Modified.......:	13.02.2018
; ===============================================================================================================
Func _MySQL_ReadConfig($sParameter)
 Local $Query = _MySQL_Query("SELECT data FROM `" & $sDB_TableConfig & "` WHERE name = '" & $sParameter& "';")
 If IsObj($Query) Then Return $Query.Fields(0).value
 Return ""
EndFunc ;==>_MySQL_ReadConfig

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_Query
; Description....:	���������� ������� � ���� ������
; Syntax.........:	_MySQL_Query($sQuery)
; Parameters.....:	$sQuery	    - ������, ���������� ������ �� ����� SQL
; Return Value(s):  On Success	- ��������� ���������� �������
;                   On Failure	- ������ ������ � �������������� @error = 1
; Date...........:	26.06.2018
; ===============================================================================================================
Func _MySQL_Query($sQuery)
 If Not IsObj($SQL) Then Return SetError(1)
 _MySQL_Log($sQuery, $_DEBUG_MODE_ALL)
 $Result = $SQL.execute($sQuery)
 If @error Then
  _MySQL_Log("���������� ��������� ������")
  Return SetError(1, 0, "")
 EndIf
 Return $Result
EndFunc ;==>_MySQL_Query

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_StringCode
; Description....:	�������������� ��������� ������ � ������ MySQL
; Syntax.........:	_MySQL_StringCode($sText)
; Parameters.....:	$sText	    - �������� ������
; Return Value(s):  ������, ��������������� ���������� MySQL
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
; Description....:	���������� ������ � ������ ������ � ����� ������
; Syntax.........:	_MySQL_Log($sMessage{, $ErrorLevel})
; Parameter(s)...:	$sMessage	- ����� ��� ������ � ������
;					$ErrorLevel	- ������� ����������������, ����������� ������ ����� ������� � ������
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
; Description....:	��������� ������ ��� ������ � ����� ������
; Syntax.........:	_MySQLError()
; Remarks .......:	������������� ���� ��� �������� ObjEvent("AutoIt.Error","_MySQLError")
; ===============================================================================================================
Func _MySQLError()
 _MySQL_Log($oMySQLError.description)
EndFunc ;==>_MySQLError

; #FUNCTION# ====================================================================================================
; Name...........:	_MySQL_End
; Description....:	���������� ������ � ����� ������
; Syntax.........:	_MySQL_End()
; ===============================================================================================================
Func _MySQL_End()
 If $SQL == -1 Then Return
 If Not IsObj($SQL) Then Return SetError(1)
 $SQL.close
EndFunc ;==>_MySQL_End
#EndRegion MySQL Functions

#Region String Functions
;-------------------------------------------------- ��������� ������� -------------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_StringGetKey
; Description....:	��������� �������� ���� � ������
; Syntax.........:	_StringGetKey($sStr, $sKey)
; Parameter(s)...:	$sStr		- �������� ������
;					$sKey		- ���� ���� ��� ������
; Remarks .......:	��������, ��� ������ 'unit="hPa" value="100"' � ����� 'value' ������ '100'
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
; Description....:	����������� ��������� ������ � ������� URL
; Syntax.........:	_StringURLEncode($sText)
; Remarks .......:	��������� ������ ������� - ��������� ������ � ������� URL
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
; Description....:	������������� ��������� ������, ���������� ���������� ��������
; Syntax.........:	_String_LiteralsDecode($sText)
; Remarks .......:	��������� ������ ������� - �������������� ��������� ������
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
 $s = StringReplace($s, "&laquo;",	"�")
 $s = StringReplace($s, "&raquo;",	"�")
 $s = StringReplace($s, "&sect;",	"�")
 $s = StringReplace($s, "&deg;",	"�")
 $s = StringReplace($s, "&para;",	"�")
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
    $c = '�'
   Case 0x00B0
    $c = '�'
   Case 0x00B2
    $c = '2'
   Case 0x00B3
    $c = '3'
   Case 0x00B7
    $c = '-'
   Case 0x00BB
    $c = '�'
   Case 0x00C6
    $c = 'AE'
   Case 0x00E0, 0x00E2, 0x00E4
    $c = 'a'
   Case 0x00E8, 0x00E9, 0x00EA
    $c = 'e'
   Case 0x00F3, 0x00F4, 0x00F6
    $c = 'o'
   Case 0x0401
    $c = '�'
   Case 0x0410 To 0x042F
    $c = Chr(Asc('�') + $iCode - 0x0410)
   Case 0x0430 To 0x044F
    $c = Chr(Asc('�') + $iCode - 0x0430)
   Case 0x0451
    $c = '�'
   Case 0x00DE
    $c = 'P'
   Case 0x2116
    $c = '�'
   Case Else
    $c = "(#0x" & Hex($iCode, 4) & ")"
  EndSwitch
  $s = StringLeft($s, $i - 1) & $c & StringTrimLeft($s, $j)
 WEnd
 Return $s
EndFunc ;==>_String_LiteralsDecode

; #FUNCTION# ====================================================================================================
; Name...........:	_String_ANSIToOEM
; Description....:	�������������� ������ �� ��������� ANSI � OEM
; Syntax.........:	_String_ANSIToOEM($sString)
; Parameter(s)...:	$sString	- �������� ������
; Return values .: 	Success:	��������������� ������
;					Failure:	������ ������, ���������� @error ��������������� � ��������� ��������:
;						1 - ������ DLL
;						2 - ���������� �������������� ������
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
; Description....:	�������������� ������ � ��������� UTF8
; Syntax.........:	_StringToUTF8($sString)
; Parameter(s)...:	$sString	- �������� ������ � ������� ANSI
; Return values .: 	Success:	��������������� ������
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
; Description....:	�������� � ������ �������, ���������� 2�� ������� � ����� �� ������������������ /x{���}
; Syntax.........:	_StringToUTF8_X($sString)
; Parameter(s)...:	$sString	- �������� ������ � ������� ANSI
; Return values .: 	Success:	��������������� ������
; Remarks .......:	����� �������� ��������
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
 $sTxt = StringReplace($sTxt, '\xD0\x90', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x91', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x92', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x93', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x94', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x95', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x01', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x96', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x97', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x98', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x99', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x9A', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x9B', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x9C', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x9D', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x9E', '�')
 $sTxt = StringReplace($sTxt, '\xD0\x9F', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA0', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA1', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA2', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA3', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA4', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA5', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA6', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA7', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA8', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xA9', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xAA', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xAB', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xAC', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xAD', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xAE', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xAF', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB0', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB1', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB2', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB3', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB4', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB5', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x91', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB6', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB7', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB8', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xB9', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xBA', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xBB', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xBC', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xBD', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xBE', '�')
 $sTxt = StringReplace($sTxt, '\xD0\xBF', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x80', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x81', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x82', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x83', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x84', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x85', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x86', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x87', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x88', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x89', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x8A', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x8B', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x8C', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x8D', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x8E', '�')
 $sTxt = StringReplace($sTxt, '\xD1\x8F', '�')
 Return $sTxt
EndFunc ;==>_StringToUTF8_X

; #FUNCTION# ======================================================================================================
; Name...........:	_TimeToString($iNum1, $iNum2)
; Description....:	����������� ���������� ��������� � ���� ��������� ������
; Syntax.........:	_TimeToString($Timer)
; Parameter(s)...:	$Timer		- ��������� �������� (� �������������)
; Return value(s):	������ � �������: 'XX ���. XX ���. XX.XXX ���.'
; Modified.......:  12.02.2018
; =================================================================================================================
Func _TimeToString($Timer)
 If $Timer > 3600000 Then Return Floor($Timer / 3600000) & " ���. " & _TimeToString(Mod($Timer, 3600000))
 If $Timer > 60000 Then Return Floor($Timer / 60000) & " ���. " & _TimeToString(Mod($Timer, 60000))
 Return Round($Timer /  1000, 3) & " ���."
EndFunc ;==>_TimeToString
#EndRegion String Functions

#Region Numeric Functions
;----------------------------------------------- ������� ��������� ����� ----------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Max($iNum1, $iNum2)
; Description....:	����� ����������� �������� �� ���� �����
; Syntax.........:	_Max($iNum1, $iNum2)
; Parameter(s)...:	$iNum1		- ������� �����
;					$iNum2		- ������ �����
; Return value(s):	���������� �������� ���� �����
; Modified.......:  05.10.2017
; ===============================================================================================================
Func _Max($iNum1, $iNum2)
 Return ($iNum1 > $iNum2) ? $iNum1 : $iNum2
EndFunc ;==>_Max

; #FUNCTION# ====================================================================================================
; Name...........:	_Min($iNum1, $iNum2)
; Description....:	����� ����������� �������� �� ���� �����
; Syntax.........:	_Min($iNum1, $iNum2)
; Parameter(s)...:	$iNum1		- ������� �����
;					$iNum2		- ������ �����
; Return value(s):	���������� �������� ���� �����
; Modified.......:  05.10.2017
; ===============================================================================================================
Func _Min($iNum1, $iNum2)
 Return ($iNum1 < $iNum2) ? $iNum1 : $iNum2
EndFunc ;==>_Min
#EndRegion Numeric Functions
