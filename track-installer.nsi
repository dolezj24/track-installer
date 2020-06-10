!include nsArray.nsh
!include LogicLib.nsh
!include "MUI2.nsh"
!include "textfunc.nsh"
!include "WordFunc.nsh"
Unicode True

;---------Setup part----------------------------
; INFORMATION: Define Tracks.ini info and installer and uninstaller file names in next commands
!define TRACK_ID "705"
!define TRACK_NAME "Maps\track-705"
!define PARTICLES "Maps\PS_Poland"
!define STAGE_NAME "Lousada - RG"
!define SURFACE "1"
!define LENGTH "3.8"
!define SPLASH_SCREEN "Textures\Splash\705-Lousada_RG.dds"

; The installer and uninstaller file names
OutFile "RBRTrackName.exe"
!define UNINSTALLER "RBRTrackNameUnistaller.exe"

; Define conditions in tracksettings.ini
!define TRACKSETTINGS_CONDITION_HEADERS "705M_crisp_clear 705M_hazy_clear 705O_M_norain_heavycloud 705O_M_lightrain_heavycloud 705O_M_heavyfog_heavycloud \
  705O_M_heavyrain_heavycloud 705O_M_hazy_heavycloud 705E_hazy_heavycloud 705E_heavyfog_heavycloud 705E_norain_lightcloud"

;--------------------------------------
; The name of the installer
Name "RBR ${STAGE_NAME}"
DirText "Check, whether the correct Richard Burns Rally folder was found." "RBR folder"
; Read install dir from register
InstallDirRegKey  HKLM "SOFTWARE\SCi Games\Richard Burns Rally\InstallPath" ""
;InstallDir "some-test-rbr-dir"
; Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------
;Interface Settings
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TEXT "You are installing ${STAGE_NAME} for RBR"
!define MUI_WELCOMEPAGE_TITLE "${STAGE_NAME}"

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
Var track
Var splashFile
Var found
Var dummy

!define /file TRACKSETTINGS_INI_CONTENT ".\tracksettings-ini.txt"

Section "Install"
  SectionIn RO

  Call RemoveTrackFromIniFiles

  FileOpen $4 "$INSTDIR\Maps\Tracks.ini" a
  FileSeek $4 0 END
  FileWrite $4 "$\r$\n"
  FileWrite $4 "[Map${TRACK_ID}]$\r$\n"
  FileWrite $4 `TrackName="${TRACK_NAME}"$\r$\n`
  FileWrite $4 `Particles="${PARTICLES}"$\r$\n`
  FileWrite $4 `StageName="${STAGE_NAME}"$\r$\n`
  FileWrite $4 "Surface=${SURFACE}$\r$\n"
  FileWrite $4 "Length=${LENGTH}$\r$\n"
  FileWrite $4 `SplashScreen="${SPLASH_SCREEN}"$\r$\n`
  FileClose $4

  SetOutPath $INSTDIR

  File /r "track-files\"
  File "tracksettings-ini.txt"
  ${FileJoin} "$INSTDIR\maps\tracksettings.ini" "$INSTDIR\tracksettings-ini.txt" ""
    Delete "$INSTDIR\tracksettings-ini.txt"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBRTrack${STAGE_NAME}" "DisplayName" "RBR ${STAGE_NAME} uninstall"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBRTrack${STAGE_NAME}" "UninstallString" '"$INSTDIR\${UNINSTALLER}"'

  WriteUninstaller "${UNINSTALLER}"
  
SectionEnd ; end the install section

Section "Uninstall"
  nsArray::SetList conditions M N E O /end

  StrCpy $splashFile "${SPLASH_SCREEN}"

  ${ForEachIn} conditions $R0 $R1
    StrCpy $track "$INSTDIR\maps\track-${TRACK_ID}_$R1"
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

  Call un.RemoveTrackFromIniFiles

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RBRTrack${STAGE_NAME}"

  Delete "$INSTDIR\${UNINSTALLER}"

SectionEnd ; End uninstall section

!macro RemoveTrackFromIniFiles UN
  Function ${UN}RemoveTrackFromIniFiles
    StrCpy $found 1
    ${While} $found == 1
      DeleteINISec "$INSTDIR\Maps\Tracks.ini" "Map${TRACK_ID}"
      ReadINIStr $dummy "$INSTDIR\Maps\Tracks.ini" "Map${TRACK_ID}" "TrackName"
      IfErrors 0 +2
        StrCpy $found 0
    ${EndWhile}

    nsArray::SetList tracksettingsConditions ${TRACKSETTINGS_CONDITION_HEADERS} /end
      StrCpy $found 1
      ${While} $found == 1
        StrCpy $found 0
        ${ForEachIn} tracksettingsConditions $R0 $R1
          DeleteINISec "$INSTDIR\Maps\tracksettings.ini" "$R1"
          ReadINIStr $dummy "$INSTDIR\Maps\tracksettings.ini" "$R1" "AmbientBlue"
          IfErrors +2 0
            StrCpy $found 1
        ${Next}
      ${EndWhile}
  FunctionEnd
!macroend

!insertmacro RemoveTrackFromIniFiles ""
!insertmacro RemoveTrackFromIniFiles "un."
