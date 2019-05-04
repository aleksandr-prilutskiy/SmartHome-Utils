#include-once
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

; #INDEX# =======================================================================================================================
; Title .........: NoIP UDF v.1.0.0
; AutoIt Version : v3.3.8.1
; Description ...: NoIP API UDF
; Author(s) .....: Nessie
; ===============================================================================================================================

; #INCLUDES# =========================================================================================================
; None

; #GLOBAL VARIABLES# =================================================================================================
; None


; #CURRENT# =====================================================================================================================
; _NOIP_DNSUpdate
; _NOIP_HostnameResolve
; ===============================================================================================================================


; #INTERNAL_USE_ONLY# ===========================================================================================================
; __NOIP_GetIpAddress
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _NOIP_DNSUpdate
; Description ...: Update multiple no-ip hostnames
; Syntax ........: _NOIP_DNSUpdate($sUser, $sPass, $sHostname[, $sIP = ""[, $bOffline = False[, $bSecure = True]]])
; Parameters ....: $sUser               - Your no-ip username
;                  $sPass               - Your no-ip password
;                  $sHostname           - Your no-ip hostname.
;										- If updating multiple hostnames use a comma separated list. Ex: test1.no-ip.biz,test2.no-ip.biz
;                  $sIP                 - The IP address to which the host(s) will be set. Default is the current IP address.
;                  $bOffline            - Sets the current host(s) to offline status. Offline settings are an Enhanced / No-IP Plus feature.
;                  $bSecure             - The protocol to use. If True the https protocol will be used, otherwise http. Default is True.
; Return values .: On Success - True
;				   On Failure -
;								@error = 1 Empty Username
;								@error = 2 Empty Password
;								@error = 3 Empty Hostname(s)
;								@error = 4 Invalid $bOffline parameter
;								@error = 5 Invalid $bSecure parameter
;								@error = 6 Unable to retrive the current IP address
;								@error = 7 Invalid IP address
;								@error = 8 Unable to contact the no-ip website
;								@error = 9 Unable to retrive the no-ip source
;								@error = 10 "nohost"
;								@error = 11 "badauth"
;								@error = 12 "badagent"
;								@error = 13 "!donator"
;								@error = 14 "abuse"
;								@error = 15 "911"
;								@error = 16 Unknown error
; Author ........: Nessie
; Example .......: _NOIP_DNSUpdate("Test", "Test", "TestME.zapto.org", "")
; ===============================================================================================================================
Func _NOIP_DNSUpdate($sUser, $sPass, $sHostname, $sIP = "", $bOffline = False, $bSecure = True)
	Local $iMatch, $sOffline, $sProtocol

	If $sUser = "" Then Return SetError(1, 0, "")
	If $sPass = "" Then Return SetError(2, 0, "")
	If $sHostname = "" Then Return SetError(3, 0, "")

	If Not IsBool($bOffline) Then Return SetError(4, 0, "")
	If Not IsBool($bSecure) Then Return SetError(5, 0, "")

	If $sIP = "" Then
		$sIP = __NOIP_GetIpAddress()
		If @error Then Return SetError(6, 0, "")
	EndIf

	;Thanks to http://tools.netshiftmedia.com/regexlibrary/# for this regex
	$iMatch = StringRegExp($sIP, "^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})$", 0)
	If Not $iMatch Then Return SetError(7, 0, "")

	If $bOffline Then
		$sOffline = "YES"
	Else
		$sOffline = "NO"
	EndIf

	If $bSecure Then
		$sProtocol = "https"
	Else
		$sProtocol = "http"
	EndIf

	Local $bRead = InetRead($sProtocol & "://" & $sUser & ":" & $sPass & "@dynupdate.no-ip.com/nic/update?hostname=" & $sHostname & "&myip=" & $sIP & "&offline=" & $sOffline)
	If @error Then Return SetError(8, 0, "")
	Local $sRead = BinaryToString($bRead)
	If @error Then Return SetError(9, 0, "")

	Switch $sRead
		Case StringInStr($sRead, "good ") Or StringInStr($sRead, "nochg ")
			Return True
		Case "nohost"
			Return SetError(10, 0, "")
		Case "badauth"
			Return SetError(11, 0, "")
		Case "badagent"
			Return SetError(12, 0, "")
		Case "!donator"
			Return SetError(13, 0, "")
		Case "abuse"
			Return SetError(14, 0, "")
		Case "911"
			Return SetError(15, 0, "")
		Case Else
			Return SetError(16, 0, "")
	EndSwitch
EndFunc   ;==>_NOIP_DNSUpdate

; #FUNCTION# ====================================================================================================================
; Name ..........: _NOIP_HostnameResolve
; Description ...: Converts a no-ip address to IP address.
; Syntax ........: _NOIP_HostnameResolve($sAddress)
; Parameters ....: $sAddress            - The no-ip hostname address
;Return values .:  On Success - Returns string containing IP address corresponding to the name.
;				   On Failure -
;							    @error = 1 Unable to retrive the IP address
; Author ........: Nessie
; Example .......: _NOIP_HostnameResolve("TestME.zapto.org")
; ===============================================================================================================================
Func _NOIP_HostnameResolve($sAddress)
	TCPStartup()
	Local $aResult = TCPNameToIP($sAddress)
	If @error Then Return SetError(1, 0, "")
	TCPShutdown()

	Return $aResult
EndFunc   ;==>_NOIP_HostnameResolve

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __NOIP_GetIpAddress
; Description ...: Retrive the current IP address
; Syntax ........: __NOIP_GetIpAddress()
;Return values .:  On Success - Returns string containing IP address corresponding to the name.
;				   On Failure -
;							    @error = 1 Unable to contact the server
;							    @error = 2 Unable to retrive the IP address
; Author ........: Nessie
; Example .......: __NOIP_GetIpAddress()
; ===============================================================================================================================
Func __NOIP_GetIpAddress()
	Local $bRead, $sRead, $aResult
	$bRead = InetRead("http://checkip.dyndns.org")
	If @error Then Return SetError(1, 0, "")
	$sRead = BinaryToString($bRead)
	If @error Then Return SetError(2, 0, "")

	$aResult = StringRegExp($sRead, "(?s)(?i)<body>Current IP Address: (.*?)</body>", 3)
	If Not @error Then Return $aResult[0]

	$bRead = InetRead("http://api.exip.org/?call=ip")
	If @error Then Return SetError(1, 0, "")
	$sRead = BinaryToString($bRead)
	If @error Then Return SetError(2, 0, "")

	Return $bRead
EndFunc   ;==>__NOIP_GetIpAddress