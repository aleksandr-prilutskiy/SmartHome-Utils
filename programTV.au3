#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	02.05.2019
	Title..........:	SmartHome - TV Program Update
	Filename.......:	programTV.au3
	Description....:	������� "����� ���". ������ �������� �������� ������������� �������
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						update - ���������� �������� ������������� �������
						/debug - ����� ������� (��������� ����� � ����������)

						�������� ������ �������:
						1. �� ��������� ����������� ���� `xmltv.xml.gz` �� ��������� �������.
						2. ���� `xmltv.xml.gz` ��������������� ���������� `7z.exe`. ��� ��������� ������ ����
						����������� �� ����������, � ���� `7z.exe` ������ ���� ���������� � ���������� `Resources\Utils`.
						��������� `7z.exe` ����� ������� � ����� http://7-zip.org.
						3. ����� ��������� ����� `xmltv.xml.gz` ���������� ���� ���� - 'xmltv' (��� ����������). ����
						���� ����������� ����������, � �� ���� ����������� ������� �� ������� ������������� ������� �
						������� ������������� �������, ������� ���������� � ���� ������ "������ ����".

    Versions.......:	0.0.0.1 (21.06.2018) - ������ ������ ���������.
						0.0.1.4 (05.02.2019) - ��������� ��������� ���������� ��������� ������
						0.2.0.0 (30.04.2019) - ��������� ������������� ��� ������ ������� 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\programTV.exe)
#pragma compile(Icon, ..\resources\icons\TV.ico)
#pragma compile(ProductName, Smart Home Server - TV Program Update)
#pragma compile(FileVersion, 0.2.0.1)
#pragma compile(LegalCopyright, (c) 2018-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <UDFs\ID3_v3.4.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

Global Enum _
 $_TV_CHANNEL_INDEX, _
 $_TV_CHANNEL_NAME, _
 $_TV_CHANNEL_ICON, _
 $_TV_CHANNEL_COUNT

Global Enum _
 $_TV_PROGRAM_NAME, _
 $_TV_PROGRAM_CHANNEL, _
 $_TV_PROGRAM_START, _
 $_TV_PROGRAM_STOP, _
 $_TV_PROGRAM_CATEGORY, _
 $_TV_PROGRAM_COUNT

; ��������� ���������� ����������
		$sAppShortName			= 'TV Program Update'					; ������� �������� ���������

; ������ ����������, ������������ � ����������
Global	$sXMLFileURL			= 'http://programtv.ru/xmltv.xml.gz'	; ������ �� XML-���� � ���������
Global	$sXMLFileName			= ''									; ��� XML-����� �� ��������� �����
Global	$sWebServerDir			= ''									; ������� ���������� web-�������� �������
Global	$sDB_TableTVProgram_New	= "tv_program_new"						; ����� ������� ������ ������������� �������
Global	$sUnZipFileName			= '\resources\utils\7-Zip\7z.exe'		; ���� � ����� ������������ ������
Global	$sChannelLogossDir		= 'images\tv\'							; ������� ����������� ��������� �������
Global	$iChannelLogoWidth		= 120									; ������ ��������� ������� �� �����������
Global	$iChannelLogoHeight		= 90									; ������ ��������� ������� �� ���������
Global	$iChangeCount			= 0										; ���-�� ���������� ������� � ���� ������
Global	$iErrorCount			= 0										; ������� ������
Dim		$aChannels[1][$_TV_CHANNEL_COUNT] = [[0]]						; ������ ������������� �������
Dim		$aProgramme[1][$_TV_PROGRAM_COUNT] = [[0]]						; ������ ������������� ��������
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
   Return _LogWrite("������� '����� ���'. ������ �������� �������� ������������� �������." & @CRLF & _
		   "��������� ��������� ������:" & @CRLF & _
           "programTV.exe [update] {/debug}" & @CRLF & _
		   " update - ���������� �������� ������������� �������" & @CRLF & _
		   " /debug - ����� ������� (��������� ����� � ����������)")
  If StringLower($CmdLine[1]) == "update" Then
   _ReadServerConfig()
   _CreateTVProgramTables()
   _InetReadFileXML()
   _CopyChannelsLogo()
   _SaveToDatabase()
   _CheckErrors()
   Return
  EndIf
 EndIf
 _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'programTV.exe /?'")
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
 $sWebServerDir = _MySQL_ReadConfig('WebServerDir')
 If StringLen($sWebServerDir) == 0 Then
  _LogWrite(" ������ ��������� ���������� �������")
  _LogWrite(" ��������� ������ 'WebServerDir' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "������ ���������� �������")
  _AppExit()
 EndIf
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region MySQL Functions
;-------------------------------------------- ������� ������ � ����� ������ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateTVProgramTables
; Description....:	�������� � ���� ������ ������ ������������� ������� � ������������� �������
; Syntax.........:	_CreateTVProgramTables()
; ===============================================================================================================
Func _CreateTVProgramTables()
 _LogWrite("�������� ������ � ���� ������...")
 If _MySQL_CheckTable($sDB_TableTVChannels) Then
  _LogWrite(" ������� ������� '" & $sDB_TableTVChannels & "'")
 Else
  _MySQL_Query("CREATE TABLE `" & $sDB_TableTVChannels & "` (" & _
   "id INT UNSIGNED NOT NULL AUTO_INCREMENT, " & _ ; id �����
   "channel_id INT UNSIGNED, " & _			; ������ ������
   "name TEXT, " & _						; �������� ������
   "icon TEXT, " & _						; ����������� ��������
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" ������� ������� '" & $sDB_TableTVChannels & "'")
  Else
   _LogWrite(" ������: ���������� ������� ������� '" & $sDB_TableTVChannels & "'")
   _SysyemLogWrite(0, 1, "������ ���� ������")
   _AppExit()
  EndIf
 EndIf
 If _MySQL_CheckTable($sDB_TableTVProgram_New) Then _MySQL_DropTable($sDB_TableTVProgram_New)
 _MySQL_Query("CREATE TABLE `" & $sDB_TableTVProgram_New & "` (" & _
  "id INT UNSIGNED NOT NULL AUTO_INCREMENT, " & _ ; id �����
  "channel_id INT UNSIGNED, " & _			; ������ ������
  "name TEXT, " & _							; �������� ��������
  "start DATETIME, " & _					; ����� ������ ��������
  "stop DATETIME, " & _						; ����� ��������� ��������
  "PRIMARY KEY (`id`));")
 If Not @error Then
  _LogWrite(" ������� ������� '" & $sDB_TableTVProgram_New & "'")
 Else
  _LogWrite(" ������: ���������� ������� ������� '" & $sDB_TableTVProgram_New & "'")
  _SysyemLogWrite(0, 1, "������ ���� ������")
  _AppExit()
 EndIf
 _LogWrite()
EndFunc ;==>_CreateTVProgramTables

; #FUNCTION# ====================================================================================================
; Name...........:	_SaveToDatabase
; Description....:	���������� ������ ������������� ������� � ������������� ������� � ���� ������
; Syntax.........:	_SaveToDatabase()
; ===============================================================================================================
Func _SaveToDatabase()
 Local $i, $Timer = TimerInit()
 _LogWrite(" ���������� � ���� ������...")
 Local $iStartCount = _MySQL_GetCount($sDB_TableTVChannels, 'id')
 For $i = 1 To UBound($aChannels, 1) - 1
  If _MySQL_GetCount($sDB_TableTVChannels, "id", "WHERE channel_id = " & $aChannels[$i][$_TV_CHANNEL_INDEX]) == 0 Then
   _MySQL_Query("INSERT INTO `" & $sDB_TableTVChannels & "` " & _
    "(channel_id, name, icon) VALUES (" & _
       "'" & $aChannels[$i][$_TV_CHANNEL_INDEX] & "', " & _							; channel_id
       "'" & _MySQL_StringCode($aChannels[$i][$_TV_CHANNEL_NAME]) & "', " & _		; name
       "'" & _MySQL_StringCode($aChannels[$i][$_TV_CHANNEL_ICON]) & "');")			; icon
   If @error Then $iErrorCount += 1
  Else
   _MySQL_Query("UPDATE `" & $sDB_TableTVChannels & "` SET " & _
    "name = '" & _MySQL_StringCode($aChannels[$i][$_TV_CHANNEL_NAME]) & "', " & _
    "icon = '" & _MySQL_StringCode($aChannels[$i][$_TV_CHANNEL_ICON]) & "' " & _
	"WHERE channel_id = " & $aChannels[$i][$_TV_CHANNEL_INDEX] & ";")
   If @error Then $iErrorCount += 1
  EndIf
 Next
 Local $iEndCount = _MySQL_GetCount($sDB_TableTVChannels, 'id')
 If $iEndCount > $iStartCount Then _
  _LogWrite(" � ������� '" & $sDB_TableTVChannels & "' ��������� " & $iEndCount - $iStartCount & " �������")

 For $i = 1 To UBound($aProgramme, 1) - 1
  _MySQL_Query("INSERT INTO `" & $sDB_TableTVProgram_New & "` " & _
   "(channel_id, name, start, stop) VALUES (" & _
      "'" & $aProgramme[$i][$_TV_PROGRAM_CHANNEL] & "', " & _						; channel_id
      "'" & _MySQL_StringCode($aProgramme[$i][$_TV_PROGRAM_NAME]) & "', " & _		; name
		    _FixDatetime($aProgramme[$i][$_TV_PROGRAM_START]) & ", " & _			; start
			_FixDatetime($aProgramme[$i][$_TV_PROGRAM_STOP]) & ");")				; stop
  If @error Then
   $iErrorCount += 1
  Else
   $iChangeCount += 1
  EndIf
 Next
 _MySQL_DropTable($sDB_TableTVProgram)
 _MySQL_Query("RENAME TABLE " & $sDB_TableTVProgram_New & " TO " & $sDB_TableTVProgram & ";")
 If @error Then
  _LogWrite(" ������: ���������� ������������� ������� '" & $sDB_TableTVProgram_New & "'")
  _SysyemLogWrite(0, 1, "���������� ������������� �������")
  _AppExit()
 EndIf
 $iEndCount = _MySQL_GetCount($sDB_TableTVProgram, 'id')
 If $iEndCount > 0 Then _LogWrite(" � ������� '" & $sDB_TableTVProgram & "' ������� " & $iEndCount & " �������")
 _LogWrite(" ��������� �������: " & _TimeToString(TimerDiff($Timer)) & @CRLF)
EndFunc ;==>_SaveToDatabase

; #FUNCTION# ====================================================================================================
; Name...........:	_FixDatetime
; Description....:	���������� ���� � ����� ������������
; Syntax.........:	_FixDatetime($sStr)
; Parameter(s)...:	$sStr		- �������� ���� � ����� � ������� ����� 'xmltv'
; Return values..:	���� � ������� ������, ������� � ������ � ���� ������
; ===============================================================================================================
Func _FixDatetime($sStr)
 Return '"' & StringLeft($sStr, 4) & '-' & StringMid($sStr, 5, 2) & '-' & StringMid($sStr, 7, 2) & ' ' & _
  StringMid($sStr, 9, 2) & ':' & StringMid($sStr, 11, 2) & ':' & StringMid($sStr, 13, 2) & '"'
EndFunc ;==>_FixDatetime
#EndRegion MySQL Functions

#Region Internet Data Read Functions
;--------------------------------------- ������ � ���������� XML-����� �� ��������� -----------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_InetReadFileXML
; Description....:	������ �� ��������� XML-����� � ���������� ������������� �������
; Syntax.........:	_InetReadFileXML()
; ===============================================================================================================
Func _InetReadFileXML()
 Local $sUnZipFullPath = $sServerAppDir & $sUnZipFileName
 If Not FileExists($sUnZipFullPath) Then
  _LogWrite(" �� ������ ����������� ����: '" & $sUnZipFullPath & "'")
  _SysyemLogWrite(0, 1, "���������� ����������� ���� '7z.exe'")
  _AppExit()
 EndIf
 _CreateTempDir()
 If $sAppTempDir == '' Then
  _SysyemLogWrite(0, 1, "���������� ������� ������� ���������� ��������� ������")
  _AppExit()
 EndIf
 Local $sXMLFileZip = $sAppTempDir & "\xmltv.gz"
 InetGet($sXMLFileURL, $sXMLFileZip, 1)
 If FileExists($sXMLFileZip) Then
  _LogWrite(" ���� � ���������� ������������� ������� ��������")
 Else
  _LogWrite(" ������: ���������� ��������� �� ��������� XML-����")
  _SysyemLogWrite(0, 1, "������ �������� XML-�����")
 EndIf
 ShellExecuteWait($sUnZipFullPath, 'e ' & $sXMLFileZip, $sAppTempDir)
 $sXMLFileName = $sAppTempDir & "\xmltv"
 If FileExists($sXMLFileName) Then
  _LogWrite(" ���� � ���������� ������������� ������� ����������")
 Else
  _LogWrite(" ������: ���������� ����������� ����� � XML-������")
  _SysyemLogWrite(0, 1, "������ ���������� XML-�����")
 EndIf
 If Not _LoadDataFromFileXML($sXMLFileName) Then
  _LogWrite(" ������: �������� ������ XML-�����!")
  _SysyemLogWrite(0, 1, "������ ������ XML-�����")
 EndIf
;_ArrayDisplay($aChannels)
;_ArrayDisplay($aProgramme)
EndFunc ;==>_InetReadFileXML

; #FUNCTION# ====================================================================================================
; Name...........:	_LoadDataFromFileXML
; Description....:	������ � ������ ������ �� XML-�����
; Syntax.........:	_LoadDataFromFileXML($sText)
; Remarks .......:	��������� ������ ������� - ���������� �������� $aChannels � $aProgramme
; ===============================================================================================================
Func _LoadDataFromFileXML($sFileName)
 Local $s, $pos, $sLine, $Timer = TimerInit()
 _LogWrite(" ������ �����: 'xmltv'...")
 Local $fNodeChannel = False
 Local $fNodeProgramme = False
 $hFile = FileOpen($sFileName, 0)
 While True
  $sLine = FileReadLine($hFile)
  If @error Then ExitLoop
  Local $nChannels = UBound($aChannels)
  Local $nProgramme = UBound($aProgramme)
;If $nProgramme > 100 Then ExitLoop
  If $fNodeProgramme Then
   $pos = StringInStr($sLine, '</programme>')
   If $pos > 0 Then
    $fNodeProgramme = False
    ContinueLoop
   EndIf
   $pos = StringInStr($sLine, '<title>')
   If $pos > 0 Then
    $s = StringTrimLeft($sLine, $pos + 6)
    $pos = StringInStr($s, '</title>')
    If $pos == 0 Then ContinueLoop
    $s = StringLeft($s, $pos - 1)
    $aProgramme[$nProgramme - 1][$_TV_PROGRAM_NAME] = $s
   EndIf
   ContinueLoop
  EndIf
  If $fNodeChannel Then
   $pos = StringInStr($sLine, '</channel>')
   If $pos > 0 Then
    $fNodeChannel = False
    ContinueLoop
   EndIf
   $pos = StringInStr($sLine, '<display-name>')
   If $pos > 0 Then
    $s = StringTrimLeft($sLine, $pos + 13)
    $pos = StringInStr($s, '</display-name>')
    If $pos == 0 Then ContinueLoop
    $s = StringLeft($s, $pos - 1)
    $aChannels[$nChannels - 1][$_TV_CHANNEL_NAME] = $s
    ContinueLoop
   EndIf
   $pos = StringInStr($sLine, '<icon src="')
   If $pos > 0 Then
    $s = StringTrimLeft($sLine, $pos + 10)
    $pos = StringInStr($s, '" />')
    If $pos == 0 Then ContinueLoop
    $s = StringLeft($s, $pos - 1)
    $aChannels[$nChannels - 1][$_TV_CHANNEL_ICON] = $s
   EndIf
   ContinueLoop
  EndIf
  $pos = StringInStr($sLine, '<programme ')
  If $pos > 0 Then
   ReDim $aProgramme[$nProgramme + 1][$_TV_PROGRAM_COUNT]
   $aProgramme[0][0] += 1
   $aProgramme[$nProgramme][$_TV_PROGRAM_CHANNEL]	= _StringGetKey($sLine, 'channel')
   $aProgramme[$nProgramme][$_TV_PROGRAM_START]		= _StringGetKey($sLine, 'start')
   $aProgramme[$nProgramme][$_TV_PROGRAM_STOP]		= _StringGetKey($sLine, 'stop')
   $fNodeProgramme = True
   ContinueLoop
  EndIf
  $pos = StringInStr($sLine, '<channel id="')
  If $pos > 0 Then
   $s = StringTrimLeft($sLine, $pos + 12)
   $pos = StringInStr($s, '">')
   If $pos == 0 Then ContinueLoop
   $s = StringLeft($s, $pos - 1)
   ReDim $aChannels[$nChannels + 1][$_TV_CHANNEL_COUNT]
   $aChannels[0][0] += 1
   $aChannels[$nChannels][$_TV_CHANNEL_INDEX] = Number($s)
   $fNodeChannel = True
  EndIf
 WEnd
 FileClose($hFile)
 _LogWrite(" ��������� �������: " & _TimeToString(TimerDiff($Timer)) & @CRLF)
 Return True ; _LoadDataFromFileXML
EndFunc ;==>_LoadDataFromFileXML

; #FUNCTION# ====================================================================================================
; Name...........:	_CopyChannelsLogo
; Description....:	�������� ��������� ������������� �������
; Syntax.........:	_CopyChannelsLogo()
; ===============================================================================================================
Func _CopyChannelsLogo()
 Local $i, $Timer = TimerInit()
 _LogWrite(" �������� ��������� ������������� �������...")
 For $i = 1 To UBound($aChannels, 1) - 1
  If $aChannels[$i][$_TV_CHANNEL_ICON] == 'http:' Then ContinueLoop
  If _MySQL_GetCount($sDB_TableTVChannels, "id", "WHERE channel_id = " & $aChannels[$i][$_TV_CHANNEL_INDEX] & _
	 " AND icon = '" & $aChannels[$i][$_TV_CHANNEL_ICON] & "'") > 0 Then ContinueLoop
  _LogWrite("  �������� �������� ������: '" & $aChannels[$i][$_TV_CHANNEL_NAME] & "'")
  Local $sFileName = $sWebServerDir & $sChannelLogossDir & $aChannels[$i][$_TV_CHANNEL_INDEX] & ".png"
  InetGet($aChannels[$i][$_TV_CHANNEL_ICON], $sFileName, 1)
  If Not FileExists($sFileName) Then
   _LogWrite("  > ������: ���������� ��������� ����: '" & $aChannels[$i][$_TV_CHANNEL_ICON] & "'")
   $iErrorCount += 1
   ContinueLoop
  EndIf
 Next
 _LogWrite(" ��������� �������: " & _TimeToString(TimerDiff($Timer)) & @CRLF)
EndFunc ;==>_LoadDataFromFileXML
#EndRegion Internet Data Read Functions

#Region Check Errors Functions
;----------------------------------------------- ������� ��������������� ----------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CheckErrors
; Description....:	�������� �� ������ �� ����������� ������ ���������
; Syntax.........:	_CheckErrors()
; ===============================================================================================================
Func _CheckErrors()
 Local $i
 _LogWrite("�������� ����������� ������ ���������...")
 For $i = 1 To UBound($aChannels, 1) - 1
  If $aChannels[$i][$_TV_CHANNEL_ICON] == 'http:' Then ContinueLoop
  Local $sFileName = $sWebServerDir & $sChannelLogossDir & $aChannels[$i][$_TV_CHANNEL_INDEX] & ".png"
  If Not FileExists($sFileName) Then
   _LogWrite(" ������: �������� ������� ������: '" & $aChannels[$i][$_TV_CHANNEL_NAME] & "'")
   _MySQL_Query("UPDATE `" & $sDB_TableTVChannels & "` SET " & _
    "icon = '' WHERE channel_id = " & $aChannels[$i][$_TV_CHANNEL_INDEX] & ";")
   $iErrorCount += 1
   ContinueLoop
  EndIf
 Next
 If $iErrorCount == 0 Then
  _LogWrite(" �� ����� ���������� ��������� ������ �� ��������")
 Else
  _LogWrite(" ����� ������ �� ����� ���������� ���������: " & $iErrorCount)
 EndIf
 Local $sText = ""
 If $iChangeCount > 0 Then $sText &= "��������� �������: " & $iChangeCount
 If $iErrorCount > 0  Then
  If StringLen($sText) > 0 Then $sText &= ". "
  $sText &= "������: " & $iErrorCount
 EndIf
 _SysyemLogWrite($iChangeCount, $iErrorCount, $sText)
 _LogWrite()
EndFunc ;==>_CheckErrors
#EndRegion Check Errors Functions
