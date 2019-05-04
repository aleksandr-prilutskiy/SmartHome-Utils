#Region Header
#CS Header
	AutoIt.........:	3.3.14.2 +
	File Version...:	0.2.0.0
	Date...........:	02.05.2019
	Title..........:	SmartHome - Multimedia Database Utility
	Filename.......:	movies.au3
	Description....:	Система "Умный дом". Скрипт обслуживания базы данных медиаресурсов, размещенных на сервере
	Uses...........:	Smart Home Framework 0.2.0.1+

	Author(s)......:	Aleksandr Prilutskiy
	Remarks........:	Параметры командной строки, обрабатываемые программой:
						/? - краткая справка о параметрах командной строки
						update - обновление списка медиаресурсов в базе данных
						/clear - очистка всех таблиц с информацией о медиаресурсах в базе данных
						/debug - режим отлажки (подробный отчет о выполнении)

						Алгоритм работы скрипта:
						1. В базе данных системы "Умный дом" должна быть таблица `config`.
						   В этой таблице выбираются все строки `MoviesDir`, `SeriesDir` и `MusicDir`.
						   Эти строки - пути к каталогам, в которых происходит сканирование файлов.
-----------------------------------------------------------------------------------------------------------------------------------
						2. В базе данных системы "Умный дом" создаются таблицы `movies_files`, `movies_info` и `movies_meta`.
						   Все таблицы создается только если они отсуствововали.
						3. Во всех записях таблицы `movies_files` поля `filesize` обнуляются.
						   У вех найденных при сканировании файлов, в таблице `movies_files` заполняеться поле
						   `filesize`. Все записи таблице `movies_files`, у которых полем `filesize` остается равно
						   нулю являются удаленными с диска и удаляются из таблицы.
						4. Все найденные при сканировании файлы анализируются по имени файла. В них выделяют русское
						   название, оригинальное название и год выпцска эти данные добавляются в соотвествующие поля
						   таблицы `movies_files`.
						   Имена файлов должы иметь вид: "{русское название} ({оригинальное название}) - {год}.{расширение}'
						   Если фильм русский и не имеет иностранного названия, или если русское название совпадает
						   с оригинальным, то в скобках имя фильма не указывается.
						5. Из таблицы `config` берутся значения записей `ServerDLNA` и `PortDLNA`.
						   По указанному адресу и порту медеасервер должен выдавать HTML-страницу в специальном формате.
						   При нахождении на странице имен файлов, соотвествующих записям в таблице `movies_files`,
						   в соответствующюю запись в поле поле `dlna_id` добавляется идентификатор ресурса медеасервера,
						   а также другие параметры файла, например размер изображения, частота кадров и т.д.
						6. По оригинальному имени фильма производится его поиск в базе данных сайта themoviedb.org,
						   с использованием API сайта, через GET-запросы. Для работы этой функции из таблицы `config`
						   берется значения записи `TMDB_API_Key`, которое используется в качестве ключа `API_Key` на сайте
						   themoviedb.org. Этот ключь нужно предварительно получить, зерегистрировавшись на указаном сайте
						   и перейдя по ссылке: `https://www.themoviedb.org/settings/api`.
						   Найденные идентификаторы помещаются в соотвествующие поля `tmdb_id` таблицы `movies_files`.

    Versions.......:	0.0.1.5 (18.09.2017) - первая полностью отлаженная версия (получение информации с сайта kinopoisk.ru)
						0.0.2.0 (08.02.2018) - скрипт переделан для получания информации о фильмах с сайта movielib.ru
						0.0.2.2 (05.04.2018) - скрипт переделан для получания информации о фильмах с сайта themoviedb.org
						0.2.0.0 (02.05.2019) - программа адаптированна под версию сервера 2.0.0 и версию прогаммы
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

; Настройка параметров приложения
		$sAppShortName			= 'Multimedia Database Utility'			; краткое название программы

; Прочие переменные, используемые в приложении
Global  $sServerURL				= ''									; URL запроса Web-интерфейса DLNA-сервера
Global	$sWebServerDir			= ''									; каталог размещения web-ресурсов сервера
Global  $sAPIKey				= ''									; ключ API_Key на сайте themoviedb.org
Global	$sMoviesIconsDir		= 'images\movies\'						; каталог изображений с обложками фильмов
Global	$iMoviesIconsWidth		= 360									; размер изображений обложек по горизонтали
Global	$iMoviesIconsHeight		= 510									; размер изображений обложек по вертикали
Global	$iMoviesOfDayNumber		= 6										; количество 'фильмов дня'
Dim		$aSaveMoviesOfDay[$iMoviesOfDayNumber]							; массив сохранение предыдущих 'фильмов дня'
Dim		$aMoviesDirs[1]			= [0]									; массив каталогов поиска файлов фильмов
Global	$iErrorCount			= 0										; счетчик ошибок
Global	$fClearDatabase			= False									; признак режима очистки баз данных
Global	$iErrorCount			= 0										; счетчик ошибок
Global	$iTotalFiles			= 0										; всего найдено файлов
Global	$iFilesCount			= 0										; счетчик текущих операций с файлами

Global	$iChangeCount			= 0										; кол-во измененных записей в базе данных
Global	$sDebugResultOfSearch	= ''									; найденные варианты названия фильма
Global	$sErrorsChars			= ''									; неизвестные символы в имени фильмов
Global	$fClearDatabase			= False									; признак режима очистки баз данных
#EndRegion Initialization

#Region Main Script
_AppStart()																; подготовка программы к работе
_Main()																	; основное выполение программы
_AppExit()																; завершение работы программы
#EndRegion Main Script

#Region Main
;------------------------------------------------ ОСНОВНОЕ ВЫПОЛНЕНИЕ ПРОГРАММЫ----------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_Main
; Description....:	Проверка и обработка параметров командной строки.
; Syntax.........:	_Main()
; ===============================================================================================================
Func _Main()
 If ($CmdLine[0] > 0) And ($CmdLine[1] == "/?") Then _
  Return _LogWrite("Система 'Умный дом'. Скрипт обслуживания базы данных фильмов, размещенных на сервере." & _
          @CRLF & "Параметры командной строки:" & @CRLF & _
          "multimedia.exe [update] {/clear} {/debug}" & @CRLF & _
		  " update - обновление списка фильмов в базе данных" & @CRLF & _
		  " /clear - очистка всех таблиц с информацией о фильмах в базе данных" & @CRLF & _
		  " /debug - режим отлажки (подробный отчет о выполнении)")
 Local $i, $sCommand = $CmdLine[0] > 0 ? $CmdLine[1] : ''
 For $i = 2 To $CmdLine[0]
  If $CmdLine[$i] == '/clear' Then $fClearDatabase = True
 Next
 Switch $sCommand
  Case "update"
   _ReadServerConfig()			; чтение настроек системы "Умный дом"
   _CreateDatabaseTables()		; создание необходимых таблиц в базе данных
   _ScanMoviesFiles()			; поиск фильмов в каталогах и добавление их в базу данных
   _ScanDLNA()					; получение DLNA-идентификаторов объектов для всех файлов
   _ScanTMDB()					; получение ID фильмов с сайта themoviedb.org
   _LoadMoviesImages()			; загрузка постеров добавленных фильмов
   _CreateMetadata()			; генерирование метаданных, связанных с фильмами
   _CheckErrors()				; проверка на ошибки
  Case Else
   _LogWrite(" Ошибка в синтаксисе команды." & @CRLF & " Используйте 'multimedia.exe /?'")
 EndSwitch
EndFunc ;==>_CheckCommandLine
#EndRegion _Main

#Region Read Config
;-------------------------------------------- ФУНКЦИИ ЗАГРУЗКИ НАСТРОЕК ПРИЛОЖЕНИЯ ------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ReadServerConfig
; Description....:	Чтение настроек системы "Умный дом" из базы данных.
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
  _LogWrite(" Ошибка получения параметров DLNA сервера" & @CRLF & _
		    " Проверьте записи 'ServerDLNA', 'PortDLNA' и 'WebServerDir' в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Ошибка параметров DLNA сервера")
  _AppExit()
 EndIf
 If StringLen($sAPIKey) == 0 Then
  _LogWrite(" Ошибка получения ключа TMDB API_Key" & @CRLF & _
            " Проверьте запись 'TMDB_API_Key' в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Ошибка ключа TMDB API_Key")
  _AppExit()
 EndIf
 If UBound($aMoviesDirs) == 1 Then
  _LogWrite(" Ошибка получения списка каталогов сканирования фильмов" & @CRLF & _
            " Проверьте записи 'MoviesDir' в таблице '" & $sDB_TableConfig & "'")
  _SysyemLogWrite(0, 1, "Ошибка каталогов сканирования")
  _AppExit()
 EndIf
 If $DEBUG Then
  _LogWrite("Были получены следующие настройки системы 'Умный дом':" & @CRLF & _
			" ServerURL    = " & $sServerURL & @CRLF & _
			" WebServerDir = " & $sWebServerDir & @CRLF & _
			" TMDB API_Key = " & $sAPIKey & @CRLF & _
			" MoviesDir    = [" & _ArrayToString($aMoviesDirs, ', ', 1) & "]" & @CRLF)
 EndIf
 _LogWrite("Загрузка предыдущих 'фильмов дня'...")
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
 _LogWrite(" Загружено записей о фильмах: " & $i & @CRLF)
EndFunc ;==>_ReadServerConfig
#EndRegion Read Config

#Region MySQL Functions
;-------------------------------------------- ФУНКЦИИ РАБОТЫ С БАЗОЙ ДАННЫХ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateDatabaseTables
; Description....:	Создание в базе данных таблиц с информацией о фильмах, размещенных на сервере.
; Syntax.........:	_CreateDatabaseTables()
; ===============================================================================================================
Func _CreateDatabaseTables()
 _LogWrite("Создание таблиц в базе данных...")
 If $fClearDatabase Then _LogWrite(" Все таблицы удалены и будут созданы заново")
 If _MySQL_CheckTable($sDB_TableMoviesFiles) Then ; $sDB_TableMoviesFiles
  If $fClearDatabase Then
   _MySQL_DropTable($sDB_TableMoviesFiles)
  Else
   _LogWrite(" Найдена таблица '" & $sDB_TableMoviesFiles & "'")
  EndIf
 EndIf
 If Not _MySQL_CheckTable($sDB_TableMoviesFiles) Then
  _MySQL_Query("CREATE TABLE `" & $sDB_TableMoviesFiles & "` (" & _
   "id INT UNSIGNED NOT NULL AUTO_INCREMENT, " & _ ; id файла
   "dlna_id TEXT NOT NULL, " & _			; id эпизода в базе данных медиасервера
   "name TEXT, " & _						; оригинальное название фильма
   "name_rus TEXT, " & _					; русское название фильма
   "year TEXT, " & _						; год выпуска фильма
   "tmdb_id INT UNSIGNED DEFAULT 0, " & _	; id фильма на сайте themoviedb.org
   "filename TEXT, " & _	 				; имя файла на сервере
   "filesize INT UNSIGNED, " & _			; размер файла
   "filetype TEXT, " & _	 				; расширение (тип) файла
   "duration INT UNSIGNED DEFAULT 0, " & _	; длительность фильма в секундах
   "resolution TEXT, " & _	 				; разрешение изображения
   "fps FLOAT, " & _						; частота кадров
   "videocodec TEXT, " & _	 				; алгоритм сжатия видеоданных
   "audiocodec TEXT, " & _	 				; алгоритм сжатия звуковой дорожки
   "audiochannels TINYINT UNSIGNED, " & _	; количество каналов звука
   "added DATE, " & _						; дата добавления записи
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" Создана таблица '" & $sDB_TableMoviesFiles & "'")
  Else
   _LogWrite(" Ошибка: Невозможно создать таблицу '" & $sDB_TableMoviesFiles & "'")
   _SysyemLogWrite(0, 1, "Ошибка базы данных")
   _AppExit()
  EndIf
 EndIf
 If _MySQL_CheckTable($sDB_TableMoviesInfo) Then ; $sDB_TableMoviesInfo
  If $fClearDatabase Then
   _MySQL_DropTable($sDB_TableMoviesInfo)
  Else
   _LogWrite(" Найдена таблица '" & $sDB_TableMoviesInfo & "'")
  EndIf
 EndIf
 If Not _MySQL_CheckTable($sDB_TableMoviesInfo) Then
  _MySQL_Query("CREATE TABLE `" & $sDB_TableMoviesInfo & "` (" & _
   "id INT UNSIGNED NOT NULL, " & _			; id фильма на сайте movielib.ru
   "name TEXT, " & _						; оригинальное название фильма
   "name_rus TEXT, " & _					; русское название фильма
   "year TEXT, " & _						; год выпуска фильма
   "time INT UNSIGNED, " & _				; продолжительность фильма
   "genre TEXT, " & _						; жанр фильма
   "country TEXT, " & _						; срана производства фильма
   "description TEXT, " & _					; описание фильма
   "director TEXT, " & _					; режиссер фильма
   "actors TEXT, " & _						; актеры в главных ролях фильма
   "poster TEXT," & _						; ссылка на постер к фильму
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" Создана таблица '" & $sDB_TableMoviesInfo & "'")
  Else
   _LogWrite(" Ошибка: Невозможно создать таблицу '" & $sDB_TableMoviesInfo & "'")
   _SysyemLogWrite(0, 1, "Ошибка базы данных")
   _AppExit()
  EndIf
 EndIf
 If _MySQL_CheckTable($sDB_TableMoviesCollections) Then ; $sDB_TableMoviesCollections
  If $fClearDatabase Then
   _MySQL_DropTable($sDB_TableMoviesCollections)
  Else
   _LogWrite(" Найдена таблица '" & $sDB_TableMoviesCollections & "'")
  EndIf
 EndIf
 If Not _MySQL_CheckTable($sDB_TableMoviesCollections) Then
  _MySQL_Query("CREATE TABLE `" & $sDB_TableMoviesCollections & "` (" & _
   "id INT UNSIGNED NOT NULL, " & _			; id колекции на сайте movielib.ru
   "name TEXT, " & _						; название коллекции фильмов
   "poster TEXT," & _						; ссылка на постер к коллекции фильмов
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" Создана таблица '" & $sDB_TableMoviesCollections & "'")
  Else
   _LogWrite(" Ошибка: Невозможно создать таблицу '" & $sDB_TableMoviesCollections & "'")
   _SysyemLogWrite(0, 1, "Ошибка базы данных")
   _AppExit()
  EndIf
 EndIf
 If _MySQL_CheckTable($sDB_TableMoviesMetadata) Then ; $sDB_TableMoviesMetadata
  If $fClearDatabase Then
   _MySQL_DropTable($sDB_TableMoviesMetadata)
  Else
   _LogWrite(" Найдена таблица '" & $sDB_TableMoviesMetadata & "'")
  EndIf
 EndIf
 If Not _MySQL_CheckTable($sDB_TableMoviesMetadata) Then
  _MySQL_Query("CREATE TABLE `" & $sDB_TableMoviesMetadata & "` (" & _
   "id INT UNSIGNED NOT NULL AUTO_INCREMENT, " & _ ; id записи
   "type TEXT, " & _						; тип записи
   "value TEXT, " & _						; значение записи
   "data INT, " & _							; дополнительные параметр
   "PRIMARY KEY (`id`));")
  If Not @error Then
   _LogWrite(" Создана таблица '" & $sDB_TableMoviesMetadata & "'")
  Else
   _LogWrite(" Ошибка: Невозможно создать таблицу '" & $sDB_TableMoviesMetadata & "'")
   _SysyemLogWrite(0, 1, "Ошибка базы данных")
   _AppExit()
  EndIf
 EndIf
 _LogWrite()
EndFunc ;==>_CreateDatabaseTables
#EndRegion MySQL Functions

#Region Files Functions
;------------------------------------------- ФУНКЦИИ СКАНИРОВАНИЯ КАТАЛОГОВ -------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ScanMoviesFiles
; Description....:	Сканирование каталогов и поиск в них файлов с фильмами.
; Syntax.........:	_ScanMoviesFiles()
; Remarks .......:	Результат работы функции - частичное заполнение таблицы $sDB_TableMoviesFiles.
;					Список каталогов берется из глобальной переменной-массива $aMoviesDirs.
;					Первый элемент массива $aMoviesDirs содержит количество элементов в массиве и пропускется.
;					Перед сканированием во всех записях таблицы `movies_files` поля `filesize` обнуляются.
;					Если находится файл, ранее добавленный в таблицу `movies_files`, у него заполняеться поле
;					`filesize`. Если запись с таким файлом не найдена - она будет добавлена и заполнено поле
;					`filesize`. После сканирования всех каталогов, все записи в таблице `movies_files` у которых
;					поле `filesize` равно нулю соотвествуют файлам, удаленным с диска и удаляются из таблицы.
; ===============================================================================================================
Func _ScanMoviesFiles()
 Local $i, $Timer = TimerInit()
 Local $iStartCount = _MySQL_GetCount($sDB_TableMoviesFiles, "id")
 _MySQL_Query("UPDATE `" & $sDB_TableMoviesFiles & "` SET filesize = 0;")
 For $i = 1 To UBound($aMoviesDirs) - 1
  _LogWrite("Сканирование каталога '" & $aMoviesDirs[$i] & "'...")
  _RecursiveScanDir($sDB_TableMoviesFiles, $aMoviesDirs[$i], _StringExplode(".mkv,.avi", ","))
 Next
 _LogWrite(" Всего найдено файлов: " & $iTotalFiles)
 Local $iSearchCount = _MySQL_GetCount($sDB_TableMoviesFiles, "id")
 If $iSearchCount > $iStartCount Then _
  _LogWrite(" Добавлена информация о новых файлах: " & $iSearchCount - $iStartCount)
 _MySQL_Query("DELETE FROM `" & $sDB_TableMoviesFiles & "` WHERE filesize = 0;")
 Local $iDelCount = _MySQL_GetCount($sDB_TableMoviesFiles, "id")
 If $iDelCount < $iSearchCount Then _
  _LogWrite(" Удалена информация о ранее присутствовавших файлах: " & $iSearchCount - $iDelCount)
 _LogWrite(" Затрачено времени: " & Round(TimerDiff($Timer) / 1000, 3) & " сек." & @CRLF)
EndFunc ;==>_ScanMoviesFiles

; #FUNCTION# ====================================================================================================
; Name...........:	_RecursiveScanDir
; Description....:	Рекурсивное сканирование каталогов.
; Syntax.........:	_RecursiveScanDir($sTableName, $sDir, $aExt)
; Parameter(s)...:	$sTableName - имя таблицы в базе данных, в которую будут добавлены найденные файлы
;					$sDir		- каталог сканирования.
;					$aExt		- массив расширений искомых файлов.
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
       _LogWrite(" Ошибка: в имени файла: '" & $sFileFullName & "' невозможно выделить год.")
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
       _LogWrite(" Ошибка:  Невозможно добавить запись о файле '" & $sFileFullName & "'")
      Else
       If $DEBUG Then _LogWrite(" Добавлен файл: " & $sDir & $sFileName)
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
;--------------------------------------- ФУНКЦИИ ДЛЯ РАБОТЫ С МЕДИАСЕРВЕРОМ DLNA --------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_ScanDLNA
; Description....:	Получение всех идентификаторов объектов медиасервера.
; Syntax.........:	_ScanDLNA()
; Remarks .......:	Результат работы функции - частичное заполнение таблицы 'movies_files' в базе данных.
; ===============================================================================================================
Func _ScanDLNA()
 _LogWrite("Сканирование каталога ресурсов медиасервера...")
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
 _LogWrite(" Затрачено времени: " & Round(TimerDiff($Timer) / 1000, 3) & " сек." & @CRLF)
EndFunc ;==>_ScanDLNA

Func _GetFileInfoDLNA($sTableName, $sID, $sFileName)
 Local $sURL = $sServerURL & '/MediaServer/Folders/0?find=' & _StringURLEncode($sFileName)
 Local $sHTML = BinaryToString(InetRead($sURL), $INET_FORCERELOAD)
 Local $jResponses = _JSONDecode($sHTML)
 If Not IsArray($jResponses) Then
  $iErrorCount += 1
  _LogWrite(" Ошибка: Невозможно получить информацию о файле: '" & $sFileName & "'")
  Return
 EndIf
;_ArrayDisplay($jResponses)
 Local $sDLNA = _GetDataFromJSON($jResponses, 'id')
 If StringLen($sDLNA) == 0 Then
  $iErrorCount += 1
  _LogWrite(" Ошибка: Не возможно получить DLNA ID для файла: '" & $sFileName & "'")
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
  _LogWrite(" Ошибка: Невозможно обновить информацию о фильме: '" & $sFileName & "'")
 EndIf
EndFunc ;==>_GetFileInfoDLNA

; #FUNCTION# ====================================================================================================
; Name...........:	_GetDuration
; Description....:	Получение значения длительности медиафайла в секундах из текстового формата
; Syntax.........:	_GetDuration($sStr)
; Parameters.....:	$sStr		- исходная трока
; Return Value(s):  On Success	- время в секундах, вычесленное из строки
;                   On Failure	- 0.
; Remarks .......:	Формат тэга: HH:MM:SS.xxx, где: НН - часы, MM - минуты, SS - секунды, xxx - доли секунд.
; ===============================================================================================================
Func _GetDuration($sStr)
 If StringLen($sStr) == 0 Then Return 0
 Local $aDuration = StringSplit($sStr, ':')
 If $aDuration[0] <> 3 Then Return 0
 Return Round(3600 * Number($aDuration[1]) + 60 * Number($aDuration[2]) + Number($aDuration[3]))
EndFunc ;==>_GetDuration

; #FUNCTION# ====================================================================================================
; Name...........:	_GetDataFromJSON
; Description....:	Получение значения определенной записи в массиве элеметнов JSON
; Syntax.........:	_GetDataFromJSON($aJSON, $sKeyStr)
; Parameter(s)...:	$aJSON			- массив записей в формате JSON
;					$sKeyStr		- строка для поиска
; Return values .: 	Success:	значение параметра, соотвествующее ключу поиска
;					Failure:	пустая строка
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
; Description....:	Получение идентификаторов вновь добавленных фильмов на сайте themoviedb.org.
; Syntax.........:	_GetNewMoviesTMDB_ID()
; Remarks .......:	Результат работы функции - заполнение пустых полей tmdb_id в таблице 'movies_files'.
; ===============================================================================================================
Func _ScanTMDB()
 Local $i, $j, $Timer = TimerInit()
 Local $iSaveErrorCount = $iErrorCount
 $iFilesCount = 0
 _LogWrite("Получение идентификаторов фильмов на сайте themoviedb.org...")
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
     _LogWrite(" Не найден идентификатор TMDB для фильма '" & $sFileName & "'")
     If StringLen($sDebugResultOfSearch) > 0 Then
      _LogWrite(' -> результаты поиска:' & @CRLF & $sDebugResultOfSearch)
     EndIf
    Else
	 _LogWrite(" Не найден идентификатор TMDB для фильма '" & $sFileName & "'")
    EndIf
    ContinueLoop
   EndIf
   _MySQL_Query("UPDATE `" & $sDB_TableMoviesFiles & "` SET " & _
     "tmdb_id = " & $iTMDB_ID & " WHERE id = " & $iFileID & ";")
   If @error Then
    _LogWrite(" Ошибка: Невозможно обновить информацию о фильме: '" & $sFileName & "'")
    $iErrorCount += 1
   Else
    If $DEBUG Then _LogWrite(" Присвоен идентификатор #" & $iTMDB_ID & " для фильма: '" & $sFileName & "'")
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
  _LogWrite(@CRLF & ' Во время поиска были обнаружены подозрительные символы: ' &  @CRLF & $s & @CRLF)
 EndIf
 _LogWrite(" Найдено идентификаторов фильмов: " & $iFilesCount & @CRLF & _
  " Всего ошибок при поиске: " & $iErrorCount - $iSaveErrorCount & @CRLF & _
  " Затрачено времени: " & Round(TimerDiff($Timer) / 1000, 3) & " сек." & @CRLF)
EndFunc ;==>_ScanTMDB

; #FUNCTION# ====================================================================================================
; Name...........:	_GetMovieTMDB_Info
; Description....:	Получение информации о фильмах, остуствующих в базе данных с сайта themoviedb.org
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
  If $DEBUG Then _LogWrite(" Ошибка. Невозможно получить информацию о фильме #" & $iMovieID)
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
  _LogWrite(" Ошибка: Невозможно добавить информацию о фильме: '" & $sMovieNameFull & "'")
  $iErrorCount += 1
 Else
  If $DEBUG Then _LogWrite(" Добавлена информация о фильме: '" & $sMovieNameFull & "' #" & $iMovieID)
  $iFilesCount += 1
 EndIf
EndFunc ;==>_GetMovieTMDB_Info

; #FUNCTION# ====================================================================================================
; Name...........:	_AddMoviesCollection
; Description....:	Добавление в базу данных информации о коллекции фильмов с сайта themoviedb.org
; Syntax.........:	_AddMoviesCollection($iMovieID, $jResponses)
; Remarks .......:	Результат работы функции - заполнение таблиц 'movies_collections' и 'movies_metadata'
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
; Description....:	Загрузка из Интернета постеров для вновь добавленных фильмов
; Syntax.........:	_LoadMoviesImages()
; ===============================================================================================================
Func _LoadMoviesImages()
 Local $i = 0, $Timer = TimerInit()
 $iFilesCount = 0
 _LogWrite("Загрузка изображений с обложками фильмов и коллекций фильмов...")
 If Not _CreateTempDir() Then
  _LogWrite(" Ошибка: невозможно создать каталог для временных файлов")
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
    If $DEBUG Then _LogWrite(" Загружен постер к фильму: '" & $sMovieNameFull & "'")
   ElseIf $iResult < 0 Then
    _LogWrite(" Ошибка: невозможно загрузить постер к фильму: '" & $sMovieNameFull & "'")
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
    If $DEBUG Then _LogWrite(" Загружен постер к коллекции фильмов: '" & $sCollectionsName & "'")
   ElseIf $iResult < 0 Then
    _LogWrite(" Ошибка: невозможно загрузить постер к коллекции фильмов: '" & $sCollectionsName & "'")
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
   _LogWrite(" Ошибка: Не удалось удалить файл: " & $sFileFullName)
 WEnd
 FileClose($hSearch)
 If $iFilesCount > 0 Then _
  _LogWrite(" Всего загружено файлов с изображениями постеров к фильмам и коллекциям фильмов: " & $iFilesCount)
 _LogWrite(" В каталоге '" & $sMoviesIconsDir & "' содержится файлов с постерами всего: " & $iImagesCount)
 _LogWrite(" Затрачено времени: " & Round(TimerDiff($Timer) /  1000, 3) & " сек." & @CRLF)
EndFunc ;==>_LoadMoviesImages

; #FUNCTION# ====================================================================================================
; Name...........:	_LoadPosterImage
; Description....:	Загрузка изображения постера из Интернета
; Syntax.........:	_LoadPosterImage($sDir, $iID, $sPosterURL)
; Parameter(s)...:	$sDir			- каталог, в который будет помещен загружаемый файл
;					$iID			- ID фильма или коллекции
;					$sPosterURL		- URL изображения с интернете, которое будет загружено
; Return Value(s):  0	- для этого фильма (коллекции) постер уже был загружен ранее
;                   1	- постер был успешно загружен
;                   -1	- ошибка
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
; Description....:  Коррекция наименования фильма в строку для сравнения
; Syntax.........:	_StringMovieNameFix($sString)
; Parameters.....:	$sString	- исходная строка
; Return values..:	Преобразованная строка
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
    $sTxt &= '0' ; ноль
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
    $sTxt &= 'Е'
   Case 0xD191
    $sTxt &= 'е'
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
;---------------------------------------- ФУНКЦИИ ГЕНЕРАЦИИ МЕТАДАННЫХ О ФИЛЬМАХ --------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CreateMetadata
; Description....:	Создание и сохранение метаданных
; Syntax.........:	_CreateMetadata()
; ===============================================================================================================
Func _CreateMetadata()
Local $i, $Timer = TimerInit()
 _LogWrite("Подготовка метаданных...")
 _LogWrite(" Подготовка списка жанров:")
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
 _LogWrite(" Выбор 'фильмов дня':")
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
   If $DEBUG Then _LogWrite(" > выбран фильм дня #" & $aMovies[$n])
   _MySQL_Query("INSERT INTO `" & $sDB_TableMoviesMetadata & "` (type, value) VALUES (" & _
    "'movie_of_day', " & _													; type
    "'" & $aMovies[$n] & "');")												; value
   $aMovies[$n] = 0
   $i += 1
  Until $i >= $iMoviesOfDayNumber
 Else
  _LogWrite(" > В таблице '" & $sDB_TableMoviesInfo & "' содержится слишком мало записей")
 EndIf
 _LogWrite(" Затрачено времени: " & Round(TimerDiff($Timer) /  1000, 3) & " сек." & @CRLF)
EndFunc ;==>_CreateMetadata
#EndRegion Metadata Functions

#Region Check Errors Functions
;----------------------------------------------- ФУНКЦИИ САМОДИАГНОСТИКИ ----------------------------------------

; #FUNCTION# ====================================================================================================
; Name...........:	_CheckErrors
; Description....:	Проверка на ошибки по результатам работы программы
; Syntax.........:	_CheckErrors()
; ===============================================================================================================
Func _CheckErrors()
 Local $i, $Query, $sDir, $iFilesCount = 0
 _LogWrite("Проверка результатов работы программы...")
 $Query = _MySQL_Query("SELECT filename, tmdb_id FROM `" & $sDB_TableMoviesFiles & "`;")
 If IsObj($Query) Then
  While Not $Query.EOF
   Local $sFileName = $Query.Fields(0).value
   Local $sTMDB_ID  = $Query.Fields(1).value
   $Query.MoveNext
   $iFilesCount += 1
   If (StringLen($sTMDB_ID) == 0) Or ($sTMDB_ID == '0') Then
    _LogWrite(" Ошибка: не найден идентификатор базы данных 'themoviedb.org' для файла: '" & $sFileName & "'")
    $iErrorCount += 1
   ElseIf Not FileExists($sWebServerDir & $sMoviesIconsDir & $sTMDB_ID & ".jpg") Then
    _LogWrite(" Ошибка: не найден постер для файла: '" & $sFileName & "'")
    $iErrorCount += 1
   EndIf
  WEnd
 EndIf
 _LogWrite(@CRLF & "Результат работы программы:")
 _LogWrite(" В таблице '" & $sDB_TableMoviesFiles & "' содержится записей: " & _
  _MySQL_GetCount($sDB_TableMoviesFiles, 'id'))
 _LogWrite(" В таблице '" & $sDB_TableMoviesInfo & "' содержится записей: " & _
  _MySQL_GetCount($sDB_TableMoviesInfo, 'id'))
 _LogWrite(" В таблице '" & $sDB_TableMoviesCollections & "' содержится записей: " & _
  _MySQL_GetCount($sDB_TableMoviesCollections, 'id'))
 If $iErrorCount == 0 Then
  _LogWrite(" Во время выполнения программы ошибок не возникло")
 Else
  _LogWrite(" Всего ошибок во время выполнения программы: " & $iErrorCount)
 EndIf
 Local $sText = "Файлов: всего: " & $iTotalFiles & "; в базе данных: " & $iFilesCount
 If $iChangeCount > 0 Then $sText &= "; добавлено: " & $iChangeCount
 If $iErrorCount > 0  Then $sText &= ". Ошибок: " & $iErrorCount
 _SysyemLogWrite($iChangeCount, $iErrorCount, $sText)
 _LogWrite()
EndFunc ;==>_CheckErrors
#EndRegion Check Errors Functions
