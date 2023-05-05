#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\ikony\MOJE\TreeEdit.ico
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Fileversion=0.0.0.1
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/reel
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/so
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.12.0

	;to do

	tooltip showing paths for mouseovered folder - maybe
	create help msgbox

	Script Function:
	MM tree editor
	makes MM tree and saves it to the file as 2d array, which is read later by the main program
	array consists of index, name visible in TreeView, record status and path associated with name

#ce ----------------------------------------------------------------------------
#Region include
#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <TreeViewConstants.au3>
#include <WindowsConstants.au3>
#include <GuiTreeView.au3>
#include <Constants.au3>
#include <File.au3>
#include <Array.au3>
#include "../Functions.au3"
#include "../_WriteFileToTV.au3"

#EndRegion include

Opt("GUICloseOnESC", 0)
Opt("GUIOnEventMode", 1)

Const $IniFileName = "MM_Tree"
Const $InitialArrayLength = 10 ;minimal value is 4!

Global Const $NewChildName = "New folder"
Global Const $NewRootName = "New root"
Global Const $SaveFileName = "MMPaths.dat"
Global Const $SaveFilePath = @ScriptDir & "\data\"

;~ Global variables
Global $bTreeEdit = False, $hDragItem, $hTreeDragImage, $fWhere

Global $MAIN_TV_Array[$InitialArrayLength][4] ;final array storing data from treeview
Global $AUX_TV_Array[$InitialArrayLength][2] ;auxiliary array

Global $NumberOfCheckedItems = 0, $count = 0
Global $TreeView_MM_Edit
Global $hRClickedItem = 0
Global $FirstFreeArrayIndex = 0

;final array is only created just before saving data from TV and associated paths with them
;all editing operation are conducted on the aux array
;
;main array structure
;[][0]		[][1]		[][2]		[][3]
;index		name		status	path

;auxiliary array structure
;[][0]		[][1]
;hWnd		path

;gui

#Region ### START Koda GUI section ### Form=f:\skrypty autoita\sdi\copy handler\form2.kxf
$Form2 = GUICreate("Media Mover tree editor", 378, 429, 231, 153)
GUISetIcon("F:\skrypty autoita\SDI\ikony\MOJE\TreeEdit.ico", -1)
$Button_Cancel = GUICtrlCreateButton("Cancel", 272, 384, 97, 33)
$TreeView_MM_Edit = GUICtrlCreateTreeView(0, 0, 233, 425, BitOR($GUI_SS_DEFAULT_TREEVIEW, $TVS_EDITLABELS, $TVS_CHECKBOXES, $WS_VSCROLL))
GUICtrlSetTip(-1, "Tree data structure to edit.")
$TreeView_MM_Editcontext = GUICtrlCreateContextMenu($TreeView_MM_Edit)
$Menu_ChangePath = GUICtrlCreateMenuItem("Change associated path", $TreeView_MM_Editcontext)
$Menu_Add = GUICtrlCreateMenuItem("Add new folder", $TreeView_MM_Editcontext)
$MenuI_Remove = GUICtrlCreateMenuItem("Remove", $TreeView_MM_Editcontext)
$Menu_Separator1 = GUICtrlCreateMenuItem("", $TreeView_MM_Editcontext)
$Menu_NewRoot = GUICtrlCreateMenuItem("New root", $TreeView_MM_Editcontext)
$Button_Help = GUICtrlCreateButton("Help", 272, 168, 97, 33)
GUICtrlSetTip(-1, "Help")
$Button_Ready = GUICtrlCreateButton("Save changes", 272, 312, 97, 33)
GUICtrlSetTip(-1, "Save changes to a database.")
$Button_ShowPaths = GUICtrlCreateButton("Show paths", 272, 240, 97, 33)
GUICtrlSetTip(-1, "Show current state of all entries in a list form.")
;~ $Button1 = GUICtrlCreateButton("DEBUG", 264, 96, 105, 41)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

;handle to the TV

Global Const $hTreeView_MM_Edit = GUICtrlGetHandle($TreeView_MM_Edit)

GUIRegisterMsg($WM_NOTIFY, "On_WM_NOTIFY")

;~ event functions
GUISetOnEvent($GUI_EVENT_CLOSE, "_Cancel_EV")
GUICtrlSetOnEvent($Button_Cancel, "_Cancel_EV")
GUICtrlSetOnEvent($Menu_Add, "_MenuAdd_EV")
GUICtrlSetOnEvent($Menu_NewRoot, "_MenuNewRoot_EV")
GUICtrlSetOnEvent($MenuI_Remove, "_MenuRemove_EV")
GUICtrlSetOnEvent($Menu_ChangePath, "_ChangeAssociatedPath_EV")
GUICtrlSetOnEvent($Button_Ready, "_ButtonReady_EV")
GUICtrlSetOnEvent($Button_ShowPaths, "_ButtonShowPaths_EV")
GUICtrlSetOnEvent($Button_Help, "_ButtonHelp_EV")
;~ GUICtrlSetOnEvent ($Button1, "_DEBUG_")		;DEBUG!!!, delete later

;retrieve data from file and put it to the main and aux arrays, also get free array index

_WriteFileToTV($MAIN_TV_Array, $AUX_TV_Array, $hTreeView_MM_Edit, $SaveFilePath & $SaveFileName, "Media Mover tree editor")
GetFreeArrayIndex()

;main loop

While 1

	Sleep(100)

	TreeKeyboardFunc($TreeView_MM_Edit)
WEnd

Exit

#Region functions
;**************************************************************************
Func _ButtonHelp_EV()

	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
	MsgBox($MB_OK + $MB_ICONASTERISK, "Tree Editor", "Tree editor - allows creating and makeing changes to the data tree structures, like Media Mover folder tree. " & _
			@CRLF & @CRLF & "For the simplicity, there are only 2 levels of a tree structure. " & _
			@CRLF & "First one is just a root level - every one contains a number of leaves with some data connected to it. In a case of Media Mover tree this data is a path to a folder." & _
			@CRLF & @CRLF & "User can delete entries in the tree, add new ones, change associated names and paths.")
	#EndRegion --- CodeWizard generated code Start ---

	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
	MsgBox($MB_OK + $MB_ICONASTERISK, "Tree Editor", "To edit the data tree, right click on the white field on the left, context menu will show up with the following options:" & _
			@CRLF & @CRLF & "Change associated path - allows change of associated path with an existing entry (leaf)," & _
			@CRLF & @CRLF & "Add new folder - adds new entry to existing structure," & @CRLF & _
			@CRLF & "Remove - removes selected entry without prompt." & @CRLF & _
			"Roots can be removed as well, however they have to be empty," & @CRLF & @CRLF & _
			"New root - adds new root. No data is associated with a root itself.")
	#EndRegion --- CodeWizard generated code Start ---

	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
	MsgBox($MB_OK + $MB_ICONASTERISK, "Tree Editor", "To select an entry for edit purpose, click on it or use arrows to move through the tree. " & _
			"Please note that marking checkboxes does not do anything - these are here just for a consistency" & @CRLF & @CRLF & _
			"To change the name of the selected entry either 2x left click on it slowly or press an 'Enter' key. To stop name edition and save change, left click anywhere on the window or press the 'Esc' key.")
	#EndRegion --- CodeWizard generated code Start ---

	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
	MsgBox($MB_OK + $MB_ICONASTERISK, "Tree Editor", "Buttons:" & @CRLF & @CRLF & _
			"Help - triggers these help messages," & @CRLF & @CRLF & _
			"Show paths - shows the entire data tree structure in a list form," & @CRLF & @CRLF & _
			"Save changes - saves the data tree to the database file," & @CRLF & @CRLF & _
			"Cancel - exit this editor.")
	#EndRegion --- CodeWizard generated code Start ---

EndFunc   ;==>_ButtonHelp_EV

;**************************************************************************

Func _ButtonReady_EV()

	Local $Result1, $Result2, $Result3

	$Result1 = CreateMainArray()

	If $Result1 = -1 Then Return

;~ 	_ArrayDisplay($MAIN_TV_Array, "Main Array")

	;create folder for file if it doesn't exist

	$Result2 = 15
	If DirGetSize($SaveFilePath) = -1 Then $Result = DirCreate($SaveFilePath)

	If $Result2 = 0 Then
		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical, Modality=Task Modal
		MsgBox($MB_OK + $MB_ICONHAND + $MB_TASKMODAL, "Tree Editor", "Error during folder creation.")
		#EndRegion --- CodeWizard generated code Start ---
	EndIf

	$Result3 = _FileWriteFromArray($SaveFilePath & $SaveFileName, $MAIN_TV_Array, 0)

	Switch @error
		Case 3
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical, Modality=Task Modal
			MsgBox($MB_OK + $MB_ICONHAND + $MB_TASKMODAL, "Tree Editor", "Error writing to file.")
			#EndRegion --- CodeWizard generated code Start ---
			Return
		Case 1
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical, Modality=Task Modal
			MsgBox($MB_OK + $MB_ICONHAND + $MB_TASKMODAL, "Tree Editor", "Error opening specified file or path does not exist.")
			#EndRegion --- CodeWizard generated code Start ---

	EndSwitch

	If $Result3 = 1 Then

		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
		MsgBox($MB_OK + $MB_ICONASTERISK, "Tree Editor", "Data saved successfully.")
		#EndRegion --- CodeWizard generated code Start ---
	EndIf

EndFunc   ;==>_ButtonReady_EV

;**************************************************************************

Func _ButtonShowPaths_EV()
	If CreateMainArray() <> -1 Then
		_ArrayDisplay($MAIN_TV_Array, "MM paths display", Default, 32 + 64, Default, "Index|Name|Level|Path", Default, 0xDDFFDD)
	EndIf
EndFunc   ;==>_ButtonShowPaths_EV
;*****************************************************************************

Func _Cancel_EV()
	GUIDelete()
	$MAIN_TV_Array = 0
	$AUX_TV_Array = 0
	Exit
EndFunc   ;==>_Cancel_EV
;**************************************************************************

Func _ChangeAssociatedPath_EV()
	Local $hSelectedItem, $count_1, $FoundIndex, $SelectedPath

	$hSelectedItem = _GUICtrlTreeView_GetSelection($hTreeView_MM_Edit)
	;find selected item in aux array, run selectfolder function,
	;assign new path with hwnd

	$FoundIndex = 0
	$count_1 = 0

	Do

		If $AUX_TV_Array[$count_1][0] = $hSelectedItem Then $FoundIndex = $count_1
		$count_1 = $count_1 + 1

	Until $FoundIndex <> 0 Or $count_1 = UBound($AUX_TV_Array, $UBOUND_ROWS)
	;untill found proper index or reached array bound

	$SelectedPath = ChooseFolder($IniFileName)
	If $SelectedPath = "" Then Return ;exit FC if nothing was selected without saving any changes

	$AUX_TV_Array[$FoundIndex][1] = $SelectedPath

EndFunc   ;==>_ChangeAssociatedPath_EV

;******************************************************************************

Func _MenuAdd_EV()

	Local $IndentationLevel, $SelectedPath

	_GUICtrlTreeView_BeginUpdate($hTreeView_MM_Edit)

	;check if TV is empty, if so add new root and new branch

	If _GUICtrlTreeView_GetCount($TreeView_MM_Edit) = 0 Then
		$SelectedPath = ChooseFolder($IniFileName)
		If $SelectedPath = "" Then Return

		$NewRoot = GUICtrlCreateTreeViewItem($NewRootName, $TreeView_MM_Edit)
		$NewRoot = GUICtrlGetHandle($NewRoot)
		$NewChild = _GUICtrlTreeView_AddChild($hTreeView_MM_Edit, $NewRoot, $NewChildName)
		SelectFirstItem($hTreeView_MM_Edit)
		_GUICtrlTreeView_EndUpdate($hTreeView_MM_Edit)

		;array operations

		;new root
		$AUX_TV_Array[0][0] = $NewRoot
		$AUX_TV_Array[0][1] = ""
ConsoleWrite($FirstFreeArrayIndex &@CR&" "UBound($AUX_TV_Array, $UBOUND_ROWS)
		;new child
		$AUX_TV_Array[1][0] = $NewChild ;hwnd
		$AUX_TV_Array[1][1] = $SelectedPath ;path

		$FirstFreeArrayIndex = 2
;~ 		_ArrayDisplay($AUX_TV_Array,"aux")
		Return

	EndIf

	;check if selected item is a child already, if yes then add sibling, otherwise add child

	$hSelectedItem = _GUICtrlTreeView_GetSelection($hTreeView_MM_Edit)
	$IndentationLevel = _GUICtrlTreeView_Level($hTreeView_MM_Edit, $hSelectedItem)

	Local $SelectedPath = ChooseFolder($IniFileName)

	;check if no new folder was selected, if so then exit function withoun makeing any changes
	If $SelectedPath = "" Then Return

	Switch $IndentationLevel
		Case 0 ;root, add child
			$NewItem = _GUICtrlTreeView_AddChild($hTreeView_MM_Edit, $hSelectedItem, $NewChildName)

		Case 1 ;child already, add sibling
			$NewItem = _GUICtrlTreeView_Add($hTreeView_MM_Edit, $hSelectedItem, $NewChildName)

		Case Else
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical, Modality=Task Modal
			MsgBox($MB_OK + $MB_ICONHAND + $MB_TASKMODAL, "Tree editor", "I think we may have a problem..." & @CRLF & "Indentation level 2 reached, unsupported.")
			#EndRegion --- CodeWizard generated code Start ---

	EndSwitch

	;check if array should be redimed in order to have space for a new element

	If $FirstFreeArrayIndex + 3 > UBound($AUX_TV_Array, $UBOUND_ROWS) Then
		ReDim $AUX_TV_Array[Floor(UBound($AUX_TV_Array) * 1.6)][2]
	EndIf

	$AUX_TV_Array[$FirstFreeArrayIndex][0] = $NewItem ;hwnd
	$AUX_TV_Array[$FirstFreeArrayIndex][1] = $SelectedPath ;path

	$FirstFreeArrayIndex = $FirstFreeArrayIndex + 1
	$SelectedPath = 0

	;refresh TV

	_GUICtrlTreeView_EndUpdate($hTreeView_MM_Edit)

EndFunc   ;==>_MenuAdd_EV

;*****************************************************************************
Func _MenuNewRoot_EV()
	Local $NewRoot
;~ 	_GUICtrlTreeView_BeginUpdate ( $hTreeView_MM_Edit )

	;check if array should be redimed in order to have space for a new element

	If $FirstFreeArrayIndex + 1 > UBound($AUX_TV_Array, $UBOUND_ROWS) Then
		ReDim $AUX_TV_Array[Floor(UBound($AUX_TV_Array) * 1.6)][2]
	EndIf

	$hSelectedItem = _GUICtrlTreeView_GetSelection($hTreeView_MM_Edit)
	$NewRoot = _GUICtrlTreeView_Add($hTreeView_MM_Edit, $hSelectedItem, $NewRootName)

	;add new root to aux array
	$AUX_TV_Array[$FirstFreeArrayIndex][0] = $NewRoot ;hwnd
	$AUX_TV_Array[$FirstFreeArrayIndex][1] = ""

	SelectFirstItem($hTreeView_MM_Edit)
	$FirstFreeArrayIndex = $FirstFreeArrayIndex + 1

;~ 	_GUICtrlTreeView_EndUpdate($hTreeView_MM_Edit)

EndFunc   ;==>_MenuNewRoot_EV

;******************************************************************************

Func _MenuRemove_EV()

;~ 	check if selected item is a root and if it is empty, if not msgbox, if yes then
;~		it can be deleted
;~		both HAS to be True

	Local $hSelectedItem = _GUICtrlTreeView_GetSelection($hTreeView_MM_Edit)
	Local $IndentationLevel = _GUICtrlTreeView_Level($hTreeView_MM_Edit, $hSelectedItem)
	Local $hFirstChild = _GUICtrlTreeView_GetFirstChild($hTreeView_MM_Edit, $hSelectedItem)

	Local $hWnd = GUICtrlGetHandle($TreeView_MM_Edit)
	Local $aRet = DllCall('user32.dll', 'hwnd', 'GetFocus')

;~ 	ConsoleWrite(_GUICtrlTreeView_GetFirstChild ( $TreeView_MM_Edit, $hSelectedItem ))
;~ ConsoleWrite($IndentationLevel)

	Select

		Case ($hFirstChild = 0x00000000) And ($IndentationLevel = 0)
			;no childs, empty root, to be deleted

			If $aRet[0] = $hWnd Then
				RemoveSelectedItem($hSelectedItem)
				_GUICtrlTreeView_Delete($hWnd, _GUICtrlTreeView_GetSelection($hWnd)) ;delete
			EndIf

		Case ($hFirstChild = 0x00000000) And ($IndentationLevel = 1)
			;child, can be deleted
			If $aRet[0] = $hWnd Then
				RemoveSelectedItem($hSelectedItem)
				_GUICtrlTreeView_Delete($hWnd, _GUICtrlTreeView_GetSelection($hWnd)) ;delete
			EndIf

		Case ($hFirstChild <> 0x00000000) And ($IndentationLevel = 0)
			;root has childs, error message

			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical, Modality=Task Modal
			MsgBox($MB_OK + $MB_ICONHAND + $MB_TASKMODAL, "Tree Editor", "Root you are trying to delete is not empty." & _
					@CRLF & "In order to delete it remove all it's content first.")
			#EndRegion --- CodeWizard generated code Start ---

			Return

	EndSelect

EndFunc   ;==>_MenuRemove_EV
;****************************************************************

Func CreateMainArray()

	Local Const $hFirstItemInTV = _GUICtrlTreeView_GetFirstItem($hTreeView_MM_Edit)
	Local Const $NumberOfItemsInTv = _GUICtrlTreeView_GetCount($hTreeView_MM_Edit)

	Local $count, $countFind, $hCurrentItem, $SizeOfAUXArray

	;check if TV is empty

	If $hFirstItemInTV = 0x00000000 Or $NumberOfItemsInTv = 0 Then

		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical, Modality=Task Modal
		MsgBox($MB_OK + $MB_ICONHAND + $MB_TASKMODAL, "Tree Editor", "No paths were added. Cannot save empty database.")
		#EndRegion --- CodeWizard generated code Start ---

		Return -1
	EndIf

	;main array structure
	;[][0]		[][1]		[][2]		[][3]
	;index		name		status	path

	;redim main array to fit the content of TV

	ReDim $MAIN_TV_Array[$NumberOfItemsInTv][4]

	$SizeOfAUXArray = UBound($AUX_TV_Array, $UBOUND_ROWS) ;number of rows in aux

	;go through the entire TV recurently, for each name copy values from aux to the main

	$hCurrentItem = $hFirstItemInTV ;_GUICtrlTreeView_GetNext ( $hTreeView_MM_Edit, $hFirstItemInTV)

;~ 	_ArrayDisplay($MAIN_TV_Array, "main array")
;~ 	_ArrayDisplay($AUX_TV_Array, "aux array")

	For $count = 0 To $NumberOfItemsInTv - 1

		$MAIN_TV_Array[$count][0] = $count
		$MAIN_TV_Array[$count][1] = _GUICtrlTreeView_GetText($hTreeView_MM_Edit, $hCurrentItem)
		$MAIN_TV_Array[$count][2] = _GUICtrlTreeView_Level($hTreeView_MM_Edit, $hCurrentItem)

		;path has to be found in the aux array

		For $countFind = 0 To $SizeOfAUXArray - 1

			If $AUX_TV_Array[$countFind][0] = $hCurrentItem Then
				;copy path from aux to main for the same hwnd
;~ 				ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $count = ' & $count & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
;~ 				ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $countFind = ' & $countFind & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
				$MAIN_TV_Array[$count][3] = $AUX_TV_Array[$countFind][1]
			EndIf
		Next

		$hCurrentItem = _GUICtrlTreeView_GetNext($hTreeView_MM_Edit, $hCurrentItem)
;~ 		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $hCurrentItem = ' & $hCurrentItem & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

	Next
;~ 	_ArrayDisplay($MAIN_TV_Array, "main array")
	Return

EndFunc   ;==>CreateMainArray

;***********************************************************************************
Func GetFreeArrayIndex()
	Local $count_1

	;go through entire aux array, find row with no data
	$count_1 = 0
	Do

		If ($AUX_TV_Array[$count_1][0] = "") And ($AUX_TV_Array[$count_1][1] = "") Then $FirstFreeArrayIndex = $count_1
		$count_1 = $count_1 + 1
;~ 		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $count_1 = ' & $count_1 & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

	Until $FirstFreeArrayIndex <> 0 Or $count_1 = UBound($AUX_TV_Array, $UBOUND_ROWS)

	If $FirstFreeArrayIndex = 0 Then $FirstFreeArrayIndex = UBound($AUX_TV_Array, $UBOUND_ROWS)

;~ 	;redim array if free index is near the end

;~ 	If $FirstFreeArrayIndex+3>UBound($AUX_TV_Array, $UBOUND_ROWS) Then
;~ 		ReDim $AUX_TV_Array[Floor(UBound($AUX_TV_Array) * 1.6)][2]
;~ 	EndIf

EndFunc   ;==>GetFreeArrayIndex

;***********************************************************************************
Func KeyPressed($iHexKey)
	Local $aRet = DllCall('user32.dll', "int", "GetAsyncKeyState", "int", $iHexKey)
;~ 	If BitAND($aRet[0], 0x8000) Or BitAND($aRet[0], 1) Then Return 1
	If BitAND($aRet[0], 1) Then Return 1
	Return 0
EndFunc   ;==>KeyPressed
;*****************************************************************************

Func On_WM_NOTIFY($hWnd, $Msg, $wParam, $lParam)
	;wparam = cid, lparam = pnmh
	If $wParam = $TreeView_MM_Edit Then
		Local $tNMHDR = DllStructCreate("hwnd hTree;int_ptr;int code", $lParam) ;works for both 32 and 64 bit ver
;~ 		Local $tNMHDR = DllStructCreate("hwnd hTree;uint;int code", $lParam); 32 bit version
		Local $code = DllStructGetData($tNMHDR, "code")
		Local $hTree = HWnd(DllStructGetData($tNMHDR, "hTree"))

;~ 		ConsoleWrite($hWnd & "   " & $Msg & "   " & $wParam  & "   " & $lParam & "   " & $code &"  "& @CR)

		Switch $code

			Case $TVN_BEGINLABELEDITA, $TVN_BEGINLABELEDITW
				$bTreeEdit = True
;~ 				$hTreeEdit = _SendMessage($hTree, $TVM_GETEDITCONTROL, 0, 0)

			Case $TVN_ENDLABELEDITA, $TVN_ENDLABELEDITW
				$bTreeEdit = False

				Return 1
			Case $TVN_SELCHANGEDA, $TVN_SELCHANGEDW
				Local $hSel = _GUICtrlTreeView_GetSelection($hTree)
;~ 				Local $tNMTREEVIEW = DllStructCreate($tagNMTREEVIEW, $lParam)
;~ 				Local $hSel = DllStructGetData($tNMTREEVIEW, "NewhItem")
				Local $sTxt = "Currently selected: " & _GUICtrlTreeView_GetText($hTree, $hSel) & " (item handle " & $hSel & ")" ;DELETE THIS
;~ 				ConsoleWrite($sTxt &@CR)		;DELETE THIS

			Case $NM_RCLICK

				$hRClickedItem = TreeItemFromPoint($hTreeView_MM_Edit)
;~ 				ConsoleWrite($hRClickedItem &@CR)
				If $hRClickedItem = 0x0 Then
					;empty space was clicked, set focus on the 1st item
					SelectFirstItem($hTreeView_MM_Edit)
				Else

					_GUICtrlTreeView_SelectItem($hTreeView_MM_Edit, $hRClickedItem)
				EndIf

				;check if TV is empty, if yes then grey out remove and change path context menu

				If _GUICtrlTreeView_GetCount($TreeView_MM_Edit) = 0 Then
					GUICtrlSetState($MenuI_Remove, $GUI_DISABLE)
					GUICtrlSetState($Menu_ChangePath, $GUI_DISABLE)
				Else
					GUICtrlSetState($MenuI_Remove, $GUI_ENABLE)
					GUICtrlSetState($Menu_ChangePath, $GUI_ENABLE)
				EndIf

				;grey out change path context menu if root was clicked

				If _GUICtrlTreeView_Level($hTreeView_MM_Edit, $hRClickedItem) = 0 Then
					GUICtrlSetState($Menu_ChangePath, $GUI_DISABLE)
				Else
					GUICtrlSetState($Menu_ChangePath, $GUI_ENABLE)
				EndIf

				$hRClickedItem = 0

			Case Else
		EndSwitch
	EndIf
EndFunc   ;==>On_WM_NOTIFY

;*****************************************************************************

;function removes item based on the given handle, updates aux array
;also decreases $FirstFreeArrayIndex by 1

Func RemoveSelectedItem($hItemHandle)
	;delete that row, move up all below,
	;decrease by 1 $FirstFreeArrayIndex

	Local $SizeOfAUXArray = UBound($AUX_TV_Array, $UBOUND_ROWS)
	Local $countFind, $FoundIndex

	;go through entire array, find matching hwnd
	For $countFind = 0 To $SizeOfAUXArray - 1
		If $AUX_TV_Array[$countFind][0] = $hItemHandle Then $FoundIndex = $countFind
	Next
	;transpose array, delete found COLUMN, transpose again

	_ArrayTranspose($AUX_TV_Array)
	_ArrayColDelete($AUX_TV_Array, $FoundIndex, False)
	_ArrayTranspose($AUX_TV_Array)

	$FirstFreeArrayIndex = $FirstFreeArrayIndex - 1

EndFunc   ;==>RemoveSelectedItem
;*****************************************************************************
Func SelectFirstItem($hWnd)
	Local $FirstItem = _GUICtrlTreeView_GetFirstItem($hWnd)
	_GUICtrlTreeView_SelectItem($hWnd, $FirstItem)
EndFunc   ;==>SelectFirstItem

;*****************************************************************************

Func TreeKeyboardFunc($cID)
	Local $hWnd = GUICtrlGetHandle($cID)
	If $bTreeEdit Then
		If KeyPressed(0x0d) Then _SendMessage($hWnd, $TVM_ENDEDITLABELNOW, 0, 0) ;enter
		If KeyPressed(0x1b) Then _SendMessage($hWnd, $TVM_ENDEDITLABELNOW, 1, 0) ;esc
	EndIf
	Local $aRet = DllCall('user32.dll', 'hwnd', 'GetFocus')
	If $aRet[0] = $hWnd Then
;~ 		If KeyPressed(0x2d) Then _GUICtrlTreeView_Add($hWnd, _GUICtrlTreeView_GetSelection($hWnd), $NewRootName) ;insert
;~ 		If KeyPressed(0x2e) Then _GUICtrlTreeView_Delete($hWnd, _GUICtrlTreeView_GetSelection($hWnd)) ;delete
		If KeyPressed(0x0d) Then _SendMessage($hWnd, $TVM_EDITLABELW, 0, _GUICtrlTreeView_GetSelection($hWnd)) ;enter
	EndIf
EndFunc   ;==>TreeKeyboardFunc

;********************************************************************************
;returns handle to the item under cursor

Func TreeItemFromPoint($hWnd)
	Local $tMPos = _WinAPI_GetMousePos(True, $hWnd)
;~ 	ConsoleWrite(DllStructGetData($tMPos, 1)&" "&DllStructGetData($tMPos, 2)&@CR)
	Return _GUICtrlTreeView_HitTestItem($hWnd, DllStructGetData($tMPos, 1), DllStructGetData($tMPos, 2))
EndFunc   ;==>TreeItemFromPoint

;********************************************************************************

Func _DEBUG_()
;~ 	RemoveSelectedItem($hTreeView_MM_Edit)
	_WriteFileToTV($MAIN_TV_Array, $AUX_TV_Array, $hTreeView_MM_Edit, $SaveFilePath & $SaveFileName, "Media Mover tree editor")
	GetFreeArrayIndex()
;~ ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $FirstFreeArrayIndex = ' & $FirstFreeArrayIndex & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
;~ ConsoleWrite(UBound($AUX_TV_Array, $UBOUND_ROWS))
;~ _ArrayDisplay($AUX_TV_Array, "AUX")
EndFunc   ;==>_DEBUG_

#EndRegion functions
