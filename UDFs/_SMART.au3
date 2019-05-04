#include-Once
#include <String.au3>
#include <Array.au3>

; #INDEX# =========================================================================================
; Title .........: S.M.A.R.T. UDF
; Version .......: 0.0.6
; Date ..........: 05.02.2018
; AutoIt Version : 3.3.12.0+
; Language ..... : Russian
; Description ...: ������� ��� ��������� ���������� � S.M.A.R.T. ������� ������.
; Author(s) .....: ��������� ���������
; =================================================================================================

; #CURRENT# =======================================================================================
;_SMART_LoadDiskInfo
;_SMART_LoadData
;_SMART_CheckError
;_SMART_FixSerialNumber
; =================================================================================================

Global Enum _						; ������� ��������� ������� �������� ������� ������:
 $_DISK_ATTR_INDEX, _				; ������ �������� ����� (0 = 1� ������� ����)
 $_DISK_ATTR_MODEL, _				; ������ �������� �����
 $_DISK_ATTR_SERIAL, _				; �������� ����� �������� �����
 $_DISK_ATTR_SIZE, _				; ������ �������� ����� (� ������)
 $_DISK_ATTR_PNPID, _				; PNP ������������� �������� ����� ��� ����������
 $_DISK_ATTR_PARTITIONS, _			; ������ �������� (partitions), ����������� �� ������� �����
 $_DISK_ATTR_LOGICALS, _			; ������ ���������� ������, ����������� �� ������� �����
 $_DISK_ATTR_COUNT

Global Enum _						; ������� ��������� ��������� �������� SMART:
 $_SMART_ATTR_ID, _					; ������ ��������
 $_SMART_ATTR_UNKNOWN, _			; �� ������������
 $_SMART_ATTR_THRESHOLD, _			; ��������� �������� ��������
 $_SMART_ATTR_VALUE, _				; ������� �������� ��������
 $_SMART_ATTR_WORST, _				; '������' �������� ��������
 $_SMART_ATTR_RAW0, _				; '�����' ������ �������� 0� ���� (�������)
 $_SMART_ATTR_RAW1, _				; '�����' ������ �������� 1� ����
 $_SMART_ATTR_RAW2, _				; '�����' ������ �������� 2� ����
 $_SMART_ATTR_RAW3					; '�����' ������ �������� 3� ���� (�������)
Global $_SMART_ATTR_COUNT = 12

Global Enum _
 $_SMART_DATA_DISK, _				; ������ �������� �����
 $_SMART_DATA_ID, _					; ������ ��������
 $_SMART_DATA_VALUE, _				; ������� �������� ��������
 $_SMART_DATA_THRESHOLD, _			; ��������� �������� ��������
 $_SMART_DATA_WORST, _				; '������' �������� ��������
 $_SMART_DATA_RAW, _				; '�����' ������ ��������
 $_SMART_DATA_ERROR, _				; ��� ������
 $_SMART_DATA_COUNT

Global Enum _
 $_SMART_ERROR_OK, _				; ������ �� ����������
 $_SMART_ERROR_WARNING, _			; �������������� �� ������� ���������
 $_SMART_ERROR_CRITICAL				; ����������� ���������

Global Enum _
 $_CHECK_NONE, _
 $_CHECK_TEMPERATURE, _
 $_CHECK_CHANGE

Global Enum _
 $_SMART_CODE_ID, _
 $_SMART_CODE_NAME, _
 $_SMART_CODE_CHECKMODE

#Region S.M.A.R.T. Attribute Names
Dim	$aSMARTCodeText[66][3] = [ _
 [  1,"Raw Read Error Rate",$_CHECK_NONE], _
 [  2,"Throughput Performance",$_CHECK_NONE], _
 [  3,"Spin Up Time",$_CHECK_NONE], _
 [  4,"Start/Stop Count",$_CHECK_NONE], _
 [  5,"Retired Block Count",$_CHECK_NONE], _
 [  6,"Read Channel Margin",$_CHECK_NONE], _
 [  7,"Seek Error Rate",$_CHECK_NONE], _
 [  8,"Seek Time Performance",$_CHECK_NONE], _
 [  9,"Power On Hours (POH)",$_CHECK_NONE], _
 [ 10,"Spin-Up Retry Count",$_CHECK_NONE], _
 [ 11,"Recalibration Retries",$_CHECK_NONE], _
 [ 12,"Device Power Cycle Count",$_CHECK_NONE], _
 [ 13,"Soft Read Error Rate",$_CHECK_NONE], _
 [174,"Unexpected Power Loss Count",$_CHECK_NONE], _
 [175,"Maximum Program Fail Count",$_CHECK_NONE], _
 [176,"Maximum Erase Fail Count",$_CHECK_NONE], _
 [177,"Endurance Used",$_CHECK_NONE], _
 [178,"Used Reserved Block Count",$_CHECK_NONE], _
 [179,"Used Reserved Block Count",$_CHECK_NONE], _
 [180,"End to End Error Detection Rate",$_CHECK_NONE], _
 [181,"Program Fail Count",$_CHECK_NONE], _
 [182,"Erase Fail Count",$_CHECK_NONE], _
 [183,"SATA Downshift Count",$_CHECK_NONE], _
 [184,"End to End Error Detection Count",$_CHECK_NONE], _
 [187,"Uncorrectable Error Count",$_CHECK_NONE], _
 [188,"Command Timeout Count",$_CHECK_NONE], _
 [189,"SSD Health Flags",$_CHECK_NONE], _
 [190,"Airflow Temperature / SATA Error Counter",$_CHECK_NONE], _
 [191,"G-Sense Error Rate",$_CHECK_NONE], _
 [192,"Power-Off Retract Count",$_CHECK_NONE], _
 [193,"Load/Unload Cycle",$_CHECK_NONE], _
 [194,"HDD Temperature",$_CHECK_TEMPERATURE], _
 [195,"ECC Uncorrectable Error Rate",$_CHECK_NONE], _
 [196,"Reallocation Event Count",$_CHECK_NONE], _
 [197,"Current Pending Sector Count",$_CHECK_NONE], _
 [198,"Uncorrectable Sector Count",$_CHECK_NONE], _
 [199,"UltraDMA CRC Error Count",$_CHECK_NONE], _
 [200,"Write Error Rate",$_CHECK_NONE], _
 [201,"Uncorrectable Soft Read Error Rate (UECC)",$_CHECK_NONE], _
 [202,"Data Address Mark Errors",$_CHECK_NONE], _
 [203,"Run Out Cancel",$_CHECK_NONE], _
 [204,"Soft ECC Correction Rate",$_CHECK_NONE], _
 [205,"Thermal Asperity Rate",$_CHECK_NONE], _
 [206,"Flying Height",$_CHECK_NONE], _
 [207,"Spin High Current",$_CHECK_NONE], _
 [208,"Spin Buzz",$_CHECK_NONE], _
 [209,"Offline Seek Performance",$_CHECK_NONE], _
 [220,"Disk Shift",$_CHECK_NONE], _
 [221,"G-Sense Error Rate",$_CHECK_NONE], _
 [222,"Loaded Hours",$_CHECK_NONE], _
 [223,"Load/Unload Retry Count",$_CHECK_NONE], _
 [224,"Load Friction",$_CHECK_NONE], _
 [225,"Load/Unload Cycle Count",$_CHECK_NONE], _
 [226,"Load-in Time",$_CHECK_NONE], _
 [227,"Torque Amplification Count",$_CHECK_NONE], _
 [228,"Power-Off Retract Count�",$_CHECK_NONE], _
 [230,"GMR Head Amplitude�",$_CHECK_NONE], _
 [231,"SSD Life Left (%)",$_CHECK_NONE], _
 [234,"Vendor Specific",$_CHECK_NONE], _
 [240,"Head Flying Hours",$_CHECK_NONE], _
 [241,"Lifetime Writes from Host",$_CHECK_NONE], _
 [242,"Lifetime Reads from Host",$_CHECK_NONE], _
 [245,"Vendor Specific",$_CHECK_NONE], _
 [250,"NAND Read Retries",$_CHECK_NONE], _
 [254,"Free Fall Protection",$_CHECK_NONE]]
#EndRegion S.M.A.R.T. Attribute Names

; #FUNCTION# ====================================================================================================
; Name...........:	_SMART_LoadDisksList
; Description....:	��������� ������ ���������� ������� ������ � ���������� � ���
; Syntax.........:	_SMART_LoadDisksList()
; Return value(s):	On Success - ���������� ��������� ������, ���������� ���������� � ������� ������,
;						������ ������� �������� �������� ������ �� ���������� ����������:
;						$_DISK_ATTR_INDEX		- ������ �������� ����� (0 = 1� ������� ����)
;						$_DISK_ATTR_MODEL		- ������ �������� �����
;						$_DISK_ATTR_SERIAL		- �������� ����� �������� �����
;						$_DISK_ATTR_SIZE		- ������ �������� ����� (� ������)
;						$_DISK_ATTR_PNPID		- PNP ������������� �������� ����� ��� ����������
;						$_DISK_ATTR_PARTITIONS	- ������ �������� (partitions), ����������� �� ������� �����
;						$_DISK_ATTR_LOGICALS	- ������ ���������� ������, ����������� �� ������� �����
; ===============================================================================================================
Func _SMART_LoadDisksList()
 Local $ObjService = ObjGet("winmgmts:\\" & @ComputerName & "\root\CIMV2")
 Local $ObjItems = $ObjService.ExecQuery("SELECT * FROM Win32_DiskDrive", "WQL", 0x30)
 If Not IsObj($ObjItems) Then Return SetError(1, 0, 0)
 Local $ObjItem, $i = 0
 For $ObjItem In $ObjItems
  If $i == 0 Then
   $i = 1
   Dim $aDisks[$i][$_DISK_ATTR_COUNT]
  Else
   $i = UBound($aDisks) + 1
   ReDim $aDisks[$i][$_DISK_ATTR_COUNT]
  EndIf
  $aDisks[$i - 1][$_DISK_ATTR_INDEX]		= $ObjItem.Index
  $aDisks[$i - 1][$_DISK_ATTR_MODEL]		= $ObjItem.Model
  $aDisks[$i - 1][$_DISK_ATTR_SERIAL]		= _SMART_FixSerialNumber($ObjItem.SerialNumber)
  $aDisks[$i - 1][$_DISK_ATTR_SIZE]			= $ObjItem.Size
  $aDisks[$i - 1][$_DISK_ATTR_PNPID]		= $ObjItem.PNPDeviceID
  $aDisks[$i - 1][$_DISK_ATTR_PARTITIONS]	= ""
  $aDisks[$i - 1][$_DISK_ATTR_LOGICALS]		= ""
 Next
 $ObjItems = $ObjService.ExecQuery("SELECT * FROM Win32_DiskPartition", "WQL", 0x30)
 If Not IsObj($ObjItems) Then Return SetError(2, 0, 0)
 For $ObjItem In $ObjItems
  $i = _ArraySearch($aDisks, $ObjItem.DiskIndex, 0, 0, 0, 0, 1, $_DISK_ATTR_INDEX)
  If $i < 0 Then Return SetError(2, 0, -1)
  $aDisks[$i][$_DISK_ATTR_PARTITIONS] &= $ObjItem.DeviceID & ";"
 Next
 Local $ObjItems = $ObjService.ExecQuery("SELECT * FROM Win32_LogicalDiskToPartition", "WQL", 0x30)
 If Not IsObj($ObjItems) Then Return SetError(3, 0, 0)
 For $ObjItem In $ObjItems
  Local $sSubStr = _StringBetween($ObjItem.Antecedent, '="', '"')
  If $sSubStr == 0 Then Return SetError(3, 0, 0)
  For $i = 0 To UBound($aDisks) - 1
   If StringInStr($aDisks[$i][$_DISK_ATTR_PARTITIONS], $sSubStr[0]) == 0 Then ContinueLoop
   $sSubStr = _StringBetween($ObjItem.Dependent, '="', '"')
   If $sSubStr == 0 Then Return SetError(3, 0, 0)
   $aDisks[$i][$_DISK_ATTR_LOGICALS] &= (StringLen($aDisks[$i][$_DISK_ATTR_LOGICALS]) > 0 ? ";" : "") & $sSubStr[0]
   ExitLoop
  Next
 Next
 Return $aDisks
EndFunc ;==>_SMART_LoadDisksList

; #FUNCTION# ====================================================================================================
; Name...........:	_SMART_LoadData
; Description....:	��������� ������� S.M.A.R.T. ������� ������
; Syntax.........:	_SMART_LoadData($aDisks[, $iDisk])
; Parameter(s)...:	$aDisks		- ������, ���������� ���������� � ������� ������, ���������� _SMART_LoadDisksList
;					$iDisk		- ������ �����, ���� ����� �������� ������� S.M.A.R.T. ������ ������ �����
; Return value(s):	On Success - ���������� ��������� ������, ���������� ������� S.M.A.R.T. ������� ������
;						������ ������� �������� �������� ������ �� ���������� ����������:
;						$_SMART_DATA_DISK		- ������ �������� ����� (0 = 1� ������� ����)
;						$_SMART_DATA_ID			- ������ ��������
;						$_SMART_DATA_VALUE		- ������� �������� ��������
;						$_SMART_DATA_THRESHOLD	- ��������� �������� ��������
;						$_SMART_DATA_WORST		- '������' �������� ��������
;						$_SMART_DATA_RAW		- '�����' ������ ��������
;						$_SMART_DATA_ERROR		- ��� ������
;					On Failure - ���������� 0. ���������� @error ��������� ��������� ��������:
;						1 - ������ ������� MSStorageDriver_ATAPISmartData
;						2 - ������ ������� MSStorageDriver_FailurePredictThresholds
;						3 - �� ������ PnP ID �����
; ===============================================================================================================
Func _SMART_LoadData($aDisks, $iDisk = -1)
 Local $ObjService = ObjGet("winmgmts:\\" & @ComputerName & "\root\WMI")
 Local $ObjItems = $objService.ExecQuery("SELECT * FROM MSStorageDriver_ATAPISmartData", "WQL", 0x30)
 If Not IsObj($ObjItems) Then Return SetError(1, 0, 0)
 Local $iDisksStart = $iDisk
 Local $iDisksEnd = $iDisk
 If $iDisk < 0 Then
  $iDisksStart = 0
  $iDisksEnd = UBound($aDisks) - 1
 EndIf
 Local $i, $n, $iCount = 0
 Local $ObjItem
 For $ObjItem In $ObjItems
  Local $nDisk = _SearchIndexHDD($aDisks, $ObjItem.InstanceName, $iDisksStart, $iDisksEnd)
  If $nDisk < 0 Then ContinueLoop
  Local $aVendorSpecific = $ObjItem.VendorSpecific
  For $i = 2 to UBound($aVendorSpecific) - $_SMART_ATTR_COUNT Step $_SMART_ATTR_COUNT
   If $aVendorSpecific[$i] == 0 Then ContinueLoop
   If $iCount == 0 Then
    $iCount = 1
    Dim $aSMART[$iCount][$_SMART_DATA_COUNT]
   Else
    $iCount = UBound($aSMART) + 1
    ReDim $aSMART[$iCount][$_SMART_DATA_COUNT]
   EndIf
   $aSMART[$iCount - 1][$_SMART_DATA_DISK]	= $nDisk
   $aSMART[$iCount - 1][$_SMART_DATA_ID]	= $aVendorSpecific[$i + $_SMART_ATTR_ID]
   $aSMART[$iCount - 1][$_SMART_DATA_VALUE]	= $aVendorSpecific[$i + $_SMART_ATTR_VALUE]
   $aSMART[$iCount - 1][$_SMART_DATA_WORST]	= $aVendorSpecific[$i + $_SMART_ATTR_WORST]
   $aSMART[$iCount - 1][$_SMART_DATA_RAW]	= $aVendorSpecific[$i + $_SMART_ATTR_RAW0] + _
									 BitShift($aVendorSpecific[$i + $_SMART_ATTR_RAW1], -8) + _
									 BitShift($aVendorSpecific[$i + $_SMART_ATTR_RAW2], -16) + _
									 BitShift($aVendorSpecific[$i + $_SMART_ATTR_RAW3], -24)
   $aSMART[$iCount - 1][$_SMART_DATA_ERROR]	= $_SMART_ERROR_OK
   $iCount += 1
  Next
 Next
 If $iCount == 0 Then Return SetError(3, 0, 0)
 Local $ObjItems = $ObjService.ExecQuery("SELECT * FROM MSStorageDriver_FailurePredictThresholds", "WQL", 0x30)
 If Not IsObj($ObjItems) Then Return SetError(2, 0, 0)
 For $ObjItem In $ObjItems
  Local $nDisk = _SearchIndexHDD($aDisks, $ObjItem.InstanceName, $iDisksStart, $iDisksEnd)
  If $nDisk < 0 Then ContinueLoop
  Local $aVendorSpecific = $objItem.VendorSpecific
  For $i = 2 to UBound($aVendorSpecific) - $_SMART_ATTR_COUNT Step $_SMART_ATTR_COUNT
   If $aVendorSpecific[$i] == 0 Then ContinueLoop
   For $n = 0 to UBound($aSMART, 1) - 1
    If $aSMART[$n][$_SMART_DATA_DISK] <> $nDisk Then ContinueLoop
    If $aSMART[$n][$_SMART_DATA_ID] $aVendorSpecific[$i + $_SMART_ATTR_ID] <> Then ContinueLoop
    $aSMART[$n][$_SMART_DATA_THRESHOLD] = $aVendorSpecific[$i + 1]
    ExitLoop
   Next
  Next
  ExitLoop
 Next
 Return $aSMART
EndFunc ;==>_SMART_LoadData

; #FUNCTION# ====================================================================================================
; Name...........:	_SMART_CheckError
; Description....:	�������� �������� �������� ������� S.M.A.R.T. �������� �����.
; Syntax.........:	_SMART_CheckError($aSMART)
; Parameter(s)...:	$aSMART		- ���������, ���������� �������� _SMART_LoadData
; Return value(s): Success      - 0 = ������ �� ����������
;				   Failure		- ���������� ���� �� ��������� ��������:
;								1 = ���������� ���� ��� ��������� ������, ������� �� ��������
;								2 = ���������� ���� ��� ��������� ����������� ������
; ===============================================================================================================
Func _SMART_CheckError(ByRef $aSMART)
 Local $i, $j, $Result = $_SMART_ERROR_OK
 For $i = 0 To UBound($aSMART) - 1
  Local $attr = _ArraySearch($aSMARTCodeText, $aSMART[$i][$_SMART_DATA_ID], 0, 0, 0, 0, 1, $_SMART_CODE_ID)
  If $attr >= 0 Then
   Switch $aSMARTCodeText[$attr][$_SMART_CODE_CHECKMODE]
    Case $_CHECK_TEMPERATURE ; �������� ����������� �����
     Local $iTemperatureCritical = 55
     Local $iTemperatureWarning = 45
	 For $j = 0 To UBound($aSMART) - 1
	  If ($aSMART[$j][$_SMART_DATA_DISK] == $aSMART[$i][$_SMART_DATA_DISK]) AND _
		 ($aSMART[$j][$_SMART_DATA_ID] == 3) Then
	   If $aSMART[$j][$_SMART_DATA_RAW] == 0 Then ; SSD ����
		$iTemperatureCritical = 70
		$iTemperatureWarning = 60
	   EndIf
	   ExitLoop
      EndIf
     Next
     If $aSMART[$i][$_SMART_ATTR_RAW0] > $iTemperatureCritical Then
      $aSMART[$i][$_SMART_DATA_ERROR] = $_SMART_ERROR_CRITICAL
      $Result = _Max($Result, $_SMART_ERROR_CRITICAL)
     ElseIf $aSMART[$i][$_SMART_ATTR_RAW0] > $iTemperatureWarning Then
      $aSMART[$i][$_SMART_DATA_ERROR] = $_SMART_ERROR_WARNING
      $Result = _Max($Result, $_SMART_ERROR_WARNING)
     EndIf
   EndSwitch
  EndIf
 Next
 Return $Result
EndFunc ;==>_SMART_CheckError

; #FUNCTION# ====================================================================================================
; Name...........:	_SMART_FixSerialNumber
; Description....:	��������� ��������� ������ �������� �����
; Syntax.........:	_SMART_FixSerialNumber($sSerialNumber)
; Parameter(s)...:	$sSerialNumber - �������� �����, ���������� �� ������� Win32_DiskDrive
; Return value(s):	���������� ������ � ������������ �������� �������
; Remarks .......:  ������ ��� ������ �������� SerialNumber ������ ��������� ������ ������������ ������, �
;					������� ����� ����������� � ���� ������������������ ����������������� ����
; ===============================================================================================================
Func _SMART_FixSerialNumber($sSerialNumber)
 Local $i, $c, $isHex = True
 While StringRight($sSerialNumber, 1) = " "
  $sSerialNumber = StringTrimRight($sSerialNumber, 1)
 WEnd
 Local $sSaveSerialNumber = $sSerialNumber
 For $i = 1 To StringLen($sSerialNumber)
  If StringInStr("0123456789ABCDEF", StringUpper(StringMid($sSerialNumber, $i, 1))) > 0 Then ContinueLoop
  $isHex = False
  ExitLoop
 Next
 If $isHex Then
  Local $sNewSerial = ""
  While StringLen($sSerialNumber) > 0
   $c = Chr(Dec(StringMid($sSerialNumber, 3, 2)))
   If StringInStr("0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ ", StringUpper($c)) < 1 Then $isHex = False
   $sNewSerial &= $c
   $c = Chr(Dec(StringLeft($sSerialNumber, 2)))
   If StringInStr("0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ ", StringUpper($c)) < 1 Then $isHex = False
   $sNewSerial &= $c
   $sSerialNumber = StringTrimLeft($sSerialNumber, 4)
  WEnd
  $sSerialNumber = $sNewSerial
 EndIf
 If Not $isHex Then $sSerialNumber = $sSaveSerialNumber
 While StringLeft($sSerialNumber, 1) = " "
  $sSerialNumber = StringTrimLeft($sSerialNumber, 1)
 WEnd
 Return $sSerialNumber
EndFunc ;==>_SMART_GetAttrName

; #FUNCTION# ====================================================================================================
; Name...........:	_SMART_GetTemperature
; Description....:	��������� ����������� �������� �����
; Syntax.........:	_SMART_GetTemperature($aSMART, $iDisk)
; Parameter(s)...:	$aSMART 	- ���������, ���������� �������� _SMART_LoadData
;					$iDisk		- ������ �����
; Return value(s):	On Success - ���������� �������� ����������� ������� ����������� �������� �����
;					On Failure - ���������� 0. ���������� @error ��������� �������� 1
; ===============================================================================================================
Func _SMART_GetTemperature($aSMART, $iDisk)
 For $i = 0 To UBound($aSMART, 1) - 1
  If $aSMART[$i][$_SMART_DATA_DISK] <> $iDisk Then ContinueLoop
  If $aSMART[$i][$_SMART_DATA_ID] <> 194 Then ContinueLoop
  Return BitAND($aSMART[$i][$_SMART_DATA_RAW], 0xFF)
 Next
 Return SetError(1, 0, "")
EndFunc ;==>_SMART_GetTemperature

; #FUNCTION# ====================================================================================================
; Name...........:	_SMART_GetAttrName
; Description....:	��������� �������� �������� S.M.A.R.T.
; Syntax.........:	_SMART_GetAttrName($id)
; Parameter(s)...:	$id 		- ������ ��������
; Return value(s):	On Success - ���������� ������, ���������� �������� ��������
;					On Failure - ���������� ������ "Unknown"
; ===============================================================================================================
Func _SMART_GetAttrName($id)
 Local $i = _ArraySearch($aSMARTCodeText, $id, 0, 0, 0, 0, 1, $_SMART_CODE_ID)
 If $i < 0 Then Return "Unknown"
 Return $aSMARTCodeText[$i][$_SMART_CODE_NAME]
EndFunc ;==>_SMART_GetAttrName

Func _SearchIndexHDD($aDisks, $sPnP_ID, $iDisksStart, $iDisksEnd)
 Local $n = StringInStr($sPnP_ID, "_", 0, -1)
 If $n == 0 Then Return SetError(1, 0, -1)
 $sPnP_ID = StringLeft($sPnP_ID, $n - 1)
 Local $nDisk = _ArraySearch($aDisks, $sPnP_ID, $iDisksStart, $iDisksEnd, 0, 0, 1, $_DISK_ATTR_PNPID)
 If $nDisk < 0 Then  Return SetError(1, 0, -1)
 Return $nDisk
EndFunc ;==>_SearchIndexHDD
