!include nsArray.nsh
!include LogicLib.nsh
!include "MUI2.nsh"
!include "textfunc.nsh"
!include "WordFunc.nsh"

!include ".\str-contains.nsh"
!define StrContains '!insertmacro "un._StrContainsConstructor"'

!define /file TRACKS_INI_CONTENT ".\tracks-ini.txt"
!define /file TRACKSETTINGS_INI_CONTENT ".\tracksettings-ini.txt"

;---------Setup part----------------------------
; INFORMATION: Define Track name and installer and uninstaller file names in next commands
!define TRACK_NAME "Track Name"
; The installer and uninstaller file names
OutFile "RBRTrackName.exe"
!define UNINSTALLER "RBRTrackNameUnistaller.exe"

;--------------------------------------
; The name of the installer
Name "RBR ${TRACK_NAME}"
DirText "Check, whether the correct Richard Burns Rally folder was found." "RBR folder"
; Read install dir from register
InstallDirRegKey  HKLM "SOFTWARE\SCi Games\Richard Burns Rally\InstallPath" ""
;InstallDir "some-test-rbr-dir"
; Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------
;Interface Settings
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TEXT "You are installing ${TRACK_NAME} for RBR"
!define MUI_WELCOMEPAGE_TITLE "${TRACK_NAME}"

;--------------------------------
; Pages install
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
; Pages uninstall
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Variables can be only global, so they are initialized here together
Var found
Var dummy
Var trackId
Var res
Var file
Var index
Var start
Var line
Var linelen
Var track
Var splashFile

Section "Install"
  SectionIn RO

  Call SetTracksIniLines
  Call SetTrackId

  StrCpy $file tracks
  Call DeleteTrackFromIniFile
  StrCpy $file tracksettings
  Call DeleteTrackFromIniFile

  FileOpen $4 "$INSTDIR\maps\tracks.ini" a
  FileSeek $4 0 END
  FileWrite $4 "$\r$\n"
  ${ForEachIn} lines $R0 $R1
    FileWrite $4 "$R1$\r$\n"
  ${Next}
  FileClose $4

  SetOutPath $INSTDIR

  File /r "track-files\"
  File "tracksettings-ini.txt"
  ${FileJoin} "$INSTDIR\maps\tracksettings.ini" "$INSTDIR\tracksettings-ini.txt" ""
    Delete "$INSTDIR\tracksettings-ini.txt"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBRTrack${TRACK_NAME}" "DisplayName" "RBR ${TRACK_NAME} uninstall"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBRTrack${TRACK_NAME}" "UninstallString" '"$INSTDIR\${UNINSTALLER}"'

  WriteUninstaller "${UNINSTALLER}"
  
SectionEnd ; end the install section

Section "Uninstall"
  nsArray::SetList conditions M N E O /end

  Call un.SetTracksIniLines
  Call un.SetTrackId

  ${ForEachIn} lines $R0 $R1
    ${StrContains} $0 "SplashScreen" $R1
    StrCmp $0 "" notfound
      ${WordFind2X} '$R1' '"' '"' "+1" $splashFile
      Goto done
    notfound:
  ${Next}
  done:

  ${ForEachIn} conditions $R0 $R1
    StrCpy $track "$INSTDIR\maps\track-$trackId_$R1"
    IfFileExists "$track_textures.rbz" 0 +2
      Delete "$track_textures.rbz"
    IfFileExists "$track_textures" 0 +2
      RMDir /r "$track_textures"
    IfFileExists "$track.col" 0 +2
      Delete "$track.col"
    IfFileExists "$track.dls" 0 +2
      Delete "$track.dls"
    IfFileExists "$track.fnc" 0 +2
      Delete "$track.fnc"
    IfFileExists "$track.ini" 0 +2
      Delete "$track.ini"
    IfFileExists "$track.lbs" 0 +2
      Delete "$track.lbs"
    IfFileExists "$track.mat" 0 +2
      Delete "$track.mat"
    IfFileExists "$track.trk" 0 +2
      Delete "$track.trk"
  ${Next}

  IfFileExists "$INSTDIR\$splashFile" 0 +2
    Delete "$INSTDIR\$splashFile"

  StrCpy $file tracks
  Call un.DeleteTrackFromIniFile
  StrCpy $file tracksettings
  Call un.DeleteTrackFromIniFile

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBRTrack${TRACK_NAME}"

  Delete "$INSTDIR\${UNINSTALLER}"

SectionEnd ; End uninstall section

!macro GrepFunc UN
  Function ${UN}GrepFunc
    ${TrimNewLines} '$R9' $R9
    ${WordFind3X} '$R9' "[" $trackId "]" "E+1" $res
    IfErrors startNotFound 0
      StrCpy $found 1
      StrCpy $0 SkipWrite
      Goto grepEnd
    startNotFound:
    ${WordFind2X} '$R9' "[" "]" "E+1" $dummy
    IfErrors 0 setFlagFalse
      ${if} $found == 1
        StrCpy $0 SkipWrite
        Goto grepEnd
      ${else}
        Goto grepEnd
      ${endIf}

    setFlagFalse:
    StrCpy $found 0
    grepEnd:
    StrCpy $R9 '$R9$\r$\n'
    Push $0
  FunctionEnd
!macroend

!insertmacro GrepFunc ""
!insertmacro GrepFunc "un."

!macro DeleteTrackFromIniFile UN
  Function ${UN}DeleteTrackFromIniFile
    StrCpy $found 0
    ${LineFind} "$INSTDIR\maps\$file.ini" "C:\$file-temp.ini" "1:-1" "${UN}GrepFunc"
    CopyFiles /SILENT "C:\$file-temp.ini" "$INSTDIR\maps\$file.ini"
    Delete "C:\$file-temp.ini"
  FunctionEnd
!macroend

!insertmacro DeleteTrackFromIniFile ""
!insertmacro DeleteTrackFromIniFile "un."

!macro SetTracksIniLines UN
  Function ${UN}SetTracksIniLines
    StrCpy $0 `${TRACKS_INI_CONTENT}`
    StrCpy $index 0
    StrCpy $start 0
    loop:
      StrCpy $2 $0 1 $index
      StrCmp $2 '$\n' found
      IntOp $index $index + 1
      StrCmp $2 '' stop loop
    found:
      IntOp $linelen $index - $start
      StrCpy $line $0 $linelen $start
      nsArray::Set lines $line
      IntOp $index $index + 1
      StrCpy $start $index
      Goto loop
    stop:
    IntOp $index $index - 1
    IntOp $linelen $index - $start
    StrCpy $line $0 $linelen $start
    StrCmp $line '' +2 0
      nsArray::Set lines $line
  FunctionEnd
!macroend

!insertmacro SetTracksIniLines ""
!insertmacro SetTracksIniLines "un."

!macro SetTrackId UN
  Function ${UN}SetTrackId
    nsArray::Get lines 0
    Pop $R0
    ${WordFind2X} '$R0' "p" "]" "+1" $trackId
  FunctionEnd
!macroend

!insertmacro SetTrackId ""
!insertmacro SetTrackId "un."

