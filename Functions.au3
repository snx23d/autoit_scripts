#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.12.0

 Script Function:
	functions used in more than one place

	to do
	status: done (almost)

	changelog:
	11.06.2015
	changed CreateDirForIniFile() and RememberLastChosenPath() so they
	always create ini files in \cfg\ folder
	added ChooseFolder()


#ce ----------------------------------------------------------------------------
#include-once
#include <String.au3>

;~ #include <Array.au3> ;for debug

Local Const $IniPreviousPathSectionName="Previous_Path"
Local Const $IniPreviousPathKeyName="path"
Global Const $DefaultConfigPath=@ScriptDir & "\cfg"

Func CreateDirForIniFile ()

;check if dir exist

	If DirGetSize($DefaultConfigPath) = -1 Then $result=DirCreate ($DefaultConfigPath)

	;DirGetSize returns -1 when no dir, otherwise dir size

;ConsoleWrite ( DirGetSize($Pathqq) )
EndFunc

#cs
function reads/writes last chosen path from a config ini file

activity= "Read" "Write"
inifilename - name of ini file inside cfg folder
section name and key name are always constant
$LastPathUsed - if writing is needed, this is a value to be remembered

$IniSectionName, $IniKeyName,
#ce

Func RememberLastChosenPath($Activity, $IniFileName, $LastPathUsed)

	Local $PathToIni=$DefaultConfigPath &"\"& $IniFileName

	If $Activity="Read" Then

		Return IniRead( $PathToIni, $IniPreviousPathSectionName, $IniPreviousPathKeyName, "")

	EndIf

	If $Activity="Write" Then

		CreateDirForIniFile ()

		IniWrite($PathToIni, $IniPreviousPathSectionName, $IniPreviousPathKeyName, $LastPathUsed)

	EndIf

EndFunc
;*****************************************
; Name...........:	ChooseFolder ($IniFileName)
; Description ...:	chooses folder for file operations, and saves last used path to specified ini file
;						inside \cfg folder
; Syntax.........:	ChooseFolder ($PreviousPath, $IniFileName)
; Parameters ....:
;
; Return values .:
;					On Success			- path to choosen folder
;                 	On Failure			- Returns False.
;
;*****************************************
Func ChooseFolder($IniFileName)

	Local $Previous_Path=RememberLastChosenPath ("Read", $IniFileName, "")

	Local $i=0, $StringLen=0, $CFtmp="", $ArraySize=0
	Local $ChosenLocation=FileSelectFolder("Select a folder", $Previous_Path)

	If $ChosenLocation <>"" Then

		;divide whole path to parts separated by \

		Local $aArray = _StringExplode($ChosenLocation, "\", 255)

		;string is now in array, let's find last part of it

		$ArraySize=UBound($aArray)

		$StringLen=StringLen($aArray[$ArraySize-1])

		$CFtmp=StringTrimRight($ChosenLocation, $StringLen)

		;variable contains trimmed path to up one level

		RememberLastChosenPath("Write", $IniFileName, $CFtmp)

	EndIf

	Return $ChosenLocation

EndFunc

;*****************************************
; Name...........:	GetCurrentTimeDecimal()
; Description ...:	returns a decimal representation of current date and time as a single string
;						including seconds and milisecinds
; Syntax.........:	GetCurrentTimeDecimal()
; Parameters ....:
;
; Return values .:
;					On Success			- decimal value of time
;                 	On Failure			-
;
;*****************************************

Func GetCurrentTimeDecimal()

	Local $YearConverted, $YearConvertedString, $STRLen, $Sum, $Counter, $RightChar, $YearOutput
	Local $Hour, $Minute, $Second, $MSecond, $RandomNumber, $Output
	;sum up all of the digits from the year minus 2000

	$YearConverted=@YEAR-2000
	$YearConvertedString=String($YearConverted)
	$STRLen= StringLen($YearConvertedString)

	$Sum=0

	;sum up digits
	For $Counter=1 To $STRLen

		$RightChar= GetCharacterFromRightSide($YearConvertedString, $Counter)
		$Sum=$Sum+Number ($RightChar)

	Next

	$YearOutput=$Sum

	;hour is represented as nn/100
	$Hour=Round(100*@HOUR/60, 0)	;rounded to natural numbers

	;minute is represented as nn/100
	$Minute= Round(100*@MIN/60, 0)

	;seconds are untouched
	$Second=@SEC

	;miliseconds are trimmed to just first 2 digits
	$MSecond=StringLeft(@MSEC, 2)

	;adding some 6 digits random number at the end
	$RandomNumber=Random(0, 999999, 1)
	;adding zeroes at the beginning if number is small
	$RandomNumber=StringFormat("%06s", $RandomNumber)

	;putting all that together
	$Output=$YearOutput & $Hour & $Minute & $Second & $MSecond & $RandomNumber

	Return $Output

EndFunc

;*****************************************
; Name...........:	GetCharacterFromRightSide
; Description ...:	returns a single character from given string from the right side in specified position
;
; Syntax.........:	GetCharacterFromRightSide($InputString, $Position)
; Parameters ....:
;
; Return values .:
;					On Success			- single character
;                 	On Failure			- False if $Position is out of range
;
;*****************************************

Func GetCharacterFromRightSide($InputString, $Position)

	Local $STRLen, $tmp

	$STRLen= StringLen ($InputString)

	If $Position > $STRLen Then Return False
	If $Position < 0 Then Return False

	$tmp=StringRight ( $InputString, $Position )
	$tmp=StringLeft($tmp, 1)

	Return $tmp
EndFunc

;*****************************************
; Name...........:	GetCharacterFromLeftSide
; Description ...:	returns a single character from given string from the left side in specified position
;
; Syntax.........:	GetCharacterFromLeftSide($InputString, $Position)
; Parameters ....:
;
; Return values .:
;					On Success			- single character
;                 	On Failure			- False if $Position is out of range
;
;*****************************************

Func GetCharacterFromLeftSide($InputString, $Position)

	Local $STRLen, $tmp

	$STRLen= StringLen ($InputString)

	If $Position > $STRLen Then Return False
	If $Position < 0 Then Return False

	$tmp=StringLeft( $InputString, $Position )
	$tmp=StringRight($tmp, 1)

	Return $tmp
EndFunc
