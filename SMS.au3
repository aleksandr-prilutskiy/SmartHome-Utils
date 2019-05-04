#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.0
	Date...........:	30.04.2019
	Title..........:	SmartHome - SMS Bot
	Filename.......:	SMS.au3
	Description....:	������� "����� ���". ������ �������� SMS-���������
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						send {������ ���������} {���������} - �������� ���������
						/debug - ����� ������� (��������� ����� � ����������)

						��������! ������ ��������� ������ ���� ������� ����� �������,
						10 ���� ������, ��� '+7' ��� '8' � ������.
						��� ������ ������� � ���� ������, � ������� 'config' ����� ��������� ������
						'SMS_API_Key', ������ ����� � ����� 'sms.ru'.

	Versions.......:	0.0.0.1 (04.07.2018) - ������ ������
						0.2.0.0 (30.04.2019) - ��������� ������������� ��� ������ ������� 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\SMS.exe)
#pragma compile(Icon, ..\resources\icons\SMS.ico)
#pragma compile(ProductName, Smart Home Server - SMS Bot)
#pragma compile(FileVersion, 0.2.0.0)
#pragma compile(LegalCopyright, (c) 2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <InetConstants.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; ��������� ���������� ����������
		$sAppShortName			= 'SMS Bot'								; ������� �������� ���������
		$iMultiRunMode			= $_MULTIRUN_MODE_ENABLE				; ����� �������� ������������� �������

; ������ ����������, ������������ � ����������
Global	$sAPPID					= ''									; ���� API �� ����� 'sms.ru'
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
   Return _LogWrite("������� '����� ���'. ������ �������� ��������� � Telegram." & @CRLF & _
		   "��������� ��������� ������:" & @CRLF & _
           "SMS.exe [send] {phone#1,phone#2,...,phone#N} {message} {/debug}" & @CRLF & _
		   " send {phones # list} {message} - �������� ��������� �� �������� �� ������ (����� ',')" & @CRLF & _
		   " /debug - ����� ������� (��������� ����� � ����������)")
  If $CmdLine[1] == "send" Then
   If $CmdLine[0] < 3 Then Return
   _ReadServerConfig()
   _SendMessage()
   Return
  EndIf
 EndIf
 _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'SMS.exe /?'")
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
 $sAPPID = _MySQL_ReadConfig("SMS_API_Key")
 If StringLen($sAPPID) == 0 Then
  _LogWrite(" ������ ��������� ���������� �������� ���������" & @CRLF & _
			" ��������� ������ 'SMS_API_Key' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "������ SMS_API_Key")
  _AppExit()
 EndIf
 If $DEBUG Then _
  _LogWrite("���� �������� ��������� ��������� ������� '����� ���':" & @CRLF & _
			" API Key = " & $sAPPID & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region SMS Send Message
;------------------------------------------------- ������� �������� ��������� -----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_SendMessage
; Description....:	�������� ��������� � ���������� Telegram
; Syntax.........:	_SendMessage()
; ===============================================================================================================
Func _SendMessage()
 $aPhones = _StringExplode($CmdLine[2], ",")
 If UBound($aPhones) < 1 Then
  _LogWrite(' ������ � ID ������������')
  _SysyemLogWrite(0, 1, '������ ID ������������')
  _AppExit()
 EndIf
 Local $i, $sMessage = ""
 For $i = 3 To $CmdLine[0]
  $sMessage &= $CmdLine[$i] & " "
 Next
 While StringRight($sMessage, 1) == ' '
  $sMessage = StringTrimRight($sMessage, 1)
 WEnd
 If StringLower(StringRight($sMessage, 7)) == ' /debug' Then $sMessage = StringTrimRight($sMessage, 7)
 For $i = 0 To UBound($aPhones) - 1
  $sURL = 'https://sms.ru/sms/send?api_id=' & $sAPPID & '&to=7' & $aPhones[$i] & '&msg=' & $sMessage & '&json=1'
  $sResponse = BinaryToString(InetRead($sURL, $INET_FORCERELOAD), 4)
  If Not @error Then
   If $DEBUG Then _
    _LogWrite(' >' & $sURL & @CRLF & ' ����� �������:' & @CRLF & $sResponse & @CRLF)
   If StringInStr($sResponse, '"status_code": 100,') Then
    _LogWrite(' ���������� ��������� "' & $sMessage & '" �� ����� +7' & $aPhones[$i])
    ContinueLoop
   EndIf
  EndIf
  _LogWrite(' ������: ���������� ��������� ��������� �� ����� +7' & $aPhones[$i])
  _SysyemLogWrite(0, 1, '������ ��� �������� ��������� �� ����� +7' & $aPhones[$i])
 Next
EndFunc ;==>_SendMessage
#EndRegion SMS Send Message
