#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.0
	Date...........:	30.04.2019
	Title..........:	SmartHome - Telegram Bot
	Filename.......:	Telegram.au3
	Description....:	������� "����� ���". ������ �������� ��������� � Telegram
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						send {id �������������} {���������} - �������� ���������
						/debug - ����� ������� (��������� ����� � ����������)

						��������! id ������������� ������ ���� ������� ����� �������, ��� ��������.
						��� ������ ������� � ���� ������, � ������� 'config' ����� ��������� ������
						'TelegramToken', ������ ����� ����.
						����  � ���� ������, � ������� 'config' ����� �������� 'TelegramProxy',
						�� ��� �������� ��������� ����� �������������� �������������� ������-������.
						��� ��������� ������ ���� ���������� ������� ����, ��� ���� � ����������
						telegram ����� ����� ����� @BotFather � ������ ������� /newbot
						��� ��������� id ������������ ���������� � ���������� ����� ��������� ����
						(�� �����), ��������� ��� ��������� � � �������� � �������� ������ ������:
						https://api.telegram.org/bot{token}/getUpdates, ��� {token} - ����� ����.
						������ ���� ������� ������ ��������, � ������� id ������������ ����� ��������
						����� �������� ���� '"from":{"id":' � �������������� ���������.

	Versions.......:	0.0.0.1 (09.11.2017) - ������ ������
						0.0.1.0 (30.07.2018) - ��������� ����������� ������ � ������-���������
						0.2.0.0 (30.04.2019) - ��������� ������������� ��� ������ ������� 2.0.0
#CE
#EndRegion Header

#Region Initialization
#pragma compile(Out, ..\bin\utils\Telegram.exe)
#pragma compile(Icon, ..\resources\icons\Telegram.ico)
#pragma compile(ProductName, Smart Home Server - Telegram Bot)
#pragma compile(FileVersion, 0.2.0.0)
#pragma compile(LegalCopyright, (c) 2017-2019 Aleksandr Prilutskiy)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <InetConstants.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

; ��������� ���������� ����������
		$sAppShortName			= 'Telegram Bot'						; ������� �������� ���������
		$iMultiRunMode			= $_MULTIRUN_MODE_ENABLE				; ����� �������� ������������� �������

; ������ ����������, ������������ � ����������
Global	$sTelegramToken			= ''									; ����� ���� ������� Telegram
Global	$sTelegramProxy			= ''									; ����� ������-�������
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
           "Telegram.exe [send] {user1,user2,...,userN} {message} {/debug}" & @CRLF & _
		   " send {users id list} {message} - �������� ��������� ������������� �� ������ (����� ',')" & @CRLF & _
		   " /debug - ����� ������� (��������� ����� � ����������)")
  If $CmdLine[1] == "send" Then
   If $CmdLine[0] < 3 Then Return
   _ReadServerConfig()
   _SendMessage()
   Return
  EndIf
 EndIf
 _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'Telegram.exe /?'")
EndFunc ;==>_Main
#EndRegion Main

#Region Read Config
;-------------------------------------------- ������� �������� �������� ���������� ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ReadServerConfig
; Description....:	������ �������� ������� "����� ���" �� ���� ������.
; Syntax.........:	_ReadServerConfig()
; ===============================================================================================================
Func _ReadServerConfig()
 $sTelegramToken = _MySQL_ReadConfig("TelegramToken")
 $sTelegramProxy = _MySQL_ReadConfig("TelegramProxy")
 If StringLen($sTelegramToken) == 0 Then
  _LogWrite(" ������ ��������� ���������� �������� ���������" & @CRLF & _
			" ��������� ������ 'TelegramToken' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "������ Telegram API Token")
  _AppExit()
 EndIf
 If $DEBUG Then _
  _LogWrite("���� �������� ��������� ��������� ������� '����� ���':" & @CRLF & _
			" TelegramToken = " & $sTelegramToken & @CRLF & _
			" Proxy-������  = " & $sTelegramProxy & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region Telegram Send Message
;------------------------------------------------- ������� �������� ��������� -----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_SendMessage
; Description....:	�������� ��������� � ���������� Telegram
; Syntax.........:	_SendMessage()
; ===============================================================================================================
Func _SendMessage()
 $aTelegramUsers = _StringExplode($CmdLine[2], ",")
 If UBound($aTelegramUsers) < 1 Then
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
 If StringLen($sTelegramProxy) > 0 Then
  _LogWrite(' ������������ ������-������:' & $sTelegramProxy)
  HttpSetProxy(2, $sTelegramProxy)
 EndIf
 For $i = 0 To UBound($aTelegramUsers) - 1
  Local $sResponse = InetRead('https://api.telegram.org/bot' & $sTelegramToken & '/sendMessage?chat_id=' & _
	    $aTelegramUsers[$i] & '&text=' & _StringURLEncode(_StringToUTF8($sMessage)), $INET_FORCERELOAD)
  If @error Then
   _LogWrite(' ������: ���������� ��������� ��������� ������������ id=' & $aTelegramUsers[$i])
   _LogWrite($sResponse)
   _SysyemLogWrite(0, 1, '������ ��� �������� ��������� ������������ id=' & $aTelegramUsers[$i])
  Else
   _LogWrite(' ���������� ��������� "' & $sMessage & '" ������������ id=' & $aTelegramUsers[$i])
  EndIf
 Next
EndFunc ;==>_SendMessage
#EndRegion Telegram Send Message
