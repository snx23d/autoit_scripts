#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.12.0

;to do

add errors from winerror.h
extract both source and destination paths error occured
move here SHFileOperationErrDecode($errNum), send only a text message to the main
queuing mcq files for processing - move to the main!

move executed mcq to a different folder
resume work after exiting whilst busy - look for existing mcq files

move to the main all msgboxes!, handle errors in the main program, not here


 Script Function:

	fchsrv=FileCopyHandlerService

	handles copying of various files and folders as a separate process that communicates with the main program

#ce ----------------------------------------------------------------------------

#Region Templates
#cs
************************************
data structure for MM queue slave
variables 1-5 - reserved for possible future usage

$S_MM_DataStructure_tag= "char MCQFileName[25];" & _
"int ErrorNumber;" & _
"char FileNameErrorOccured[256];" & _
"int ExitCommand;" & _
"int SkipOnErrorCommand" ;& _
;~ "int VARIABLE1;" & _
;~ "int VARIABLE2;" & _
;~ "int VARIABLE3;" & _
;~ "int VARIABLE4;" & _
;~ "int VARIABLE5"

************************************
queues structure:

STX marker destination ENQ marker source(s) ETX marker

this sequence makes a full queue record
**************************
logging to file

_FileWriteLog ($PathToLogFile, $sLogMsg)
***********************************

;CopyWithProgress (from, to, error)												;template

;error to be passed to the copy handler for processing
;~ 		$result = CopyWithProgress($ProcessedPathBuffer,"F:\testW", $ErrorMessage)
************************************

#ce
#EndRegion

#Region Include

#include-once
#include <Array.au3>						;for debug
#include <File.au3>
#include <GUIConstantsEx.au3>
#include "../WinErrDecode.au3"
#include "../IPC_LibraryByNomad.au3"	;library used for IPC shared memory method
#include "../Queue.au3"


;~ #include

#EndRegion

#Region Constants

;win api file copy constants
Global Const $FO_MOVE                   = 0x0001
Global Const $FO_COPY                   = 0x0002
Global Const $FO_DELETE                 = 0x0003
Global Const $FO_RENAME                 = 0x0004
Global Const $FOF_MULTIDESTFILES        = 0x0001
Global Const $FOF_CONFIRMMOUSE          = 0x0002
Global Const $FOF_SILENT                = 0x0004
Global Const $FOF_RENAMEONCOLLISION     = 0x0008
Global Const $FOF_NOCONFIRMATION        = 0x0010
Global Const $FOF_WANTMAPPINGHANDLE     = 0x0020
Global Const $FOF_ALLOWUNDO             = 0x0040
Global Const $FOF_FILESONLY             = 0x0080
Global Const $FOF_SIMPLEPROGRESS        = 0x0100
Global Const $FOF_NOCONFIRMMKDIR        = 0x0200
Global Const $FOF_NOERRORUI             = 0x0400
Global Const $FOF_NOCOPYSECURITYATTRIBS = 0x0800
Global Const $FOF_NORECURSION           = 0x1000
Global Const $FOF_NO_CONNECTED_ELEMENTS = 0x2000
Global Const $FOF_WANTNUKEWARNING       = 0x4000
Global Const $FOF_NORECURSEREPARSE      = 0x8000


Global Const $NullChar = 		Chr(0)
Global Const $MarkerSTX = 	Chr(3)		;start of text marker
Global Const $MarkerETX =		Chr(4)		;end of text marker
Global Const $MarkerENQ = 	Chr(5)		;end of the destination block marker
Global Const $MM_SaveQueuePath =@ScriptDir & "\data\MCQ\"
Global Const $DebugLogSavePath=@ScriptDir & "\log\"
Global Const $NameOfThisScript="fchsrv"
Global Const $PathToLogFile=$DebugLogSavePath & $NameOfThisScript &".txt"

#EndRegion

#Region Variables

Global $MCQ_FileToProcess=""
Global $MM_Queue=0
;~ Global $tmp_QueueArray=0
Global $DebugLog=""
Local $Source, $Destination
Local $ErrorNumberMessage, $ResultOfCopying

#EndRegion

;check if log folder exist, if not then create it
	$Result=1
	If DirGetSize($DebugLogSavePath) = -1 Then

		$Result=DirCreate ($DebugLogSavePath)
		_FileWriteLog ($PathToLogFile, "log folder created")

	EndIf

	If $Result =0 Then

		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical, Modality=Task Modal
		MsgBox($MB_OK + $MB_ICONHAND + $MB_TASKMODAL, $NameOfThisScript, "An undefined critical error occured during an attempt to create the following path:" & _
		@CRLF & @CRLF & $DebugLogSavePath)
		#EndRegion --- CodeWizard generated code End ---

	EndIf

_FileWriteLog ($PathToLogFile, "logging new session")


If $CmdLine[0] <> 6 Then Exit ; require PID, 5 pointers = 6 parameters

;assign parameters to variables representing the pointers

Global $PID_MainProgram = $CmdLine[1]
Global $MM_MCQFileName_Pointer = $CmdLine[2]
Global $MM_ErrorNumber_Pointer = $CmdLine[3]
Global $MM_FileNameErrorOccured_Pointer = $CmdLine[4]
Global $MM_ExitCommand_Pointer = $CmdLine[5]
Global $MM_SkipOnErrorCommand_Pointer = $CmdLine[6]
;~ Global $tmp = $CmdLine[7]
;~ Global $tmp = $CmdLine[8]
;~ Global $tmp = $CmdLine[9]

;create initial queue for processing mcq file

$MM_Queue=_Queue_Create(50)	;create MM queue with initial size of 50

;open kernel library to start sharing access to memory

Global $hKernDll = _MemoryOpen($PID_MainProgram)



#Region Main

While 1

$MCQ_FileToProcess=_MemoryRead($MM_MCQFileName_Pointer, $hKernDll , "char MCQ_FileToProcess[25]")

;scan for new mcq files to process

If $MCQ_FileToProcess <>"" Then

	;reset to null string MCQ_FileToProcess field and send info about receiving the message

	_MemoryWrite($MM_MCQFileName_Pointer, $hKernDll, "", "char MCQ_FileToProcess[25]")
	_MemoryWrite($MM_ErrorNumber_Pointer, $hKernDll, -5 , "int")

	;path to read the file

	$SaveFileReadPath=$MM_SaveQueuePath & $MCQ_FileToProcess

	;write MCQ_FileToProcess's content to the queue array

	$SaveFileReadResult=1
	$SaveFileReadResult= _FileReadToArray ($SaveFileReadPath, $MM_Queue, 0)

	If @error=1 Then

		_FileWriteLog ($PathToLogFile, "_FileReadToArray failed")

		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical, Modality=Task Modal
		MsgBox($MB_OK + $MB_ICONHAND + $MB_TASKMODAL, $NameOfThisScript, "Error opening queue data file or path does not exist.")
		#EndRegion --- CodeWizard generated code Start ---

	EndIf
	_FileWriteLog ($PathToLogFile, "file" & $SaveFileReadPath & " received" )
;~ 	_ArrayDisplay($MM_Queue);for debug only

	;loop untill file queue is empty

	$ExtractionResult=True

	While (_Queue_GetSize($MM_Queue)>0) And ($ExtractionResult=True)

		;process queue array
		$ExtractionResult=ExtractDataFromQueue($MM_Queue, $Source, $Destination)

		If $ExtractionResult=False Then
			;send error message

			_MemoryWrite($MM_ErrorNumber_Pointer, $hKernDll, 1 , "int")

		EndIf

		;proceed with ccopying the files if mcq is fine
		If $ExtractionResult=True Then

			;CORRECT THIS!!!!!

			;error to be passes to the copy handler for processing
			$ResultOfCopying = CopyWithProgress($Source, $Destination, $ErrorNumberMessage)

			;send error number returned by CopyWithProgress

			_MemoryWrite($MM_ErrorNumber_Pointer, $hKernDll, $ErrorNumberMessage , "int")


			;clear variables
			$Source=""
			$Destination=""

		EndIf

	WEnd

EndIf



Sleep(200)

WEnd

#EndRegion Main

;close IPC kernel dll handle before exit
_MemoryClose($hKernDll)

Exit

#Region Functions
;*******************************************************************************
;function handles copying files and folders using Win API dialogue box

Func CopyWithProgress($sFrom, $sTo, ByRef $ErrMessage_fc)

    ; version 1 by SumTingWong on 5/26/2006
    ; http://www.autoitscript.com/forum/index.php?showtopic=11888
    ; updated by lod3n on 6/5/2007

    Local $SHFILEOPSTRUCT
    Local $pFrom
    Local $pTo
    Local $aDllRet
    Local $nError = 0
    Local $i

    $SHFILEOPSTRUCT = DllStructCreate("int;uint;ptr;ptr;uint;int;ptr;ptr")
    If @error Then Return "nostruct"
; hwnd
    DllStructSetData($SHFILEOPSTRUCT, 1, 0)
; wFunc
    DllStructSetData($SHFILEOPSTRUCT, 2, $FO_COPY)
; pFrom
    $pFrom = DllStructCreate("char[" & StringLen($sFrom)+2 & "]")

; pFrom will now be null-terminated at StringLen($sFrom)+1
    DllStructSetData($pFrom, 1, $sFrom)
    For $i = 1 To StringLen($sFrom)+2
        If DllStructGetData($pFrom, 1, $i) = 10 Then DllStructSetData($pFrom, 1, 0, $i)
    Next
; We need a second null at the end
    DllStructSetData($pFrom, 1, 0, StringLen($sFrom)+2)
    DllStructSetData($SHFILEOPSTRUCT, 3, DllStructGetPtr($pFrom))
; pTo
    $pTo = DllStructCreate("char[" & StringLen($sTo)+2 & "]")
; pTo will now be null-terminated at StringLen($sTo)+1
    DllStructSetData($pTo, 1, $sTo)
; We need a second null at the end
    DllStructSetData($pTo, 1, 0, StringLen($sTo)+2)
    DllStructSetData($SHFILEOPSTRUCT, 4, DllStructGetPtr($pTo))

; fFlags
    DllStructSetData($SHFILEOPSTRUCT, 5, BitOR($FOF_NOCONFIRMMKDIR, _
        $FOF_NOCONFIRMATION, _
        $FOF_NOERRORUI))

; fAnyOperationsAborted
    DllStructSetData($SHFILEOPSTRUCT, 6, 0)
; hNameMappings
    DllStructSetData($SHFILEOPSTRUCT, 7, 0)
; lpszProgressTitle
    DllStructSetData($SHFILEOPSTRUCT, 8, 0)
    $aDllRet = DllCall("shell32.dll", "int", "SHFileOperation", "ptr", DllStructGetPtr($SHFILEOPSTRUCT))
	$retcode = $aDllRet[0]
	$pFrom = 0
    $pTo = 0
    $SHFILEOPSTRUCT = 0

    If $retcode <> 0 Then
;~ 		ConsoleWrite(hex($retcode) & ": " & SHFileOperationErrDecode($retcode) & @crlf)
		$ErrMessage_fc=$retcode
;~         SetError($nError)
        Return False
    EndIf

	$ErrMessage_fc=""
    Return True
EndFunc

;*******************************************************************************

;function extracts a single package of data from the queue and checks it's integrity
Func ExtractDataFromQueue(ByRef $QueueArray, ByRef $Source_FC, ByRef $Destination_FC)

	#include-once				;include these two if this is to me moved to any separate script
	#include "../Queue.au3"

	Local $tmp_STX, $tmp_destination, $tmp_ENQ, $tmp_source, $tmp_ETX, $DataOK

	;popping out data from the queue to temp variables

	$tmp_STX=_Queue_Pop($QueueArray)
	$tmp_destination=_Queue_Pop($QueueArray)
	$tmp_ENQ=_Queue_Pop($QueueArray)
	$tmp_source=_Queue_Pop($QueueArray)
	$tmp_ETX=_Queue_Pop($QueueArray)

	;perform data check

	$DataOK=True

	;check markers
	If $tmp_STX<>$MarkerSTX Then $DataOK=False
	If $tmp_ENQ<>$MarkerENQ Then $DataOK=False
	If $tmp_ETX<>$MarkerETX Then $DataOK=False

	;check if source string ends with 2 nulls
	If (StringRight($tmp_source,2))<> ($NullChar & $NullChar) Then $DataOK=False

	If $DataOK=False Then 	;data from mcq file is corrupt

		Return False
	EndIf

	;data is fine, proceeding
	$Source_FC= $tmp_source
	$Destination_FC= $tmp_destination

;~ 	; some debug info to log
;~ 	$DDebugstr= "peek "&_Queue_Peek($QueueArray)&" dest "&$Destination_FC&" source "& $Source_FC

;~ 	_FileWriteLog ($PathToLogFile, $DDebugstr)

	Return True

EndFunc

;************************************************************************************



#EndRegion
