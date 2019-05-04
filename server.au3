#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.2
	Date...........:	02.05.2019
	Title..........:	SmartHome - Server
	Filename.......:	Server.au3
	Description....:	������� "����� ���". ������ ���������� ��������
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						off - ���������� �������
						reboot - ������������ �������
						mute - ���������� �����
						unmute - ��������� �����
						play {filename} - ������������ wav-�����
						sysinfo - ���������� ���������� �� ���������� �������� �������
						/debug - ����� ������� (��������� ����� � ����������)

    Versions.......:    0.0.0.1 (21.09.2017) - ������ ������ ���������
	                    0.0.0.4 (20.10.2017) - ��������� ������� "alloff"
	                    0.0.1.0 (17.06.2018) - ��������� ���������� ������
	                    0.0.2.0 (07.02.2019) - ��������� ���������� ���������� �� ���������� ��������
						0.2.0.0 (26.04.2019) - ��������� ������������� ��� ������ ������� 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\server.exe)
#pragma compile(Icon, ..\resources\icons\server.ico)
#pragma compile(ProductName, Smart Home Server - Server Driver)
#pragma compile(FileVersion, 0.2.0.2)
#pragma compile(LegalCopyright, (c)2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <UDFs\_AudioEndpointVolume.au3>
#include <UDFs\_SMART.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; ��������� ���������� ����������
		$sAppShortName			= 'Server Control'						; ������� �������� ���������

; ������ ����������, ������������ � ����������
Global	$sSoundFilesSubDir		= '\resources\sound\'					; ���������� ���������� �������� ������
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
    Return _LogWrite("������� '����� ���'. ������ ���������� ��������." & @CRLF & _
		    "��������� ��������� ������:" & @CRLF & _
            "server.exe [off|reboot|mute|unmute|play|sysinfo] {filename} {/debug}" & @CRLF & _
		    " off - ���������� �������" & @CRLF & _
		    " reboot - ������������ �������" & @CRLF & _
		    " mute - ���������� �����" & @CRLF & _
		    " unmute - ��������� �����" & @CRLF & _
		    " play {filename} - ������������ wav-�����" & @CRLF & _
		    " sysinfo - ���������� ���������� �� ���������� �������� �������" & @CRLF & _
		    " /debug - ����� ������� (��������� ����� � ����������)")
   Case "off"
    _PowerOff()
    Return
   Case "reboot"
    _Reboot()
    Return
   Case "mute"
    _Mute()
    Return
   Case "unmute"
    _Unmute()
    Return
   Case "play"
    _Play($sParameter)
    Return
   Case "sysinfo"
    _SysInfo()
    Return
  EndSwitch
 EndIf
 _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'server.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region Server Control Functions
;------------------------------------------------ ������� ���������� �������� -----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Reboot
; Description....:	������������ �������
; Syntax.........:	_Reboot()
; ===============================================================================================================
Func _Reboot()
 Shutdown(BitOR($SD_REBOOT, $SD_FORCE, $SD_FORCEHUNG))
EndFunc ;==>_Reboot

; #FUNCTION# ====================================================================================================
; Name...........:	_PowerOff
; Description....:	���������� �������
; Syntax.........:	_PowerOff()
; ===============================================================================================================
Func _PowerOff()
 Shutdown(BitOR($SD_SHUTDOWN, $SD_FORCE, $SD_FORCEHUNG))
EndFunc ;==>_PowerOff
#EndRegion Server Control Functions

#Region Sound Control Functions
;-------------------------------------------- ������� ���������� ������ �� ������� ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Mute
; Description....:	���������� �����
; Syntax.........:	_Mute()
; ===============================================================================================================
Func _Mute()
 _SetMute(1)
 If _GetMute() == 1 Then
  _LogWrite(" ���� ��������")
  _MySQL_Query("UPDATE `" & $sDB_TableDevices & "` SET state = 1, updated = NOW() WHERE name = 'Server';")
 Else
  _LogWrite(" ������: ���������� ��������� ���� �� �������")
  _SysyemLogWrite(0, 1, "���������� ��������� ���� �� �������")
 EndIf
EndFunc ;==>_Mute

; #FUNCTION# ====================================================================================================
; Name...........:	_Unmute
; Description....:	��������� �����
; Syntax.........:	_Unmute()
; ===============================================================================================================
Func _Unmute()
 _SetMute(0)
 Sleep(500)
 If _GetMute() == 0 Then
  _LogWrite(" ���� �������")
  _MySQL_Query("UPDATE `" & $sDB_TableDevices & "` SET state = 3, updated = NOW() WHERE name = 'Server';")
 Else
  _LogWrite(" ������: ���������� �������� ���� �� �������")
  _SysyemLogWrite(0, 1, "���������� �������� ���� �� �������")
 EndIf
EndFunc ;==>_Unmute

; #FUNCTION# ====================================================================================================
; Name...........:	_Play
; Description....:	������������ �����
; Syntax.........:	_Play()
; ===============================================================================================================
Func _Play($sFileName)
 Local $sFullFileName = $sServerAppDir & $sSoundFilesSubDir & $sFileName
 If Not FileExists($sFullFileName) Then
  _LogWrite(" ������: �� ������ ���� '" & $sFullFileName & "'")
  _SysyemLogWrite(0, 1, "�� ������ ���� alarm.wav")
  _AppExit()
 EndIf
 _LogWrite(" ������������ �����: '" & $sFullFileName & "'")
 SoundPlay($sFullFileName, 1)
EndFunc ;==>_Play
#EndRegion Sound Control Functions

#Region System Information Functions
;---------------------------------------- ������� ��������� ���������� � ������� --------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_SysInfo
; Description....:	���� � ������ � ���� ������ ���������� �� ���������� �������� �������
; Syntax.........:	_SysInfo()
; ===============================================================================================================
Func _SysInfo()
 _CreateTableSysInfo()
 Local $i, $ObjItem, $ObjSubItem, $ObjWMIService = ObjGet("winmgmts:\\" & @ComputerName & "\root\CIMV2")
 Local $sSectionName = "Processor"
 Local $ColItems = $objWMIService.ExecQuery("SELECT * FROM Win32_Processor", "WQL", 0x30)
 $i = 1
 If IsObj($ColItems) Then
  For $ObjItem In $ColItems
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Name,						$sSectionName& ".Name")
   _SaveSysInfoData($ObjItem.NumberOfCores,				$sSectionName& ".NumberOfCores")
   _SaveSysInfoData($ObjItem.MaxClockSpeed,				$sSectionName& ".MaxClockSpeed")
   _SaveSysInfoData($ObjItem.AddressWidth,				$sSectionName& ".AddressWidth")
   _SaveSysInfoData($ObjItem.L2CacheSize,				$sSectionName& ".L2CacheSize")
   _SaveSysInfoData($ObjItem.L3CacheSize,	 			$sSectionName& ".L3CacheSize")
   _SaveSysInfoData($ObjItem.LoadPercentage,			$sSectionName& ".LoadPercentage")
   $i += 1
  Next
 EndIf
 $sSectionName = "BaseBoard"
 $ColItems = $objWMIService.ExecQuery("SELECT * FROM Win32_BaseBoard", "WQL", 0x30)
 $i = 1
 If IsObj($ColItems) Then
  For $ObjItem In $ColItems
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Manufacturer,					$sSectionName & ".Manufacturer")
   _SaveSysInfoData($ObjItem.Product,						$sSectionName & ".Product")
   $i += 1
  Next
 EndIf
 $sSectionName = "DiskDrive"
 Local $aDisks = _SMART_LoadDisksList()
 For $i = 0 To UBound($aDisks, 1) - 1
  If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
  _SaveSysInfoData($aDisks[$i][$_DISK_ATTR_MODEL],					$sSectionName & ".Model", $i)
  _SaveSysInfoData($aDisks[$i][$_DISK_ATTR_SERIAL],					$sSectionName & ".SerialNumber", $i)
  _SaveSysInfoData(Round($aDisks[$i][$_DISK_ATTR_SIZE] / 1048576, 2), $sSectionName & ".Size", $i)
  _SaveSysInfoData($aDisks[$i][$_DISK_ATTR_LOGICALS],				$sSectionName & ".LogicalDisks", $i)
 Next
 $sSectionName = "LogicalDisk"
 $ColItems = $objWMIService.ExecQuery("SELECT * FROM Win32_LogicalDisk", "WQL", 0x30)
 $i = 1
 If IsObj($ColItems) Then
  For $ObjItem In $ColItems
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Name,									$sSectionName & ".Name", $i)
   _SaveSysInfoData(Round($ObjItem.Size / 1073741824, 2),			$sSectionName & ".Size", $i)
   _SaveSysInfoData(Round($ObjItem.FreeSpace / 1073741824, 2),		$sSectionName & ".FreeSpace", $i)
   _SaveSysInfoData($ObjItem.FileSystem,							$sSectionName & ".FileSystem", $i)
   $i += 1
  Next
 EndIf
 $sSectionName = "NetworkAdapter"
 Local $Adapters = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter", "WQL", 0x30)
 Local $Config = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration", "WQL", 0x30)
 $i = 1
 If IsObj($Adapters) And IsObj($Config) Then
  For $ObjItem In $Config
   If Not $ObjItem.IPEnabled Then ContinueLoop
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Description, $sSectionName & ".Name", $i)
   _SaveSysInfoData(_ObjArrayToString($ObjItem.IPAddress), $sSectionName & ".IPAddress", $i)
   _SaveSysInfoData($ObjItem.MACAddress, $sSectionName & ".MACAddress", $i)
   For $ObjSubItem In $Adapters
    If $ObjSubItem.Index <> $ObjItem.Index Then ContinueLoop
     _SaveSysInfoData($ObjSubItem.Speed, $sSectionName & ".Speed", $i)
    ExitLoop
   Next
   $i += 1
  Next
 EndIf
 $sSectionName = "OperatingSystem"
 $ColItems = $objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL", 0x30)
 $i = 1
 If IsObj($ColItems) Then
  For $ObjItem In $ColItems
   If $DEBUG Then _LogWrite(@CRLF & " " & $sSectionName & " #" & $i)
   _SaveSysInfoData($ObjItem.Caption, $sSectionName & ".Name")
   _SaveSysInfoData($ObjItem.Version, $sSectionName & ".Version")
   _SaveSysInfoData(Round($ObjItem.TotalVisibleMemorySize / 1048576, 2), $sSectionName & ".TotalVisibleMemorySize")
   _SaveSysInfoData(Round($ObjItem.TotalVirtualMemorySize / 1048576, 2), $sSectionName & ".TotalVirtualMemorySize")
   _SaveSysInfoData($ObjItem.InstallDate, $sSectionName & ".InstallDate")
   _SaveSysInfoData($ObjItem.LastBootUpTime, $sSectionName & ".LastBootUpTime")
   $i += 1
  Next
 EndIf
 Local $iCount = _MySQL_GetCount($sDB_TableSysInfo, "name")
 If $iCount > 0 Then
  _LogWrite(" � ������� '" & $sDB_TableSysInfo & "' ��������� �������: " & $iCount)
 _SysyemLogWrite($iCount, 0, "System Information. ��������� �������: " & $iCount)
 Else
  _SysyemLogWrite($iCount, 1, "�� ���������� �������� ���������� � �������")
 EndIf
EndFunc ;==>_SysInfo
#EndRegion System Information Functions

#Region MySQL Functions
;-------------------------------------------- ������� ������ � ����� ������ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateTableSysInfo
; Description....:	�������� � ���� ������ ������ ������� � ����������� � ���������� �������
; Syntax.........:	_CreateTableSysInfo()
; ===============================================================================================================
Func _CreateTableSysInfo()
 _MySQL_DropTable($sDB_TableSysInfo)
 _MySQL_Query("CREATE TABLE `" & $sDB_TableSysInfo & "` (" & _
  "name TEXT, " & _					; ������������ ���������
  "device TEXT, " & _				; ID ���������� � �������
  "value TEXT, " & _				; �������� ���������
  "time TIMESTAMP);")				; ����� ������� ��������� ���������� � �������
 If Not @error Then
  _LogWrite(" ������� (���� ������� ������) ������� '" & $sDB_TableSysInfo & "'")
 Else
  _LogWrite(" ������: ���������� ������� ������� '" & $sDB_TableSysInfo & "'")
  _SysyemLogWrite(0, 1, "������ ���� ������")
  _AppExit()
 EndIf
EndFunc ;==>_CreateTableSysInfo

; #FUNCTION# ====================================================================================================
; Name...........:	_SaveSysInfoData
; Description....:	������ ������ � ������� � ����������� � ���������� �������
; Syntax.........:	_SaveSysInfoData($Value, $sName[, $id])
; Parameters.....:	$Value	- �������� ���������
;					$sName	- ������������ ���������
;					$id		- ID ���������� � �������
; ===============================================================================================================
Func _SaveSysInfoData($Value, $sName, $id = 1)
 If $DEBUG Then _LogWrite(" > " & $sName & " = " & $Value)
 _MySQL_Query("INSERT INTO `" & $sDB_TableSysInfo & "` " & _
  "(name, device, value) VALUES (" & _
  "'" & _MySQL_StringCode($sName) & "'," & _									; name
  "'" & $id & "'," & _															; device
  "'" & _MySQL_StringCode($Value) &"');")										; value
EndFunc ;==>_SaveSysInfoData

; #FUNCTION# ====================================================================================================
; Name...........:	_ObjArrayToString
; Description....:	������������� �������-������� � ���� ������
; Syntax.........:	_ObjArrayToString($aStrings)
; Parameters.....:	$aStrings	- ������-������
; Return value(s):	������, ���������� ��� �������� �������, ������������� ����� �����������
; ===============================================================================================================
Func _ObjArrayToString($aStrings)
 Local $i, $sString = ""
 For $i = 0 To UBound($aStrings) - 1
  $sString &= " | " & $aStrings[$i]
 Next
 Return StringTrimLeft($sString, 3)
EndFunc ;==>_ObjArrayToString
#EndRegion MySQL Functions
