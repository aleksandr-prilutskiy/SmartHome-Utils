#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	SmartHome - Database Service Tool
	Filename.......:	database.au3
	Description....:	������� "����� ���". ������� ������������ ���� ������
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						clean - ������� ���������� ������� � ���� ������
						/debug - ����� ������� (��������� ����� � ����������)

    Versions.......:    0.0.0.1 (xx.xx.xxxx) - ������ ������
						0.0.2.0 (07.02.2019) - ��������� ��������� ���������� ��������� ������
						0.2.0.0 (26.04.2019) - ��������� ������������� ��� ������ ������� 2.0.0

$sDB_TableConfig		= "config"				- ������� �� �����
$sDB_TableUser			= "user"				- ������� �� �����
$sDB_TableEvents		= "events"				- ������� ������, ���������� ����� ������������� �����
$sDB_TableShedule		= "shedule"				- ������� �� �����
$sDB_TableScripts		= "scripts"				- ������� �� �����
$sDB_TableStates		= "variables"			- ������� �� �����
$sDB_TableLog			= "system_log"			- ������� ������, ���������� ����� ������������� �����
$sDB_TableDevices		= "devices"				- ������� �� �����
$sDB_TableSensors		= "sensors"				- ������� �� �����
$sDB_TableSensorsData	= "sensors_data"		- ������� ������, ���������� ����� ������������� �����
$sDB_TableUserWidgets	= "user_widgets"		- ������� ������ ��������� �������������
$sDB_TableMediaFavorite	= "media_favorite"		- ������� ������ ��������� ������������� � ��������� ��������
$sDB_TableMediaBrowsed	= "media_browsed"		- ������� ������ ��������� ������������� � ��������� ��������
$sDB_TableMusicFiles	= "music_files"			- �������������� �������� Music.exe
$sDB_TableMusicAlbums	= "music_albums"		- ��������� �����������  �������� Music.exe
$sDB_TableMusicArtists	= "music_artists"		- ��������� �����������  �������� Music.exe
$sDB_TableMoviesFiles	= "movies_files"		- �������������� �������� Movies.exe
$sDB_TableMoviesInfo	= "movies_info"			- �������������� �������� Movies.exe
$sDB_TableMoviesMeta	= "movies_metadata"		- �������������� �������� Movies.exe
$sDB_TableSeriesFiles	= "series_files"		- �������������� �������� Series.exe
$sDB_TableSeriesSeasons	= "series_seasons"		- �������������� �������� Series.exe
$sDB_TableSeries		= "series_names"		- �������������� �������� Series.exe
$sDB_TablePhotoFiles	= "photo_files"			- �������������� �������� Photo.exe
$sDB_TablePhotoAlbums	= "photo_albums"		- �������������� �������� Photo.exe
$sDB_TableTVChannels	= "tv_channel"			- ������� �� �����
$sDB_TableTVChannelMap	= "tv_channel_map"		- ������� ������ ��������� ���������
$sDB_TableTVProgram		= "tv_program"			- ��������� ����������� �������� TV_Program.exe
$sDB_TableSysInfo		= "server_sysinfo"		- ��������� ����������� �������� SysInfo.exe
$sDB_TableSysSMART		= "server_smart_hdd"	- ������� ������, ���������� ����� ������������� �����
$sDB_TableWeather		= "weather_forecast"	- ��������� ����������� �������� Weather.exe
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\database.exe)
#pragma compile(Icon, ..\resources\icons\database.ico)
#pragma compile(ProductName, Smart Home Server - Clean Database)
#pragma compile(FileVersion, 0.2.0.1)
#pragma compile(LegalCopyright, (c)2016-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; ��������� ���������� ����������
		$sAppShortName			= 'database'							; ������� �������� ���������
; ������ ����������, ������������ � ����������
Global  $iStorageTime			= 7										; ����� �������� ������� � ��������
Global	$iRecordsCount			= 0										; ������� ��������� �������
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
  Local $sParameter = $CmdLine[0] > 1 ? $CmdLine[2] : ''
  Switch ($CmdLine[0] > 0 ? $CmdLine[1] : "")
   Case "/?"
    Return _LogWrite("������� '����� ���'. ������� ������������ ���� ������." & @CRLF & _
		    "��������� ��������� ������:" & @CRLF & _
            "database.exe [clean] {/debug}" & @CRLF & _
		    " clean - ������� ���������� ������� � ���� ������" & @CRLF & _
		    " /debug - ����� ������� (��������� ����� � ����������)")
   Case "clean"
    _CleanDatabase()
    Return
  EndSwitch
 EndIf
 _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'database.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region MySQL Functions
;-------------------------------------------- ������� ������ � ����� ������ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CleanDatabase
; Description....:	������� ���������� ������� � ���� ������
; Syntax.........:	_CleanDatabase()
; ===============================================================================================================
Func _CleanDatabase()
 Local $iCountStart, $iCountEnd
 $iCountStart = _MySQL_GetCount($sDB_TableEvents)
 If $iCountStart > 0 Then ; ������� ����� ������� � ������� 'events'
  _MySQL_Query("DELETE FROM `" & $sDB_TableEvents & "` " & _
   "WHERE updated < TIMESTAMP(DATE_SUB(NOW(), INTERVAL " & $iStorageTime & " DAY));")
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableEvents)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" �� ������� '" & $sDB_TableEvents & "' ������� " & $iCountStart - $iCountEnd & " �������")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableLog)
 If $iCountStart > 0 Then ; ������� ����� ������� � ������� 'server_log'
  _MySQL_Query("DELETE FROM `" & $sDB_TableLog & "` " & _
   "WHERE time < TIMESTAMP(DATE_SUB(NOW(), INTERVAL " & $iStorageTime & " DAY));")
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableLog)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" �� ������� '" & $sDB_TableLog & "' ������� " & $iCountStart - $iCountEnd & " �������")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableSensorsData)
 If $iCountStart > 0 Then ; ������� ����� ������� � ������� 'sensors_data'
  _MySQL_Query("DELETE FROM `" & $sDB_TableSensorsData & "` " & _
   "WHERE updated < TIMESTAMP(DATE_SUB(NOW(), INTERVAL " & $iStorageTime & " DAY));")
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableSensorsData)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" �� ������� '" & $sDB_TableSensorsData & "' ������� " & $iCountStart - $iCountEnd & " �������")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableUserWidgets)
 If $iCountStart > 0 Then ; ������� ������� ��������� ������������� � ������� 'user_widgets'
  Local $Query = _MySQL_Query("SELECT id, user_id FROM `" & $sDB_TableUserWidgets & "`;")
  If IsObj($Query) Then
   While Not $Query.EOF
    Local $iID		= $Query.Fields(0).value
    Local $iUser	= $Query.Fields(1).value
    $Query.MoveNext
	If _MySQL_GetCount($sDB_TableUser, 'id', "WHERE id = '" & $iUser & "'") == 0 Then _
    _MySQL_Query("DELETE FROM `" & $sDB_TableUserWidgets & "` WHERE id =  " & $iID & ";")
   WEnd
  EndIf
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableUserWidgets)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" �� ������� '" & $sDB_TableUserWidgets & "' ������� " & $iCountStart - $iCountEnd & " �������")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableMediaFavorite)
 If $iCountStart > 0 Then ; ������� ������� ��������� ������������� � ������� 'media_favorite'
  Local $Query = _MySQL_Query("SELECT id, user_id, dlna_id FROM `" & $sDB_TableMediaFavorite & "`;")
  If IsObj($Query) Then
   While Not $Query.EOF
    Local $iID		= $Query.Fields(0).value
    Local $iUser	= $Query.Fields(1).value
	Local $iDLNA	= $Query.Fields(2).value
    $Query.MoveNext
	If _MySQL_GetCount($sDB_TableUser, 'id', "WHERE id = '" & $iUser & "'") == 0 Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableMediaFavorite & "` WHERE id =  " & $iID & ";")
	If (_MySQL_GetCount($sDB_TableMusicFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) And  _
	   (_MySQL_GetCount($sDB_TableMoviesFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) And _
	   (_MySQL_GetCount($sDB_TableSeriesFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableMediaFavorite & "` WHERE id =  " & $iID & ";")
   WEnd
  EndIf
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableMediaFavorite)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" �� ������� '" & $sDB_TableMediaFavorite & "' ������� " & $iCountStart - $iCountEnd & " �������")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableMediaBrowsed)
 If $iCountStart > 0 Then ; ������� ������� ��������� ������������� � ������� 'media_browsed'
  Local $Query = _MySQL_Query("SELECT id, user_id, dlna_id FROM `" & $sDB_TableMediaBrowsed & "`;")
  If IsObj($Query) Then
   While Not $Query.EOF
    Local $iID		= $Query.Fields(0).value
    Local $iUser	= $Query.Fields(1).value
	Local $iDLNA	= $Query.Fields(2).value
    $Query.MoveNext
	If _MySQL_GetCount($sDB_TableUser, 'id', "WHERE id = '" & $iUser & "'") == 0 Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableMediaBrowsed & "` WHERE id =  " & $iID & ";")
	If (_MySQL_GetCount($sDB_TableMusicFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) And  _
	   (_MySQL_GetCount($sDB_TableMoviesFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) And _
	   (_MySQL_GetCount($sDB_TableSeriesFiles, 'id', "WHERE dlna_id = '" & $iDLNA & "'") == 0) Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableMediaBrowsed & "` WHERE id =  " & $iID & ";")
   WEnd
  EndIf
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableMediaBrowsed)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" �� ������� '" & $sDB_TableMediaBrowsed & "' ������� " & $iCountStart - $iCountEnd & " �������")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableTVChannelMap)
 If $iCountStart > 0 Then ; ������� ������� ��������� ������������� � ������� 'tv_channel_map'
  Local $Query = _MySQL_Query("SELECT id, device FROM `" & $sDB_TableTVChannelMap & "`;")
  If IsObj($Query) Then
   While Not $Query.EOF
    Local $iID		= $Query.Fields(0).value
    Local $sDevice	= $Query.Fields(1).value
    $Query.MoveNext
	If _MySQL_GetCount($sDB_TableDevices, 'id', "WHERE name = '" & $sDevice & "'") == 0 Then _
     _MySQL_Query("DELETE FROM `" & $sDB_TableTVChannelMap & "` WHERE id =  " & $iID & ";")
   WEnd
  EndIf
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableTVChannelMap)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" �� ������� '" & $sDB_TableTVChannelMap & "' ������� " & $iCountStart - $iCountEnd & " �������")
 EndIf
 $iCountStart = _MySQL_GetCount($sDB_TableSysSMART)
 If $iCountStart > 0 Then ; ������� ����� ������� � ������� 'server_smart_hdd'
  _MySQL_Query("DELETE FROM `" & $sDB_TableSysSMART & "` " & _
   "WHERE time < TIMESTAMP(DATE_SUB(NOW(), INTERVAL " & $iStorageTime & " DAY));")
  If @error Then $iErrorCount += 1
  $iCountEnd = _MySQL_GetCount($sDB_TableSysSMART)
  $iRecordsCount += $iCountStart - $iCountEnd
  If $iCountStart > $iCountEnd Then _
   _LogWrite(" �� ������� '" & $sDB_TableSysSMART & "' ������� " & $iCountStart - $iCountEnd & " �������")
 EndIf
 If $iErrorCount == 0 Then
  _LogWrite(" �� ����� ���������� ��������� ������ �� ��������")
 Else
  _LogWrite(" ����� ������ �� ����� ���������� ���������: " & $iErrorCount)
 EndIf
 Local $sText = "����� ������� �������: " & $iRecordsCount
 If $iErrorCount > 0  Then $sText &= ". ������: " & $iErrorCount
 _SysyemLogWrite($iRecordsCount, $iErrorCount, $sText)
 _LogWrite()
EndFunc ;==>_CleanDatabase
#EndRegion MySQL Functions
