#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.1
	Date...........:	29.04.2019
	Title..........:	SmartHome - DDNS Update
	Filename.......:	DDNS.au3
	Description....:	������� "����� ���". ������ ���������� ������ DDNS
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						test - �������� ������� DDNS
						update - ���������� ������ DDNS
						/debug - ����� ������� (��������� ����� � ����������)

						��� ������ ������� � ���� ������, � ������� 'config' ����� ��������� ������:
						'DDNS_Domains', 'DDNS_User' � 'DDNS_Password', � ������� ����� �������
						������������� �����, ��� ������������ � ������ �� ����� 'ddns.net'.
						� ���� 'DDNS_Domains' ����� ��������� ��������� �������, ����������� �
						��������� ������� ������, ����� ����� � ������� ';'.

	Versions.......:	0.0.1.0 (19.07.2017) - ������ ������ ���������
						0.0.2.0 (06.02.2019) - ��������� ��������� ���������� ��������� ������
						0.0.2.3 (11.02.2019) - ��������� ������� test � ����� � ���������� �������
						0.2.0.0 (26.04.2019) - ��������� ������������� ��� ������ ������� 2.0.0
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

; ��������� ���������� ����������
		$sAppShortName			= 'DDNS Update'							; ������� �������� ���������

; ������ ����������, ������������ � ����������
Global	$sDDNS_Domains			= ''									; ��� ������
Global	$sDDNS_User				= ''									; ��� ������������
Global	$sDDNS_Password			= ''									; ������
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
   Return _LogWrite("������� '����� ���'. ������ ���������� ������������ ������ DNS (DDNS)." & @CRLF & _
		   "��������� ��������� ������:" & @CRLF & _
           "DDNS.exe [update] {/debug}" & @CRLF & _
		   " test - �������� ������� DDNS" & @CRLF & _
		   " update - ���������� ������ DDNS" & @CRLF & _
		   " /debug - ����� ������� (��������� ����� � ����������)")
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
 _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'DDNS.exe /?'")
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
 Local $i, $Query, $sDir
 $sDDNS_User	 = _MySQL_ReadConfig('DDNS_User')
 $sDDNS_Password = _MySQL_ReadConfig('DDNS_Password')
 $sDDNS_Domains	 = _MySQL_ReadConfig('DDNS_Domains')
 If (StringLen($sDDNS_User) == 0) Or (StringLen($sDDNS_Password) == 0) Or (StringLen($sDDNS_Domains) == 0) Then
  _LogWrite(" ������ ��������� ���������� DDNS �������" & @CRLF & _
			" ��������� ������ 'DDNS_User', 'DDNS_Password' � 'DDNS_Domains'" & _
			" � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "������ ���������� DDNS �������")
  _AppExit()
 EndIf
 If $DEBUG Then _
  _LogWrite("���� �������� ��������� ��������� ������� '����� ���':" & @CRLF & _
			" DDNS_User =     " & $sDDNS_User & @CRLF & _
			" DDNS_Password = " & $sDDNS_Password & @CRLF & _
			" DDNS_Domains  = " & $sDDNS_Domains & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region DDNS Functions
;-------------------------------------------- ������� ������ � ������� DDNS -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_TestRecordDDNS
; Description....:	�������� ������ DDNS �������
; Syntax.........:	_TestRecordDDNS()
; ===============================================================================================================
Func _TestRecordDDNS()
 _LogWrite("�������� ������ ������ (�������):")
 Local $aDomain = _StringExplode($sDDNS_Domains, ";")
 For $i = 0 To UBound($aDomain) - 1
  Local $sDDNS_IP_Old = _NOIP_HostnameResolve($aDomain[$i])
  If @error Then
   _LogWrite(" " & $aDomain[$i] & @CRLF & "  �� ������� � IP-������" & @CRLF)
  Else
   _LogWrite(" " & $aDomain[$i] & @CRLF & "  ->" & $sDDNS_IP_Old & @CRLF)
  EndIf
 Next
 _LogWrite()
EndFunc ;==>_TestRecordDDNS

; #FUNCTION# ====================================================================================================
; Name...........:	_UpdateRecordDDNS
; Description....:	���������� ������ DDNS �������
; Syntax.........:	_UpdateRecordDDNS()
; ===============================================================================================================
Func _UpdateRecordDDNS()
 Local $i, $iErrorCount = 0, $iChangeCount = 0
 _LogWrite("���������� ������ ������ (�������): '" & $sDDNS_Domains & "'")
 If $DEBUG Then _LogWrite(" ������ ���� ������� �� ���������� ��������:")
 Local $aDomain = _StringExplode($sDDNS_Domains, ";")
 Dim $aIP[UBound($aDomain)]
 For $i = 0 To UBound($aDomain) - 1
  $aIP[$i] = _NOIP_HostnameResolve($aDomain[$i])
  If $DEBUG Then _LogWrite(" " & $aDomain[$i] & " = " & ($aIP[$i] == "" ? "����� �� ������" : $aIP[$i]))
 Next
 If $DEBUG Then _LogWrite()
 For $i = 0 To UBound($aDomain) - 1
  _NOIP_DNSUpdate($sDDNS_User, $sDDNS_Password, $aDomain[$i])
  If @error Then
   _LogWrite(" ������ ���������� ������ DDNS ������� ��� ������: '" & $aDomain[$i] & "'")
   $aIP[$i] = ""
   $iErrorCount += 1
  Else
   _LogWrite(" ������ ������: '" & $aDomain[$i] & "' - ������� ���������")
  EndIf
 Next
 _LogWrite()
 Local $sText = ""
 Local $sIP = __NOIP_GetIpAddress()
 For $i = 0 To UBound($aDomain) - 1
  If StringLen($aIP[$i]) > 0 Then
   If ($sIP <> $aIP[$i]) Or $DEBUG Then _
    _LogWrite(" ����� '" & $aDomain[$i] & "' ������ ������ � IP-�������: " & $sIP)
   If $sIP <> $aIP[$i] Then $iChangeCount += 1
  Else
   _LogWrite(" ������. ����� '" & $aDomain[$i] & "' - �� ��������")
  EndIf
 Next
 If $iChangeCount > 0 Then $sText &= "�������� �������: " & $iChangeCount
 If $iErrorCount > 0 Then $sText &= (StringLen($sText) > 0 ? "; " : "") & "����� ������: " & $iErrorCount
 If StringLen($sText) > 0 Then _SysyemLogWrite($iChangeCount, $iErrorCount, $sText)
EndFunc ;==>_UpdateRecordDDNS
#EndRegion DDNS Functions
