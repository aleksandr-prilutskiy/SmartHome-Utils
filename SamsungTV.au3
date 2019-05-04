#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.1.0
	Date...........:	03.05.2019
	Title..........:	SmartHome - Samsung TV
	Filename.......:	SamsungTV.au3
	Description....:	������� "����� ���". ������� ���������� ������������ Samsung
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						off {devicename} - ���������� ����������
						play {devicename } {url} - ��������� �� ���������� ������������ (����� ��� ������)
						channel_up {devicename} - ������������ �� ��������� �����
						channel_down {devicename} - ������������ �� ���������� �����
						channel	{devicename} {N} - ������������ �� �������� �����
						volume_up {devicename} - ���������� ���������
						volume_down {devicename} - ���������� ���������
						mute {devicename} - ���������� / ��������� �����
						pause {devicename} - ��������� ���������������
						return {devicename} - ������ �������� �������� (������� � �������� ���������)
						/debug - ����� ������� (��������� ����� � ����������)

						��� ������ ������� � ���� ������, � ������� 'devices' ������ ���� ������, ���� �������
						'name' ������ �������������� ��������� {devicename} � ��������� ������.
						� ���� ������ ������ ���� ��������� ���� 'addr' � 'parameters':
						addr - ip-����� ���������� � ��������� ����;
						parameters - DLNA UUID ���������� (����� ���������� � ��������� �����-�������).

    Versions.......:    0.0.1.5 (11.07.2017) - ���������� ������ ��� �������� ������������� DLNA �� ����������
					    0.0.1.12(03.10.2017) - ��������� ������������ �������, ���������� ���������� � ��
	                    0.0.2.0 (15.06.2018) - �������� ��������� ���� ������
						0.2.0.0 (26.04.2019) - ��������� ������������� ��� ������ ������� 2.0.0
						0.2.1.0 (02.05.2019) - ��������� ���������� ��� "�������� �����-������" ������ 3.xx
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\SamsungTV.exe)
#pragma compile(Icon, ..\resources\icons\Samsung.ico)
#pragma compile(ProductName, Smart Home Server - Samsung TV E7x Series Driver)
#pragma compile(FileVersion, 0.2.1.0)
#pragma compile(LegalCopyright, (c)2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <InetConstants.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; ��������� ���������� ����������
		$sAppShortName			= 'Samsung TV Driver'					; ������� �������� ���������

; ������ ����������, ������������ � ����������
Global  $sServerURL				= ''									; URL ������� Web-���������� DLNA-�������
Global	$sSamTV_AppName 		= "autoit.samsung.remote"				;
Global	$sSamTV_Port			= 55000
Global	$sSamTV_UserIPAddr		= @IPAddress1
Global	$sSamTV_UserMacAddr		= "00-00-00-00-00-00"
Global	$sDeviceName			= ''
Global	$sDeviceUUID			= ''
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
; Modified.......:	04.02.2019
; ===============================================================================================================
Func _Main()
 If $CmdLine[0] > 0 Then
  If $CmdLine[1] == "/?" Then _
   Return _LogWrite("������� '����� ���'. ������� ���������� ������������ Samsung." & @CRLF & _
		   "��������� ��������� ������:" & @CRLF & _
           "SamsungTV.exe [off|play|channel_up|channel_down|volume_up|volume_down|mute|" & _
                          "pause|return|channel] {devicename} {URL} {N} {/debug}" & @CRLF & _
		   " off {devicename} - ���������� ����������" & @CRLF & _
		   " play {devicename} {url} - ��������� �� ���������� ������������ (����� ��� ������)" & @CRLF & _
		   " channel_up {devicename} - ������������ �� ��������� �����" & @CRLF & _
		   " channel_down {devicename} - ������������ �� ���������� �����" & @CRLF & _
		   " channel {devicename} {N} - ������������ �� �������� �����" & @CRLF & _
		   " volume_up {devicename} - ���������� ���������" & @CRLF & _
		   " volume_down {devicename} - ���������� ���������" & @CRLF & _
		   " mute {devicename} - ���������� / ��������� �����" & @CRLF & _
		   " pause {devicename} - ��������� ���������������" & @CRLF & _
		   " return {devicename} - ������ �������� �������� (������� � �������� ���������)" & @CRLF & _
		   " /debug - ����� ������� (��������� ����� � ����������)")
  $sDeviceName = ($CmdLine[0] > 1 ? $CmdLine[2] : "")
  If StringLen($sDeviceName) == 0 Then
   _LogWrite("������: �� ������� ��� ����������")
   _SysyemLogWrite(0, 1, "�� ������� ��� ����������")
   Return
  EndIf
  Local $Addr = '', $Data = ($CmdLine[0] > 2 ? $CmdLine[3] : "")
  Local $Query = _MySQL_Query("SELECT addr, parameters FROM `" & $sDB_TableDevices & "` " & _
   "WHERE name = '" &$sDeviceName & "';")
  If IsObj($Query) Then
   $Addr		= $Query.Fields(0).value
   $sDeviceUUID = $Query.Fields(1).value
  EndIf
  If StringLen($Addr) == 0 Then
   _LogWrite("������: ���������� �������� ����� ���������� '" & $sDeviceName & "'. " & _
             "�������� ������� '" & $sDB_TableDevices & "' � ���� ������.")
   _SysyemLogWrite(0, 1, "���������� �������� ����� ����������")
   _AppExit()
  EndIf
  Switch $CmdLine[1]
   Case "off"
    Return _SamsungTV_PowerOff($Addr)
   Case "play"
    Return _SamsungTV_Play($Addr, $Data)
   Case "channel_up"
    Return _SamsungTV_SendCommand($Addr, "KEY_CHUP")
   Case "channel_down"
    Return _SamsungTV_SendCommand($Addr, "KEY_CHDOWN")
   Case "channel"
    Return _SamsungTV_SetChannel($Addr, $Data)
   Case "volume_up"
    Return _SamsungTV_SendCommand($Addr, "KEY_VOLUP")
   Case "volume_down"
    Return _SamsungTV_SendCommand($Addr, "KEY_VOLDOWN")
   Case "mute"
    Return _SamsungTV_SendCommand($Addr, "KEY_MUTE")
   Case "pause"
    Return _SamsungTV_SendCommand($Addr, "KEY_PAUSE")
   Case "return"
    Return _SamsungTV_SendCommand($Addr, "KEY_RETURN")
  EndSwitch
 EndIf
 _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'SamsungTV.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region Read Config
;-------------------------------------------- ������� �������� �������� ���������� ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ReadServerConfig
; Description....:	������ �������� ������� "����� ���" �� ���� ������
; Syntax.........:	_ReadServerConfig($Addr)
; Parameter(s)...:	$Addr		- ip-����� ���������� � ����
; Return values .:	On Success - True
;					On Failure - False, ���������� @error ��������� ��������� ��������:
; 						1: ������ ��������� ���������� ������� �� ���� ������
;						2: ������ ��������� ���������� DLNA-���������� ����������
; ===============================================================================================================
Func _ReadServerConfig($Addr)
 Local $sServerAddr = _MySQL_ReadConfig('ServerAddr')
 Local $sPortDLNA   = _MySQL_ReadConfig('PortDLNA')
 If (StringLen($sServerAddr) == 0) OR (StringLen($sPortDLNA) == 0) Then
  _LogWrite("������ ��������� ���������� DLNA �������" & @CRLF & _
			"��������� ������ 'ServerAddr' � 'PortDLNA' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "������ ���������� DLNA-�������")
  _AppExit()
 EndIf
 If (StringLen($sDeviceUUID) == 0) Then
  _LogWrite("������: ������ UUID ����������" & @CRLF & _
   " ��������� ��������� ���������� '" & $sDeviceName & "'" & @CRLF & _
   " ������ '�������������� ���������' ������ ��������� UUID ����������.")
  _SysyemLogWrite(0, 1, "������: �� ������ UUID ����������")
  Return False
 EndIf
 $sServerURL = 'http://' & $sServerAddr & (StringLen($sPortDLNA) > 0 ? ':' & $sPortDLNA : '')
 If $DEBUG Then _
  _LogWrite("���� �������� ��������� ��������� ������� '����� ���':" & @CRLF & _
			" ����� ������� DLNA = " & $sServerURL & @CRLF & _
			" UUID ���������� = " & $sDeviceUUID & @CRLF)
 Return True
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region TV Control Commands
;----------------------------------------------- ������� ���������� ����������� ---------------------------------

; #FUNCTION# ======================================================================================================
; Name...........:	_SamsungTV_SendCommand
; Description....:	�������� ������� �� ���������
; Syntax.........:	_SamsungTV_SendCommand($Addr, $sCommand)
; Parameter(s)...:	$Addr		- ip-����� ���������� � ����
;					$sCommand	- �������
; Version .......:	0.0.2
; Modified.......:	04.10.2017
; =================================================================================================================
Func _SamsungTV_SendCommand($Addr, $sCommand)
 TCPStartup()
 Local $iSocket = TCPConnect($Addr, $sSamTV_Port)
 If @error Then
  _LogWrite(" ������: ���������� ���������� ���������� � �����������: " & $Addr)
  Return SetError(1)
 EndIf
 _LogWrite(" �������� ������� '" & $sCommand & "' �� ��������� � �������: " & $Addr)
 Local $Datagram = Chr(0x00) & _SamsungTV_StringAddHeader($sSamTV_AppName) & _
  _SamsungTV_StringAddHeader(Chr(0x64) & Chr(0x00) & _
  _SamsungTV_StringAddHeader(_Base64Encode($sSamTV_UserIPAddr)) & _
  _SamsungTV_StringAddHeader(_Base64Encode($sSamTV_UserMacAddr)) & _
  _SamsungTV_StringAddHeader(_Base64Encode($sSamTV_AppName))) & _
  Chr(0x00) & _SamsungTV_StringAddHeader($sSamTV_AppName) & _
  _SamsungTV_StringAddHeader(Chr(50) & Chr(48) & Chr (48)) & _
  Chr(0x00) & _SamsungTV_StringAddHeader($sSamTV_AppName) & _
  _SamsungTV_StringAddHeader(Chr(0x00) & Chr(0x00) & Chr(0x00) & _
  _SamsungTV_StringAddHeader(_Base64Encode($sCommand)))
 TCPSend($iSocket, StringToBinary($Datagram))
 TCPShutdown()
EndFunc ;==>_SamsungTV_SendCommand

; #FUNCTION# ====================================================================================================
; Name...........:	_SamsungTV_SetChannel
; Description....:	������� ����� �� ��������
; Syntax.........:	_SamsungTV_SetChannel($Addr, $sChannel)
; Parameter(s)...:	$Addr		- ip-����� ���������� � ����
;					$sChannel	- ����� ������
; Remarks .......:	����� ������ ���������� � 3-� ��������� ��������� ������
; ===============================================================================================================
Func _SamsungTV_SetChannel($Addr, $sChannel)
 If $sChannel == "" Then Return
 Local $i
 For $i = 1 To StringLen($sChannel)
  _SamsungTV_SendCommand($Addr, "KEY_" & StringMid($sChannel, $i, 1))
  Sleep(250)
 Next
 _SamsungTV_SendCommand($Addr, "KEY_ENTER")
EndFunc ;==>_SamsungTV_SetChannel

; #FUNCTION# ====================================================================================================
; Name...........:	_SamsungTV_PowerOff
; Description....:	���������� ����������
; Syntax.........:	_SamsungTV_PowerOff($Addr)
; Parameter(s)...:	$Addr		- ip-����� ���������� � ����
; ===============================================================================================================
Func _SamsungTV_PowerOff($Addr)
 Local $OffCount = 0, $Timer = TimerInit()
 While True
  _SamsungTV_SendCommand($Addr, "KEY_POWEROFF")
  Local $iPing = Ping($Addr, 100)
  If $iPing == 0 Then
   $OffCount = $OffCount + 1
  Else
   $OffCount = 0
  EndIf
  If $OffCount > 4 Then ExitLoop
  If TimerDiff($Timer) > 10000 Then Return _LogWrite("������: ���������� ��������� ���������.")
  Sleep(250)
 WEnd
 _MySQL_Query("UPDATE `" & $sDB_TableDevices & "` SET ping = '0' WHERE id = " & $Addr & ";")
 _LogWrite("��������� ��������.")
EndFunc ;==>_SamsungTV_PowerOff

; #FUNCTION# ====================================================================================================
; Name...........:	_SamsungTV_Play
; Description....:	������ ��������������� DLNA-������������� �� ����������
; Syntax.........:	_SamsungTV_Play($Addr{, $sCurrentURI})
; Parameter(s)...:	$Addr		- ip-����� ���������� � ����
;					$sID		- ID ������������� (���� = '', �� ������������ ������� 'KEY_PLAY')
; ===============================================================================================================
Func _SamsungTV_Play($Addr, $sID = "")
 If $sID == "" Then Return _SamsungTV_SendCommand($Addr, "KEY_PLAY")
 If Not _ReadServerConfig($Addr) Then Return
 Local $sURL = $sServerURL & '/MediaServer/Folders/0?action%3Dplayto%3Bitemid%3D' & _
  $sID & '%3Bdeviceuuid%3D' & $sDeviceUUID
 If $DEBUG Then _LogWrite('�������� ������� ������������ ' & $sURL)
 InetRead($sURL, $INET_FORCERELOAD)
EndFunc ;==>_SamsungTV_Play
#EndRegion TV Control Commands

#Region Additional Functions
;------------------------------------------------ ��������������� ������� ---------------------------------------

; #FUNCTION# ======================================================================================================
; Name...........:	_SamsungTV_StringAddHeader
; Description....:	���������� � ������ ���������, ����������� ����� ������
; Syntax.........:	_SamsungTV_StringAddHeader($sString)
; Parameter(s)...:	$sString	- �������� ������
; Return value(s):	������, ������� ������� ��������� 2 �����, �������������� ����� ������
; Version .......:	0.0.1
; Modified.......:	27.12.2016
; =================================================================================================================
Func _SamsungTV_StringAddHeader($sString)
 Local $n = StringLen($sString)
 Local $sHeader = Chr(BitAND($n, 0xFF)) & Chr(BitAND(Floor($n / 0x100), 0xFF))
 Return $sHeader & $sString
EndFunc ;==>_SamsungTV_StringAddHeader

; #FUNCTION# ======================================================================================================
; Name...........:	_Base64Encode
; Description....:	�������� ������ �� ��������� MIME base64
; Syntax.........:	_Base64Encode($sDdata)
; Parameter(s)...:	$sDdata		- ������ ��� �����������
; Return value(s):	Success: ������������ ������, � ���� ������
;					Failure: ������ ������ � ���������� @error = 1
; Return value(s):	������������ ������, ��� ������ ��� FALSE � ������ ������������� ������.
; Version .......:	0.0.1
; Modified.......:	27.12.2016
; =================================================================================================================
Func _Base64Encode($sDdata)
 $sDdata = Binary($sDdata)
 Local $dllStruct = DllStructCreate("byte[" & BinaryLen($sDdata) & "]")
 DllStructSetData($dllStruct, 1, $sDdata)
 Local $strc = DllStructCreate("int")
 Local $a_Call = DllCall("Crypt32.dll", _
  "int", "CryptBinaryToString", _
  "ptr", DllStructGetPtr($dllStruct), _
  "int", DllStructGetSize($dllStruct), _
  "int", 1, _
  "ptr", 0, _
  "ptr", DllStructGetPtr($strc))
 If @error Or Not $a_Call[0] Then Return SetError(1, 0, "")
 Local $a = DllStructCreate("char[" & DllStructGetData($strc, 1) & "]")
 $a_Call = DllCall("Crypt32.dll", _
  "int", "CryptBinaryToString", _
  "ptr", DllStructGetPtr($dllStruct), _
  "int", DllStructGetSize($dllStruct), _
  "int", 1, _
  "ptr", DllStructGetPtr($a), _
  "ptr", DllStructGetPtr($strc))
 If @error Or Not $a_Call[0] Then Return SetError(1, 0, "")
 Return StringTrimRight(DllStructGetData($a, 1), 2)
EndFunc ;==>_Base64Encode
#EndRegion Additional Functions
