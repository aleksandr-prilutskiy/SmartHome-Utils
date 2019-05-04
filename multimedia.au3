#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.0
	Date...........:	02.05.2019
	Title..........:	SmartHome - Multimedia Database Utility
	Filename.......:	movies.au3
	Description....:	������� "����� ���". ������ ������������ ���� ������ �������������, ����������� �� �������
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	��������� ��������� ������, �������������� ����������:
						/? - ������� ������� � ���������� ��������� ������
						update - ���������� ������ ������������� � ���� ������
						/clear - ������� ���� ������ � ����������� � ������������� � ���� ������
						/debug - ����� ������� (��������� ����� � ����������)

						�������� ������ �������:
						1. � ���� ������ ������� "����� ���" ������ ���� ������� `config`.
						   � ���� ������� ���������� ��� ������ `MoviesDir`, `SeriesDir` � `MusicDir`.
						   ��� ������ - ���� � ���������, � ������� ���������� ������������ ������.
-----------------------------------------------------------------------------------------------------------------------------------
						2. � ���� ������ ������� "����� ���" ��������� ������� `movies_files`, `movies_info` � `movies_meta`.
						   ��� ������� ��������� ������ ���� ��� ��������������.
						3. �� ���� ������� ������� `movies_files` ���� `filesize` ����������.
						   � ��� ��������� ��� ������������ ������, � ������� `movies_files` ������������ ����
						   `filesize`. ��� ������ ������� `movies_files`, � ������� ����� `filesize` �������� �����
						   ���� �������� ���������� � ����� � ��������� �� �������.
						4. ��� ��������� ��� ������������ ����� ������������� �� ����� �����. � ��� �������� �������
						   ��������, ������������ �������� � ��� ������� ��� ������ ����������� � �������������� ����
						   ������� `movies_files`.
						   ����� ������ ����� ����� ���: "{������� ��������} ({������������ ��������}) - {���}.{����������}'
						   ���� ����� ������� � �� ����� ������������ ��������, ��� ���� ������� �������� ���������
						   � ������������, �� � ������� ��� ������ �� �����������.
						5. �� ������� `config` ������� �������� ������� `ServerDLNA` � `PortDLNA`.
						   �� ���������� ������ � ����� ����������� ������ �������� HTML-�������� � ����������� �������.
						   ��� ���������� �� �������� ���� ������, �������������� ������� � ������� `movies_files`,
						   � ��������������� ������ � ���� ���� `dlna_id` ����������� ������������� ������� ������������,
						   � ����� ������ ��������� �����, �������� ������ �����������, ������� ������ � �.�.
						6. �� ������������� ����� ������ ������������ ��� ����� � ���� ������ ����� themoviedb.org,
						   � �������������� API �����, ����� GET-�������. ��� ������ ���� ������� �� ������� `config`
						   ������� �������� ������ `TMDB_API_Key`, ������� ������������ � �������� ����� `API_Key` �� �����
						   themoviedb.org. ���� ����� ����� �������������� ��������, ������������������� �� �������� �����
						   � ������� �� ������: `https://www.themoviedb.org/settings/api`.
						   ��������� �������������� ���������� � �������������� ���� `tmdb_id` ������� `movies_files`.

    Versions.......:	0.0.1.5 (18.09.2017) - ������ ��������� ���������� ������ (��������� ���������� � ����� kinopoisk.ru)
						0.0.2.0 (08.02.2018) - ������ ��������� ��� ��������� ���������� � ������� � ����� movielib.ru
						0.0.2.2 (05.04.2018) - ������ ��������� ��� ��������� ���������� � ������� � ����� themoviedb.org
						0.2.0.0 (02.05.2019) - ��������� ������������� ��� ������ ������� 2.0.0 � ������ ��������
#CE
#EndRegion Header

#Region Initialization
#pragma compile(ProductName, Smart Home Server - Multimedia Database Utility)
#pragma compile(FileVersion, 0.2.0.0)
#pragma compile(LegalCopyright, (c) 2017 Aleksandr Prilutskiy)
#pragma compile(Out, ..\bin\utils\multimedia.exe)
#pragma compile(Icon, ..\resources\icons\multimedia.ico)
#pragma compile(x64, false)
#pragma compile(UPX, false)
#pragma compile(Console, true)
#include <GDIPlus.au3>
#include <InetConstants.au3>
#include <UDFs\JSON.au3>
#include <UDFs\SmartHomeFramework.au3>
Opt("TrayIconHide", 1)

Global Enum _
 $_GENRES_NAME, _
 $_GENRES_DATA, _
 $_GENRES_COUNT

; ��������� ���������� ����������
		$sAppShortName			= 'Multimedia Database Utility'			; ������� �������� ���������

; ������ ����������, ������������ � ����������
Global  $sServerURL				= ''									; URL ������� Web-���������� DLNA-�������
Global	$sWebServerDir			= ''									; ������� ���������� web-�������� �������
Global  $sAPIKey				= ''									; ���� API_Key �� ����� themoviedb.org
Global	$sMoviesIconsDir		= 'images\movies\'						; ������� ����������� � ��������� �������
Global	$iMoviesIconsWidth		= 360									; ������ ����������� ������� �� �����������
Global	$iMoviesIconsHeight		= 510									; ������ ����������� ������� �� ���������
Global	$iMoviesOfDayNumber		= 6										; ���������� '������� ���'
Dim		$aSaveMoviesOfDay[$iMoviesOfDayNumber]							; ������ ���������� ���������� '������� ���'
Dim		$aMoviesDirs[1]			= [0]									; ������ ��������� ������ ������ �������
Global	$iErrorCount			= 0										; ������� ������
Global	$fClearDatabase			= False									; ������� ������ ������� ��� ������
Global	$iErrorCount			= 0										; ������� ������
Global	$iTotalFiles			= 0										; ����� ������� ������
Global	$iFilesCount			= 0										; ������� ������� �������� � �������

Global	$iChangeCount			= 0										; ���-�� ���������� ������� � ���� ������
Global	$sDebugResultOfSearch	= ''									; ��������� �������� �������� ������
Global	$sErrorsChars			= ''									; ����������� ������� � ����� �������
Global	$fClearDatabase			= False									; ������� ������ ������� ��� ������
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
 If ($CmdLine[0] > 0) And ($CmdLine[1] == "/?") Then _
  Return _LogWrite("������� '����� ���'. ������ ������������ ���� ������ �������, ����������� �� �������." & _
          @CRLF & "��������� ��������� ������:" & @CRLF & _
          "multimedia.exe [update] {/clear} {/debug}" & @CRLF & _
		  " update - ���������� ������ ������� � ���� ������" & @CRLF & _
		  " /clear - ������� ���� ������ � ����������� � ������� � ���� ������" & @CRLF & _
		  " /debug - ����� ������� (��������� ����� � ����������)")
 Local $i, $sCommand = $CmdLine[0] > 0 ? $CmdLine[1] : ''
 For $i = 2 To $CmdLine[0]
  If $CmdLine[$i] == '/clear' Then $fClearDatabase = True
 Next
 Switch $sCommand
  Case "update"
   _ReadServerConfig()			; ������ �������� ������� "����� ���"
   _CreateDatabaseTables()		; �������� ����������� ������ � ���� ������
   _ScanMoviesFiles()			; ����� ������� � ��������� � ���������� �� � ���� ������
   _ScanDLNA()					; ��������� DLNA-��������������� �������� ��� ���� ������
   _ScanTMDB()					; ��������� ID ������� � ����� themoviedb.org
   _LoadMoviesImages()			; �������� �������� ����������� �������
   _CreateMetadata()			; ������������� ����������, ��������� � ��������
   _CheckErrors()				; �������� �� ������
  Case Else
   _LogWrite(" ������ � ���������� �������." & @CRLF & " ����������� 'multimedia.exe /?'")
 EndSwitch
EndFunc ;==>_CheckCommandLine
#EndRegion _Main

#Region Read Config
;-------------------------------------------- ������� �������� �������� ���������� ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ReadServerConfig
; Description....:	������ �������� ������� "����� ���" �� ���� ������.
; Syntax.........:	_ReadServerConfig()
; ===============================================================================================================
Func _ReadServerConfig()
 Local $i, $sDir
 Local $sServerDLNA = _MySQL_ReadConfig('ServerDLNA')
 Local $sPortDLNA = _MySQL_ReadConfig('PortDLNA')
 $sServerURL = 'http://' & $sServerDLNA & (StringLen($sPortDLNA) > 0 ? ':' & $sPortDLNA : '')
 $sWebServerDir	= _MySQL_ReadConfig('WebServerDir')
 $sAPIKey		= _MySQL_ReadConfig('TMDB_API_Key')
 Local $Query = _MySQL_Query("SELECT data FROM `" & $sDB_TableConfig & "` WHERE name = 'MoviesDir';")
 If IsObj($Query) Then
  While Not $Query.EOF
   $sDir = $Query.Fields(0).value
   If StringLen($sDir) > 0 Then
    If StringRight($sDir, 1) <> "\" Then $sDir &= "\"
    If FileExists($sDir) Then
     $i = UBound($aMoviesDirs) + 1
     ReDim $aMoviesDirs[$i]
	 $aMoviesDirs[$i - 1] = $sDir
	 $aMoviesDirs[0] += 1
    EndIf
   EndIf
   $Query.MoveNext
  WEnd
 EndIf
 If (StringLen($sServerDLNA) == 0) Or (StringLen($sWebServerDir) == 0) Then
  _LogWrite(" ������ ��������� ���������� DLNA �������" & @CRLF & _
		    " ��������� ������ 'ServerDLNA', 'PortDLNA' � 'WebServerDir' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "������ ���������� DLNA �������")
  _AppExit()
 EndIf
 If StringLen($sAPIKey) == 0 Then
  _LogWrite(" ������ ��������� ����� TMDB API_Key" & @CRLF & _
            " ��������� ������ 'TMDB_API_Key' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "������ ����� TMDB API_Key")
  _AppExit()
 EndIf
 If UBound($aMoviesDirs) == 1 Then
  _LogWrite(" ������ ��������� ������ ��������� ������������ �������" & @CRLF & _
            " ��������� ������ 'MoviesDir' � ������� '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "������ ��������� ������������")
  _AppExit()
 EndIf
 If $DEBUG Then
  _LogWrite("���� �������� ��������� ��������� ������� '����� ���':" & @CRLF & _
			" ServerURL    = " & $sServerURL & @CRLF & _
			" WebServerDir = " & $sWebServerDir & @CRLF & _
			" TMDB API_Key = " & $sAPIKey & @CRLF & _
			" MoviesDir    = [" & _ArrayToString($aMoviesDirs, ', ', 1) & "]" & @CRLF)
 EndIf
 _LogWrite("�������� ���������� '������� ���'...")
 For $i = 0 To UBound($aSaveMoviesOfDay) - 1
  $aSaveMoviesOfDay[$i] = 0
 Next
 $i = 0
 $Query = _MySQL_Query("SELECT value FROM `" & $sDB_TableMoviesMetadata & "` WHERE type = 'movie_of_day';")
 If IsObj($Query) Then
  While Not $Query.EOF
   $aSaveMoviesOfDay[$i] = $Query.Fields(0).value
   $Query.MoveNext
   $i += 1
   if $i >= UBound($aSaveMoviesOfDay) Then ExitLoop
  WEnd
 EndIf
 _LogWrite(" ��������� ������� � �������: " & $i & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region MySQL Functions
;-------------------------------------------- ������� ������ � ����� ������ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateDatabaseTables
; Description....:	�������� � ���� ������ ������ � ����������� � �������, ����������� �� �������.
; Syntax.........:	_CreateDatabaseTables()
; ===============================================================================================================
Func _CreateDatabaseTables()
 _LogWrite("�������� ������ � ���� ������...")
 If $fClearDatabase Then _LogWrite(" ��� ������� ������� � ����� ������� ������")
 If _MySQL_CheckTable($sDB_TableMoviesFiles) Then ; $sDB_TableMoviesFiles
  If $fClearDatabase Then
   _MySQL_DropTable($sDB_TableMoviesFiles)
  Else
   _LogWrite(" ������� ������� '" & $sDB_TableMoviesFiles & "'")
  EndIf
 EndIf
 If Not _MySQL_CheckTable($sDB_TableMoviesFiles) Then
  _MySQL_Query("CREATE TABLE `" & $sDB_TableMoviesFiles & "` (" & _
   "id INT UNSIGNED NOT NULL AUTO_INCREMENT, " & _ ; id �����
   "dlna_id TEXT NOT NULL, " & _			; id ������� � ���� ������ ������������
   "name TEXT, " & _						; ������������ �������� ������
   "name_rus TEXT, " & _					; ������� �������� ������
   "year TEXT, " & _						; ��� ������� ������
   "tmdb_id INT UNSIGNED DEFAULT 0, " & _	; id ������ �� ����� themoviedb.org
   "filename TEXT, " & _	 				; ��� ����� �� �������
   "filesize INT UNSIGNED, " & _			; ������ �����
   "filetype TEXT, " & _	 				; ���������� (���) �����
   "duration INT UNSIGNED DEFAULT 0, " & _	; ������������ ������ � ��������
   "resolution TEXT, " & _	 				; ���������� �����������
   "fps FLOAT, " & _						; ������� ������
   "videocodec TEXT, " & _	 				; �������� ������ �����������
   "audiocodec TEXT, " & _	 				; �������� ������ �������� �������
   "audiochannels TINYINT UNSIGNED, " & _	; ���������� ������� �����
   "added DATE, " & _						; ���� ���������� ������
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" ������� ������� '" & $sDB_TableMoviesFiles & "'")
  Else
   _LogWrite(" ������: ���������� ������� ������� '" & $sDB_TableMoviesFiles & "'")
   _SysyemLogWrite(0, 1, "������ ���� ������")
   _AppExit()
  EndIf
 EndIf
 If _MySQL_CheckTable($sDB_TableMoviesInfo) Then ; $sDB_TableMoviesInfo
  If $fClearDatabase Then
   _MySQL_DropTable($sDB_TableMoviesInfo)
  Else
   _LogWrite(" ������� ������� '" & $sDB_TableMoviesInfo & "'")
  EndIf
 EndIf
 If Not _MySQL_CheckTable($sDB_TableMoviesInfo) Then
  _MySQL_Query("CREATE TABLE `" & $sDB_TableMoviesInfo & "` (" & _
   "id INT UNSIGNED NOT NULL, " & _			; id ������ �� ����� movielib.ru
   "name TEXT, " & _						; ������������ �������� ������
   "name_rus TEXT, " & _					; ������� �������� ������
   "year TEXT, " & _						; ��� ������� ������
   "time INT UNSIGNED, " & _				; ����������������� ������
   "genre TEXT, " & _						; ���� ������
   "country TEXT, " & _						; ����� ������������ ������
   "description TEXT, " & _					; �������� ������
   "director TEXT, " & _					; �������� ������
   "actors TEXT, " & _						; ������ � ������� ����� ������
   "poster TEXT," & _						; ������ �� ������ � ������
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" ������� ������� '" & $sDB_TableMoviesInfo & "'")
  Else
   _LogWrite(" ������: ���������� ������� ������� '" & $sDB_TableMoviesInfo & "'")
   _SysyemLogWrite(0, 1, "������ ���� ������")
   _AppExit()
  EndIf
 EndIf
 If _MySQL_CheckTable($sDB_TableMoviesCollections) Then ; $sDB_TableMoviesCollections
  If $fClearDatabase Then
   _MySQL_DropTable($sDB_TableMoviesCollections)
  Else
   _LogWrite(" ������� ������� '" & $sDB_TableMoviesCollections & "'")
  EndIf
 EndIf
 If Not _MySQL_CheckTable($sDB_TableMoviesCollections) Then
  _MySQL_Query("CREATE TABLE `" & $sDB_TableMoviesCollections & "` (" & _
   "id INT UNSIGNED NOT NULL, " & _			; id �������� �� ����� movielib.ru
   "name TEXT, " & _						; �������� ��������� �������
   "poster TEXT," & _						; ������ �� ������ � ��������� �������
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" ������� ������� '" & $sDB_TableMoviesCollections & "'")
  Else
   _LogWrite(" ������: ���������� ������� ������� '" & $sDB_TableMoviesCollections & "'")
   _SysyemLogWrite(0, 1, "������ ���� ������")
   _AppExit()
  EndIf
 EndIf
 If _MySQL_CheckTable($sDB_TableMoviesMetadata) Then ; $sDB_TableMoviesMetadata
  If $fClearDatabase Then
   _MySQL_DropTable($sDB_TableMoviesMetadata)
  Else
   _LogWrite(" ������� ������� '" & $sDB_TableMoviesMetadata & "'")
  EndIf
 EndIf
 If Not _MySQL_CheckTable($sDB_TableMoviesMetadata) Then
  _MySQL_Query("CREATE TABLE `" & $sDB_TableMoviesMetadata & "` (" & _
   "id INT UNSIGNED NOT NULL AUTO_INCREMENT, " & _ ; id ������
   "type TEXT, " & _						; ��� ������
   "value TEXT, " & _						; �������� ������
   "data INT, " & _							; �������������� ��������
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" ������� ������� '" & $sDB_TableMoviesMetadata & "'")
  Else
   _LogWrite(" ������: ���������� ������� ������� '" & $sDB_TableMoviesMetadata & "'")
   _SysyemLogWrite(0, 1, "������ ���� ������")
   _AppExit()
  EndIf
 EndIf
 _LogWrite()
EndFunc ;==>_CreateDatabaseTables
#EndRegion MySQL Functions

#Region Files Functions
;------------------------------------------- ������� ������������ ��������� -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ScanMoviesFiles
; Description....:	������������ ��������� � ����� � ��� ������ � ��������.
; Syntax.........:	_ScanMoviesFiles()
; Remarks .......:	��������� ������ ������� - ��������� ���������� ������� $sDB_TableMoviesFiles.
;					������ ��������� ������� �� ���������� ����������-������� $aMoviesDirs.
;					������ ������� ������� $aMoviesDirs �������� ���������� ��������� � ������� � �����������.
;					����� ������������� �� ���� ������� ������� `movies_files` ���� `filesize` ����������.
;					���� ��������� ����, ����� ����������� � ������� `movies_files`, � ���� ������������ ����
;					`filesize`. ���� ������ � ����� ������ �� ������� - ��� ����� ��������� � ��������� ����
;					`filesize`. ����� ������������ ���� ���������, ��� ������ � ������� `movies_files` � �������
;					���� `filesize` ����� ���� ������������ ������, ��������� � ����� � ��������� �� �������.
; ===============================================================================================================
Func _ScanMoviesFiles()
 Local $i, $Timer = TimerInit()
 Local $iStartCount = _MySQL_GetCount($sDB_TableMoviesFiles, "id")
 _MySQL_Query("UPDATE `" & $sDB_TableMoviesFiles & "` SET filesize = 0;")
 For $i = 1 To UBound($aMoviesDirs) - 1
  _LogWrite("������������ �������� '" & $aMoviesDirs[$i] & "'...")
  _RecursiveScanDir($sDB_TableMoviesFiles, $aMoviesDirs[$i], _StringExplode(".mkv,.avi", ","))
 Next
 _LogWrite(" ����� ������� ������: " & $iTotalFiles)
 Local $iSearchCount = _MySQL_GetCount($sDB_TableMoviesFiles, "id")
 If $iSearchCount > $iStartCount Then _
  _LogWrite(" ��������� ���������� � ����� ������: " & $iSearchCount - $iStartCount)
 _MySQL_Query("DELETE FROM `" & $sDB_TableMoviesFiles & "` WHERE filesize = 0;")
 Local $iDelCount = _MySQL_GetCount($sDB_TableMoviesFiles, "id")
 If $iDelCount < $iSearchCount Then _
  _LogWrite(" ������� ���������� � ����� ���������������� ������: " & $iSearchCount - $iDelCount)
 _LogWrite(" ��������� �������: " & Round(TimerDiff($Timer) / 1000, 3) & " ���." & @CRLF)
EndFunc ;==>_ScanMoviesFiles

; #FUNCTION# ====================================================================================================
; Name...........:	_RecursiveScanDir
; Description....:	����������� ������������ ���������.
; Syntax.........:	_RecursiveScanDir($sTableName, $sDir, $aExt)
; Parameter(s)...:	$sTableName - ��� ������� � ���� ������, � ������� ����� ��������� ��������� �����
;					$sDir		- ������� ������������.
;					$aExt		- ������ ���������� ������� ������.
; ===============================================================================================================
Func _RecursiveScanDir($sTableName, $sDir, $aExt)
 Local $Query, $i
 Local $hSearch = FileFindFirstFile($sDir & "*.*")
 If $hSearch = -1 Then Return
 While True
  Local $sFileName = FileFindNextFile($hSearch)
  If @error Then ExitLoop
  Local $sFileFullName = $sDir & $sFileName
  If StringInStr(FileGetAttrib($sFileFullName), "D") > 0 Then
   _RecursiveScanDir($sTableName, $sFileFullName & "\", $aExt)
  Else
   Local $sFixFullFileName = _MySQL_StringCode($sFileFullName)
   For $i = 0 To UBound($aExt) - 1
    If StringLower(StringRight($sFileName, StringLen($aExt[$i]))) == $aExt[$i] Then
     If _MySQL_GetCount($sTableName, "id", "WHERE filename = '" & $sFixFullFileName & "'") > 0 Then
      _MySQL_Query("UPDATE `" & $sTableName & "` SET filesize = " & FileGetSize($sFileFullName) & _
	               " WHERE filename ='" & $sFixFullFileName & "';")
	 Else
      $sExt = $aExt[$i]
      If StringLeft($sExt, 1) == "." Then $sExt = StringTrimLeft($sExt, 1)
      Local $sMovieName = ""
	  Local $sMovieNameRus = ""
      Local $sMovieYear = ""
      Local $s = $sFileFullName
      Local $pos = StringInStr($s, "\", 0, -1)
      If $pos > 0 Then $s = StringTrimLeft($s, $pos)
      $pos = StringInStr($s, ".", 0, -1)
      If $pos > 0 Then $s = StringLeft($s, $pos - 1)
      $pos = StringInStr($s, " - ", 0, -1)
	  If $pos == 0 Then
       _LogWrite(" ������: � ����� �����: '" & $sFileFullName & "' ���������� �������� ���.")
       $iErrorCount += 1
	   ContinueLoop
	  EndIf
      $sMovieYear = Number(StringTrimLeft($s, $pos + 2))
      $s = StringLeft($s, $pos - 1)
      $sMovieNameRus = $s
      $pos = StringInStr($s, " (")
	  If ($pos > 0) And (StringRight($s, 1) == ")")Then
	   $sMovieName = StringTrimRight(StringTrimLeft($s, $pos + 1), 1)
	   $sMovieNameRus = StringLeft($s, $pos - 1)
	  EndIf
	  If $sTableName == $sDB_TableMoviesFiles Then
       _MySQL_Query("INSERT INTO `" & $sDB_TableMoviesFiles & "` " & _
        "(name, name_rus, year, filename, filesize, filetype, added) VALUES (" & _
        "'" & _MySQL_StringCode($sMovieName) & "', " & _ 		; name
        "'" & _MySQL_StringCode($sMovieNameRus) & "', " & _		; name_rus
        "'" & _MySQL_StringCode($sMovieYear) & "', " & _ 		; year
        "'" & $sFixFullFileName & "', " & _						; filename
         "'" & FileGetSize($sFileFullName) & "', " & _			; filesize
        "'" & _MySQL_StringCode($sExt) & "', " & _				; filetype
        "CURDATE());")											; added
	  EndIf
      If @error Then
       _LogWrite(" ������:  ���������� �������� ������ � ����� '" & $sFileFullName & "'")
      Else
       If $DEBUG Then _LogWrite(" �������� ����: " & $sDir & $sFileName)
	  EndIf
     EndIf
     $iTotalFiles += 1
    EndIf
   Next
  EndIf
 WEnd
 FileClose($hSearch)
EndFunc ;==>_RecursiveScanDir
#EndRegion Files Functions

#Region DLNA Server Functions
;--------------------------------------- ������� ��� ������ � ������������� DLNA --------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ScanDLNA
; Description....:	��������� ���� ��������������� �������� ������������.
; Syntax.........:	_ScanDLNA()
; Remarks .......:	��������� ������ ������� - ��������� ���������� ������� 'movies_files' � ���� ������.
; ===============================================================================================================
Func _ScanDLNA()
 _LogWrite("������������ �������� �������� ������������...")
 $iFilesCount = 0
 Local $i, $Timer = TimerInit()
 Local $Query = _MySQL_Query("SELECT id, filename FROM `" & $sDB_TableMoviesFiles & "` WHERE dlna_id IS NULL;")
 If IsObj($Query) Then
  While Not $Query.EOF
   Local $iFileID		 = $Query.Fields(0).value
   Local $sFileName		 = $Query.Fields(1).value
   $Query.MoveNext
   _GetFileInfoDLNA($sDB_TableMoviesFiles, $iFileID, $sFileName)
  WEnd
 EndIf
 _LogWrite(" ��������� �������: " & Round(TimerDiff($Timer) / 1000, 3) & " ���." & @CRLF)
EndFunc ;==>_ScanDLNA

Func _GetFileInfoDLNA($sTableName, $sID, $sFileName)
 Local $sURL = $sServerURL & '/MediaServer/Folders/0?find=' & _StringURLEncode($sFileName)
 Local $sHTML = BinaryToString(InetRead($sURL), $INET_FORCERELOAD)
 Local $jResponses = _JSONDecode($sHTML)
 If Not IsArray($jResponses) Then
  $iErrorCount += 1
  _LogWrite(" ������: ���������� �������� ���������� � �����: '" & $sFileName & "'")
  Return
 EndIf
;_ArrayDisplay($jResponses)
 Local $sDLNA = _GetDataFromJSON($jResponses, 'id')
 If StringLen($sDLNA) == 0 Then
  $iErrorCount += 1
  _LogWrite(" ������: �� �������� �������� DLNA ID ��� �����: '" & $sFileName & "'")
  Return
 EndIf
 Local $sResolution = _GetDataFromJSON($jResponses, '3d')
 If StringLen($sResolution) > 0 Then $sResolution = '[3D]'
 $sResolution = _GetDataFromJSON($jResponses, 'width') & 'x' & _GetDataFromJSON($jResponses, 'height') & $sResolution
 If $sTableName == $sDB_TableMoviesFiles Then
  _MySQL_Query("UPDATE `" & $sTableName & "` SET " & _
   "dlna_id = '" & $sDLNA & "', " & _
   "duration = '" & _GetDuration(_GetDataFromJSON($jResponses, 'duration')) & "', " & _
   "resolution = '" & $sResolution & "', " & _
   "fps = '" & _GetDataFromJSON($jResponses, 'fps') & "', " & _
   "videocodec = '" & _GetDataFromJSON($jResponses, 'videocodec') & "', " & _
   "audiocodec = '" & _GetDataFromJSON($jResponses, 'audiocodec') & "', " & _
   "audiochannels = '" & Number(_GetDataFromJSON($jResponses, 'channels')) & "' " & _
   "WHERE id = " & $sID & ";")
 EndIf
 If @error Then
  $iErrorCount += 1
  _LogWrite(" ������: ���������� �������� ���������� � ������: '" & $sFileName & "'")
 EndIf
EndFunc ;==>_GetFileInfoDLNA

; #FUNCTION# ====================================================================================================
; Name...........:	_GetDuration
; Description....:	��������� �������� ������������ ���������� � �������� �� ���������� �������
; Syntax.........:	_GetDuration($sStr)
; Parameters.....:	$sStr		- �������� �����
; Return Value(s):  On Success	- ����� � ��������, ����������� �� ������
;                   On Failure	- 0.
; Remarks .......:	������ ����: HH:MM:SS.xxx, ���: �� - ����, MM - ������, SS - �������, xxx - ���� ������.
; ===============================================================================================================
Func _GetDuration($sStr)
 If StringLen($sStr) == 0 Then Return 0
 Local $aDuration = StringSplit($sStr, ':')
 If $aDuration[0] <> 3 Then Return 0
 Return Round(3600 * Number($aDuration[1]) + 60 * Number($aDuration[2]) + Number($aDuration[3]))
EndFunc ;==>_GetDuration

; #FUNCTION# ====================================================================================================
; Name...........:	_GetDataFromJSON
; Description....:	��������� �������� ������������ ������ � ������� ��������� JSON
; Syntax.........:	_GetDataFromJSON($aJSON, $sKeyStr)
; Parameter(s)...:	$aJSON			- ������ ������� � ������� JSON
;					$sKeyStr		- ������ ��� ������
; Return values .: 	Success:	�������� ���������, �������������� ����� ������
;					Failure:	������ ������
; ===============================================================================================================
Func _GetDataFromJSON(ByRef $aJSON, $sKeyStr)
 Local $n = _ArraySearch($aJSON, $sKeyStr, 0, 0, 1, 0, 1, 0)
 If $n < 0 Then Return ''
 Return $aJSON[$n][1]
EndFunc ;==>_GetDataFromJSON
#EndRegion DLNA Server Functions

#Region Internet Movies Info Functions
; #FUNCTION# ====================================================================================================
; Name...........:	_ScanTMDB
; Description....:	��������� ��������������� ����� ����������� ������� �� ����� themoviedb.org.
; Syntax.........:	_GetNewMoviesTMDB_ID()
; Remarks .......:	��������� ������ ������� - ���������� ������ ����� tmdb_id � ������� 'movies_files'.
; ===============================================================================================================
Func _ScanTMDB()
 Local $i, $j, $Timer = TimerInit()
 Local $iSaveErrorCount = $iErrorCount
 $iFilesCount = 0
 _LogWrite("��������� ��������������� ������� �� ����� themoviedb.org...")
 Local $Query = _MySQL_Query("SELECT id, name, name_rus, year, filename FROM `" & $sDB_TableMoviesFiles & _
  "` WHERE tmdb_id = 0;")
 If IsObj($Query) Then
  While Not $Query.EOF
   Local $iFileID		 = $Query.Fields(0).value
   Local $sMovieName	 = $Query.Fields(1).value
   Local $sMovieNameRus	 = $Query.Fields(2).value
   Local $sMovieYear	 = $Query.Fields(3).value
   Local $sFileName		 = $Query.Fields(4).value
   Local $sMovieNameFull = $sMovieNameRus & _
    (StringLen($sMovieName) > 0 ? ' (' & $sMovieName & ')' : '') & ' - ' & $sMovieYear
   Local $sURL = "https://api.themoviedb.org/3/search/movie?api_key=" & $sAPIKey & "&language=" & _
    "ru-RU&include_adult=false&query=" & _StringToUTF8($sMovieName == '' ? $sMovieNameRus : $sMovieName)
   Local $iTMDB_ID = 0
   $Query.MoveNext
   $sDebugResultOfSearch = ''
   Local $sJSON = BinaryToString(InetRead($sURL), $INET_FORCERELOAD)
   $jResponses = _JSONDecode(BinaryToString(StringToBinary($sJSON), 4))
   If IsArray($jResponses) Then
    For $i = 0 To UBound($jResponses, 1) - 1
     If $jResponses[$i][0] <> "results" Then ContinueLoop
     If Not IsArray($jResponses[$i][1]) Then Return 0
     Local $aResults = $jResponses[$i][1]
     For $j = 0 To UBound($aResults) - 1
      Local $iTMDBID			= Number(_GetDataFromJSON($aResults[$j], 'id'))
      Local $sTMDBTitle			= _GetDataFromJSON($aResults[$j], 'title')
      Local $sTMDBOriginalName	= _GetDataFromJSON($aResults[$j], 'original_title')
      Local $sTMDBYear			= StringLeft(_GetDataFromJSON($aResults[$j], 'release_date'), 4)
      If $sMovieName == '' Then $sTMDBOriginalName = ''
      Local $sResultMovieName = $sTMDBTitle & _
	   (StringLen($sTMDBOriginalName) > 0 ? ' (' & $sTMDBOriginalName & ')' : '') & ' - ' & $sTMDBYear
      If _StringMovieNameFix($sResultMovieName) == _StringMovieNameFix($sMovieNameFull) Then _
	   $iTMDB_ID = $iTMDBID
      $sDebugResultOfSearch &= "  > '" & $sResultMovieName & "'" & @CRLF
     Next
     ExitLoop
    Next
   EndIf
   If $iTMDB_ID == 0 Then
    If $DEBUG Then
     _LogWrite(" �� ������ ������������� TMDB ��� ������ '" & $sFileName & "'")
     If StringLen($sDebugResultOfSearch) > 0 Then
      _LogWrite(' -> ���������� ������:' & @CRLF & $sDebugResultOfSearch)
     EndIf
    Else
	 _LogWrite(" �� ������ ������������� TMDB ��� ������ '" & $sFileName & "'")
    EndIf
    ContinueLoop
   EndIf
   _MySQL_Query("UPDATE `" & $sDB_TableMoviesFiles & "` SET " & _
     "tmdb_id = " & $iTMDB_ID & " WHERE id = " & $iFileID & ";")
   If @error Then
    _LogWrite(" ������: ���������� �������� ���������� � ������: '" & $sFileName & "'")
    $iErrorCount += 1
   Else
    If $DEBUG Then _LogWrite(" �������� ������������� #" & $iTMDB_ID & " ��� ������: '" & $sFileName & "'")
    $iFilesCount += 1
   EndIf
   _GetMovieTMDB_Info($iTMDB_ID)
  WEnd
 EndIf
 If $DEBUG And (StringLen($sErrorsChars) > 0) Then
  Local $s = ''
  For $i = 1 To StringLen($sErrorsChars)
   Local $sChar = StringMid($sErrorsChars, $i, 1)
   $s &= $sChar & '(' & StringToBinary($sChar, 4) & ') '
  Next
  _LogWrite(@CRLF & ' �� ����� ������ ���� ���������� �������������� �������: ' &  @CRLF & $s & @CRLF)
 EndIf
 _LogWrite(" ������� ��������������� �������: " & $iFilesCount & @CRLF & _
  " ����� ������ ��� ������: " & $iErrorCount - $iSaveErrorCount & @CRLF & _
  " ��������� �������: " & Round(TimerDiff($Timer) / 1000, 3) & " ���." & @CRLF)
EndFunc ;==>_ScanTMDB

; #FUNCTION# ====================================================================================================
; Name...........:	_GetMovieTMDB_Info
; Description....:	��������� ���������� � �������, ������������ � ���� ������ � ����� themoviedb.org
; Syntax.........:	_GetMovieTMDB_Info($iMovieID)
; ===============================================================================================================
Func _GetMovieTMDB_Info($iMovieID)
 If _MySQL_GetCount($sDB_TableMoviesInfo, "id", "WHERE id = " & $iMovieID) > 0 Then Return
 Local $sMovieName		= ""
 Local $sMovieDirector	= ""
 Local $sMovieActors		= ""
 Local $sURL = "https://api.themoviedb.org/3/movie/" & $iMovieID & "?api_key=" & $sAPIKey & "&language=ru-RU"
 Local $sJSON = BinaryToString(InetRead($sURL, $INET_FORCERELOAD), 4)
 $jResponses = _JSONDecode($sJSON)
 If IsArray($jResponses) Then
  $sMovieName				= _StringToUTF8_X(_GetDataFromJSON($jResponses, 'original_title'))
  Local $sMovieNameRus	 	= _StringToUTF8_X(_GetDataFromJSON($jResponses, 'title'))
  Local $sMovieYear		 	= StringLeft(_GetDataFromJSON($jResponses, 'release_date'), 4)
  Local $sMovieTime		 	= Number(_GetDataFromJSON($jResponses, 'runtime'))
  Local $sMovieGenre		= _GetArrayFromJSON(_GetDataFromJSON($jResponses, 'genres'), 'name')
  Local $sMovieCountry	 	= _GetArrayFromJSON(_GetDataFromJSON($jResponses, 'production_countries'), 'name')
  Local $sMovieDescription	= _StringToUTF8_X(_GetDataFromJSON($jResponses, 'overview'))
  Local $sMoviePoster		= _GetDataFromJSON($jResponses, 'poster_path')
  If StringLen($sMoviePoster) > 0 Then _
   $sMoviePoster			= "https://image.tmdb.org/t/p/w300_and_h450_bestv2" & $sMoviePoster
  _AddMoviesCollection(_GetDataFromJSON($jResponses, 'belongs_to_collection'))
 EndIf
 If $sMovieName == "" Then
  If $DEBUG Then _LogWrite(" ������. ���������� �������� ���������� � ������ #" & $iMovieID)
  $iErrorCount += 1
  Return
 EndIf
 $sURL = "https://api.themoviedb.org/3/movie/" & $iMovieID & "/credits?api_key=" & $sAPIKey
 $sJSON = BinaryToString(InetRead($sURL, $INET_FORCERELOAD), 4)
 $jResponses = _JSONDecode($sJSON)
 If IsArray($jResponses) Then
  $sMovieActors		 	= _StringToUTF8_X(_GetArrayFromJSON(_GetDataFromJSON($jResponses, 'cast'), 'name'))
  $sMovieDirector		= _StringToUTF8_X(_GetArrayFromJSON( _
						   _GetDataFromJSON($jResponses, 'crew'), 'name', 'job', 'Director'))
 EndIf
 Local $sMovieNameFull = $sMovieNameRus & _
  (StringLen($sMovieName) > 0 ? ' (' & $sMovieName & ')' : '') & ' - ' & $sMovieYear
 _MySQL_Query("INSERT INTO `" & $sDB_TableMoviesInfo & "` (id, name, name_rus, year, time, genre, " & _
  "country, description, director, actors, poster) VALUES (" & _
	    $iMovieID & ", " & _											; id
  "'" & _MySQL_StringCode($sMovieName) & "', " & _						; name
  "'" & _MySQL_StringCode($sMovieNameRus) & "', " & _					; name_rus
  "'" & _MySQL_StringCode($sMovieYear) & "', " & _						; year
        $sMovieTime & ", " & _											; time
  "'" & _MySQL_StringCode($sMovieGenre) & "', " & _						; genre
  "'" & _MySQL_StringCode($sMovieCountry) & "', " & _					; country
  "'" & _MySQL_StringCode($sMovieDescription) & "', " & _				; description
  "'" & _MySQL_StringCode($sMovieDirector) & "', " & _					; director
  "'" & _MySQL_StringCode($sMovieActors) & "', " & _					; actors
  "'" & _MySQL_StringCode($sMoviePoster) & "');")						; poster
 If @error Then
  _LogWrite(" ������: ���������� �������� ���������� � ������: '" & $sMovieNameFull & "'")
  $iErrorCount += 1
 Else
  If $DEBUG Then _LogWrite(" ��������� ���������� � ������: '" & $sMovieNameFull & "' #" & $iMovieID)
  $iFilesCount += 1
 EndIf
EndFunc ;==>_GetMovieTMDB_Info

; #FUNCTION# ====================================================================================================
; Name...........:	_AddMoviesCollection
; Description....:	���������� � ���� ������ ���������� � ��������� ������� � ����� themoviedb.org
; Syntax.........:	_AddMoviesCollection($iMovieID, $jResponses)
; Remarks .......:	��������� ������ ������� - ���������� ������ 'movies_collections' � 'movies_metadata'
; ===============================================================================================================
Func _AddMoviesCollection($jResponses)
 Local $i
 If Not IsArray($jResponses) Then Return
; _ArrayDisplay($jResponses)
 Local $iID		= 0
 Local $sName	= ''
 Local $sPoster	= ''
 For $i = 0 To UBound($jResponses) - 1
  If $jResponses[$i][0] = "id"			Then $iID = Number($jResponses[$i][1])
  If $jResponses[$i][0] = "name"		Then $sName = $jResponses[$i][1]
  If $jResponses[$i][0] = "poster_path"	Then _
   $sPoster = "https://image.tmdb.org/t/p/w300_and_h450_bestv2" & $jResponses[$i][1]
 Next
 If ($iID == 0) Or (StringLen($sName) == 0) Then Return
 If _MySQL_GetCount($sDB_TableMoviesCollections, 'id', "WHERE id = '" & $iID & "'") == 0 Then _
  _MySQL_Query("INSERT INTO `" & $sDB_TableMoviesCollections & "` (id, name, poster) VALUES (" & _
   "'" & $iID & "', " & _													; id
   "'" & _MySQL_StringCode($sName) & "', " & _								; name
   "'" & _MySQL_StringCode($sPoster) & "');")								; poster

 Local $sURL = "https://api.themoviedb.org/3/collection/" & $iID & "?api_key=" & $sAPIKey & "&language=ru-RU"
 Local $sJSON = BinaryToString(InetRead($sURL, $INET_FORCERELOAD), 4)
 $jResponses = _JSONDecode($sJSON)
 If Not IsArray($jResponses) Then Return
 Local $aParts = _GetDataFromJSON($jResponses, 'parts')
 For $i = 0 To UBound($aParts) - 1
  Local $iMovieID = _GetDataFromJSON($aParts[$i], 'id')
  If $iMovieID == 0 Then ContinueLoop
  If _MySQL_GetCount($sDB_TableMoviesMetadata, 'value', "WHERE type = 'collection' AND " & _
   "value = '" & $iID & "' AND data = " & $iMovieID) == 0 Then _
   _MySQL_Query("INSERT INTO `" & $sDB_TableMoviesMetadata & "` (type, value, data) VALUES (" & _
    "'collection', " & _													; type
    "'" & $iID & "', " & _													; value
          $iMovieID & ");")													; data
 Next
EndFunc ;==>_AddMoviesCollection

; #FUNCTION# ====================================================================================================
; Name...........:	_LoadMoviesImages
; Description....:	�������� �� ��������� �������� ��� ����� ����������� �������
; Syntax.........:	_LoadMoviesImages()
; ===============================================================================================================
Func _LoadMoviesImages()
 Local $i = 0, $Timer = TimerInit()
 $iFilesCount = 0
 _LogWrite("�������� ����������� � ��������� ������� � ��������� �������...")
 If Not _CreateTempDir() Then
  _LogWrite(" ������: ���������� ������� ������� ��� ��������� ������")
  Return
 EndIf
 _GDIPlus_Startup()
 Local $sImgDir = $sWebServerDir & $sMoviesIconsDir
 Local $Query = _MySQL_Query("SELECT id, poster, name, name_rus, year FROM `" & $sDB_TableMoviesInfo & "`;")
 If IsObj($Query) Then
  While Not $Query.EOF
   Local $sMovieName		= $Query.Fields(2).value
   Local $sMovieNameFull = $Query.Fields(3).value & (StringLen($sMovieName) > 0 ? ' (' & $sMovieName & ')' _
    : '') & ' - ' & $Query.Fields(4).value
   Local $iResult = _LoadPosterImage($sImgDir, $Query.Fields(0).value, $Query.Fields(1).value)
   $Query.MoveNext
   If $iResult > 0 Then
    If $DEBUG Then _LogWrite(" �������� ������ � ������: '" & $sMovieNameFull & "'")
   ElseIf $iResult < 0 Then
    _LogWrite(" ������: ���������� ��������� ������ � ������: '" & $sMovieNameFull & "'")
   EndIf
  WEnd
 EndIf
 $sImgDir = $sWebServerDir & $sMoviesIconsDir & 'collections\'
 Local $Query = _MySQL_Query("SELECT id, poster, name FROM `" & $sDB_TableMoviesCollections & "`;")
 If IsObj($Query) Then
  While Not $Query.EOF
   Local $sCollectionsName = $Query.Fields(2).value
   Local $iResult = _LoadPosterImage($sImgDir, $Query.Fields(0).value, $Query.Fields(1).value)
   $Query.MoveNext
   If $iResult > 0 Then
    If $DEBUG Then _LogWrite(" �������� ������ � ��������� �������: '" & $sCollectionsName & "'")
   ElseIf $iResult < 0 Then
    _LogWrite(" ������: ���������� ��������� ������ � ��������� �������: '" & $sCollectionsName & "'")
   EndIf
  WEnd
 EndIf
 _GDIPlus_Shutdown()
 Local $iImagesCount = 0
 Local $hSearch = FileFindFirstFile($sWebServerDir & $sMoviesIconsDir & "*.*")
 If $hSearch = -1 Then Return
 While True
  Local $sFileName = FileFindNextFile($hSearch)
  If @error Then ExitLoop
  Local $sFileFullName = $sWebServerDir & $sMoviesIconsDir & $sFileName
  If StringInStr(FileGetAttrib($sFileFullName), "D") > 0 Then ContinueLoop
  If StringLower(StringRight($sFileName, 4)) == '.jpg' Then
   If _MySQL_GetCount($sDB_TableMoviesInfo, 'id', _
    "WHERE id = " & Number(StringTrimRight($sFileName, 4))) > 0 Then
	$iImagesCount += 1
	ContinueLoop
   EndIf
  EndIf
  FileDelete($sFileFullName)
  If FileExists($sFileFullName) Then _
   _LogWrite(" ������: �� ������� ������� ����: " & $sFileFullName)
 WEnd
 FileClose($hSearch)
 If $iFilesCount > 0 Then _
  _LogWrite(" ����� ��������� ������ � ������������� �������� � ������� � ���������� �������: " & $iFilesCount)
 _LogWrite(" � �������� '" & $sMoviesIconsDir & "' ���������� ������ � ��������� �����: " & $iImagesCount)
 _LogWrite(" ��������� �������: " & Round(TimerDiff($Timer) /  1000, 3) & " ���." & @CRLF)
EndFunc ;==>_LoadMoviesImages

; #FUNCTION# ====================================================================================================
; Name...........:	_LoadPosterImage
; Description....:	�������� ����������� ������� �� ���������
; Syntax.........:	_LoadPosterImage($sDir, $iID, $sPosterURL)
; Parameter(s)...:	$sDir			- �������, � ������� ����� ������� ����������� ����
;					$iID			- ID ������ ��� ���������
;					$sPosterURL		- URL ����������� � ���������, ������� ����� ���������
; Return Value(s):  0	- ��� ����� ������ (���������) ������ ��� ��� �������� �����
;                   1	- ������ ��� ������� ��������
;                   -1	- ������
; ===============================================================================================================
Func _LoadPosterImage($sDir, $iID, $sPosterURL)
 Local $sFileName =  $sDir & $iID & ".jpg"
 Local $sTempFile = $sAppTempDir & "\new_poster.jpg"
 If FileExists($sFileName) Then Return 0
 InetGet($sPosterURL, $sTempFile)
 If FileExists($sTempFile) Then
  Local $hImage = _GDIPlus_ImageLoadFromFile($sTempFile)
  Local $H = _GDIPlus_ImageGetHeight($hImage)
  Local $W = _GDIPlus_ImageGetWidth($hImage)
  Local $hImageScaled = _GDIPlus_ImageResize($hImage, $iMoviesIconsWidth, $iMoviesIconsHeight)
  _GDIPlus_ImageSaveToFile($hImageScaled, $sFileName)
  _GDIPlus_ImageDispose($hImage)
  _GDIPlus_ImageDispose($hImageScaled)
 EndIf
 If Not FileExists($sFileName) Then Return -1
 $iFilesCount += 1
 Return 1
EndFunc ;==>_LoadPosterImage

; #FUNCTION# ====================================================================================================
; Name...........:	_StringMovieNameFix
; Description....:  ��������� ������������ ������ � ������ ��� ���������
; Syntax.........:	_StringMovieNameFix($sString)
; Parameters.....:	$sString	- �������� ������
; Return values..:	��������������� ������
; ===============================================================================================================
Func _StringMovieNameFix($sString)
 Local $iPos = 3, $j, $sTxt = '', $bin = StringToBinary($sString, 4)
 While $iPos < StringLen($bin)
  Local $iByte = Dec(StringMid($bin, $iPos,  2))
  $iPos += 2
  Local $iCode = $iByte
  Local $iReadByte = 0
  If BitAND($iByte, 0xE0) == 0xC0 Then
   $iReadByte = 1
  ElseIf BitAND($iByte, 0xF0) == 0xE0 Then
   $iReadByte = 2
  ElseIf BitAND($iByte, 0xF8) == 0xF0 Then
   $iReadByte = 3
  EndIf
  For $j = 1 To $iReadByte
   $iCode = $iCode * 0x100 + Dec(StringMid($bin, $iPos,  2))
   $iPos += 2
  Next
  Switch $iCode
   Case 0x20, 0x3F, 0x2E, 0x2F, 0x5C, 0x3A
    ContinueLoop
   Case 0xCF
    $sTxt &= '-'
   Case 0x22, 0xC2AB, 0xC2BB
    $sTxt &= "'"
   Case 0xC2B3
    $sTxt &= '3'
   Case 0xC2B7
    $sTxt &= '-'
   Case 0xC380 To 0xC385
    $sTxt &= 'A'
   Case 0xC386
    $sTxt &= 'AE'
   Case 0xC387
    $sTxt &= 'C'
   Case 0xC388 To 0xC38B
    $sTxt &= 'E'
   Case 0xC38C To 0xC38F
    $sTxt &= 'I'
   Case 0xC390
    $sTxt &= 'D'
   Case 0xC391
    $sTxt &= 'N'
   Case 0xC392 To 0xC396
    $sTxt &= 'O'
   Case 0xC397
    $sTxt &= 'x'
   Case 0xC398, 0xC3B8
    $sTxt &= '0' ; ����
   Case 0xC399 To 0xC39C
    $sTxt &= 'U'
   Case 0xC39D
    $sTxt &= 'Y'
   Case 0xC39E
    $sTxt &= 'P'
   Case 0xC39F
    $sTxt &= 'B'
   Case 0xC3A0 To 0xC3A5
    $sTxt &= 'a'
   Case 0xC3A6
    $sTxt &= 'ae'
   Case 0xC3A7
    $sTxt &= 'c'
   Case 0xC3A8 To 0xC3AB
    $sTxt &= 'e'
   Case 0xC3AC To 0xC3AF
    $sTxt &= 'i'
   Case 0xC3B0
    $sTxt &= 'd'
   Case 0xC3B1
    $sTxt &= 'n'
   Case 0xC3B2 To 0xC3B6
    $sTxt &= 'o'
   Case 0xC3B7, 0xE28093
    $sTxt &= '-'
   Case 0xC3B9 To 0xC3BC
    $sTxt &= 'u'
   Case 0xC3BD, 0xC3BF
    $sTxt &= 'y'
   Case 0xC3BE
    $sTxt &= 'p'
   Case 0xC487
    $sTxt &= 'c'
   Case 0xC491
    $sTxt &= 'd'
   Case 0xD001
    $sTxt &= '�'
   Case 0xD191
    $sTxt &= '�'
   Case Else
	Local $sBinStr = Hex($iCode)
	While StringLeft($sBinStr, 2) == '00'
     $sBinStr = StringTrimLeft($sBinStr, 2)
    WEnd
    Local $sChar = BinaryToString(Binary('0x' & $sBinStr), 4)
    $sTxt &= $sChar
	If $DEBUG And ($iCode > 0x7F) And Not((($iCode >= 0xD090) And ($iCode <= 0xD0BF)) _
     Or (($iCode >= 0xD180) And ($iCode <= 0xD18F))) Then
	  If Not StringInStr($sErrorsChars, $sChar) Then $sErrorsChars &= $sChar
    EndIf
  EndSwitch
 WEnd
 Return $sTxt
EndFunc ;==>_StringMovieNameFix
#EndRegion Internet Movies Info Functions

#Region Metadata Functions
;---------------------------------------- ������� ��������� ���������� � ������� --------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateMetadata
; Description....:	�������� � ���������� ����������
; Syntax.........:	_CreateMetadata()
; ===============================================================================================================
Func _CreateMetadata()
Local $i, $Timer = TimerInit()
 _LogWrite("���������� ����������...")
 _LogWrite(" ���������� ������ ������:")
 Dim $aGenres[1][$_GENRES_COUNT] = [[0]]
 Local $Query = _MySQL_Query("SELECT genre FROM `" & $sDB_TableMoviesInfo & "`;")
 If IsObj($Query) Then
  While Not $Query.EOF
   $aMoviesGenres = _StringExplode($Query.Fields(0).value, ", ")
   $Query.MoveNext
   For $i = 0 To UBound($aMoviesGenres) - 1
    If ($aMoviesGenres[$i] == '') Or StringInStr($aMoviesGenres[$i], ' ') Then ContinueLoop
    Local $iGenre = _ArraySearch($aGenres, $aMoviesGenres[$i], 0, 0, 0, 0, 1, 0)
    If $iGenre <= 0 Then
     Local $n = UBound($aGenres)
     ReDim $aGenres[$n + 1][$_GENRES_COUNT]
     $aGenres[0][0] += 1
     $aGenres[$n][$_GENRES_NAME] = $aMoviesGenres[$i]
     $aGenres[$n][$_GENRES_DATA] = 1
    Else
     $aGenres[$iGenre][$_GENRES_DATA] += 1
    EndIf
   Next
  WEnd
 EndIf
 _MySQL_Query("DELETE FROM `" & $sDB_TableMoviesMetadata & "` WHERE type = 'genre';")
 For $i = 1 To UBound($aGenres, 1) - 1
  If $DEBUG Then _LogWrite(" > " & $aGenres[$i][$_GENRES_NAME] & " = " & $aGenres[$i][$_GENRES_DATA])
  _MySQL_Query("INSERT INTO `" & $sDB_TableMoviesMetadata & "` (type, value, data) VALUES (" & _
   "'genre', " & _															; type
   "'" & _MySQL_StringCode($aGenres[$i][$_GENRES_NAME]) & "', " & _			; value
	     $aGenres[$i][$_GENRES_DATA] & ");")								; data
 Next
 _LogWrite(" ����� '������� ���':")
 Dim $aMovies[1] = [0]
 Local $Query = _MySQL_Query("SELECT " & $sDB_TableMoviesInfo & ".id " & _
  "FROM `" & $sDB_TableMoviesInfo & "` LEFT JOIN `" & $sDB_TableMoviesFiles & "` " & _
  "ON " & $sDB_TableMoviesInfo & ".id = " & $sDB_TableMoviesFiles & ".tmdb_id " & _
  "WHERE " & $sDB_TableMoviesFiles & ".filename IS NOT NULL GROUP BY " & $sDB_TableMoviesInfo & ".id;")
 If IsObj($Query) Then
  While Not $Query.EOF
   Local $sTMDB_ID = $Query.Fields(0).value
   $Query.MoveNext
   If _ArraySearch($aSaveMoviesOfDay, $sTMDB_ID) > 0 Then ContinueLoop
   $i = UBound($aMovies)
   ReDim $aMovies[$i + 1]
   $aMovies[$i] = $sTMDB_ID
  WEnd
 EndIf
 _MySQL_Query("DELETE FROM `" & $sDB_TableMoviesMetadata & "` WHERE type = 'movie_of_day';")
 If UBound($aMovies) > $iMoviesOfDayNumber Then
  $i = 0
  Do
   Local $n = Random(1, UBound($aMovies) - 1, 1)
   If $aMovies[$n] == 0 Then ContinueLoop
   If $DEBUG Then _LogWrite(" > ������ ����� ��� #" & $aMovies[$n])
   _MySQL_Query("INSERT INTO `" & $sDB_TableMoviesMetadata & "` (type, value) VALUES (" & _
    "'movie_of_day', " & _													; type
    "'" & $aMovies[$n] & "');")												; value
   $aMovies[$n] = 0
   $i += 1
  Until $i >= $iMoviesOfDayNumber
 Else
  _LogWrite(" > � ������� '" & $sDB_TableMoviesInfo & "' ���������� ������� ���� �������")
 EndIf
 _LogWrite(" ��������� �������: " & Round(TimerDiff($Timer) /  1000, 3) & " ���." & @CRLF)
EndFunc ;==>_CreateMetadata
#EndRegion Metadata Functions

#Region Check Errors Functions
;----------------------------------------------- ������� ��������������� ----------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CheckErrors
; Description....:	�������� �� ������ �� ����������� ������ ���������
; Syntax.........:	_CheckErrors()
; ===============================================================================================================
Func _CheckErrors()
 Local $i, $Query, $sDir, $iFilesCount = 0
 _LogWrite("�������� ����������� ������ ���������...")
 $Query = _MySQL_Query("SELECT filename, tmdb_id FROM `" & $sDB_TableMoviesFiles & "`;")
 If IsObj($Query) Then
  While Not $Query.EOF
   Local $sFileName = $Query.Fields(0).value
   Local $sTMDB_ID  = $Query.Fields(1).value
   $Query.MoveNext
   $iFilesCount += 1
   If (StringLen($sTMDB_ID) == 0) Or ($sTMDB_ID == '0') Then
    _LogWrite(" ������: �� ������ ������������� ���� ������ 'themoviedb.org' ��� �����: '" & $sFileName & "'")
    $iErrorCount += 1
   ElseIf Not FileExists($sWebServerDir & $sMoviesIconsDir & $sTMDB_ID & ".jpg") Then
    _LogWrite(" ������: �� ������ ������ ��� �����: '" & $sFileName & "'")
    $iErrorCount += 1
   EndIf
  WEnd
 EndIf
 _LogWrite(@CRLF & "��������� ������ ���������:")
 _LogWrite(" � ������� '" & $sDB_TableMoviesFiles & "' ���������� �������: " & _
  _MySQL_GetCount($sDB_TableMoviesFiles, 'id'))
 _LogWrite(" � ������� '" & $sDB_TableMoviesInfo & "' ���������� �������: " & _
  _MySQL_GetCount($sDB_TableMoviesInfo, 'id'))
 _LogWrite(" � ������� '" & $sDB_TableMoviesCollections & "' ���������� �������: " & _
  _MySQL_GetCount($sDB_TableMoviesCollections, 'id'))
 If $iErrorCount == 0 Then
  _LogWrite(" �� ����� ���������� ��������� ������ �� ��������")
 Else
  _LogWrite(" ����� ������ �� ����� ���������� ���������: " & $iErrorCount)
 EndIf
 Local $sText = "������: �����: " & $iTotalFiles & "; � ���� ������: " & $iFilesCount
 If $iChangeCount > 0 Then $sText &= "; ���������: " & $iChangeCount
 If $iErrorCount > 0  Then $sText &= ". ������: " & $iErrorCount
 _SysyemLogWrite($iChangeCount, $iErrorCount, $sText)
 _LogWrite()
EndFunc ;==>_CheckErrors
#EndRegion Check Errors Functions
