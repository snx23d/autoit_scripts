#include-once
#include <GuiListBox.au3>
#include <WindowsConstants.au3>
;

;'Windows API Constants
Global Const $DRAGLISTMSGSTRING 	= "commctrl_DragListMsg"
Global Const $DL_BEGINDRAG 			= $WM_USER + 133
Global Const $DL_DRAGGING 			= $WM_USER + 134
Global Const $DL_DROPPED 			= $WM_USER + 135
Global Const $DL_CANCELDRAG 		= $WM_USER + 136

;~ Global Const $LB_ITEMFROMPOINT 		= 0x1A9

Global $iBeginDragID
Global $aDragList_Array[1][1]
Global $nDragListMessage = -1

Func _DragList_SetList($n_List, $hWnd=0)
	If $hWnd = 0 Then
		Local $aTmpArr[1][1]
		
		For $i = 1 To $aDragList_Array[0][0]
			If $aDragList_Array[$i][0] <> $n_List Then
				$aTmpArr[0][0] += 1
				ReDim $aTmpArr[$aTmpArr[0][0]+1][2]
				$aTmpArr[$aTmpArr[0][0]][0] = $aDragList_Array[$i][0]
				$aTmpArr[$aTmpArr[0][0]][1] = $aDragList_Array[$i][1]
			Else
				_DragList_ResetScreen($aDragList_Array[$i][1])
			EndIf
		Next
		
		$aDragList_Array = $aTmpArr
		
		If $aDragList_Array[0][0] < 1 Then
			GUIRegisterMsg($nDragListMessage, "")
			$nDragListMessage = -1
		EndIf
		
		Return
	EndIf
	
	$aDragList_Array[0][0] += 1
	ReDim $aDragList_Array[$aDragList_Array[0][0]+1][2]
	$aDragList_Array[$aDragList_Array[0][0]][0] = $n_List
	$aDragList_Array[$aDragList_Array[0][0]][1] = $hWnd
	
	_DragList_Create($n_List)
	
	If $nDragListMessage <> -1 Then Return
	
	$nDragListMessage = DllCall("user32.dll", "int", "RegisterWindowMessage", "str", $DRAGLISTMSGSTRING)
	$nDragListMessage = $nDragListMessage[0]
	
	GUIRegisterMsg($nDragListMessage, "_DragList_Handler")
EndFunc

Func _DragList_Handler($hWnd, $nMsg, $wParam, $lParam)
	#cs from msdn:
		The wParam parameter of the drag list message is the control identifier for the drag list box.
		The lParam parameter is the address of a DRAGLISTINFO structure,
		which contains the notification code for the drag event and other information.
		The return value of the message depends on the notification
	#ce
	
	Local $nID = BitAND($wParam, 0x0000FFFF)
	
	For $i = 1 To $aDragList_Array[0][0]
		If $nID = $aDragList_Array[$i][0] Then
			Local $stDraglistInfo = DllStructCreate("uint;hwnd;int;int", $lParam)
			Local $nNotifyCode = DllStructGetData($stDraglistInfo, 1)
			Local $hList = DllStructGetData($stDraglistInfo, 2)
			Local $n_List = $aDragList_Array[$i][0]
			
			Local $stPoint = DllStructCreate("int;int")
			
			DllStructSetData($stPoint, 1, DllStructGetData($stDraglistInfo, 3))
			DllStructSetData($stPoint, 2, DllStructGetData($stDraglistInfo, 4))
			
			Switch $nNotifyCode
				Case $DL_BEGINDRAG
					$iBeginDragID = _DragList_GetItemFromPoint($hList, $stPoint)
					Return 1
				Case $DL_CANCELDRAG
					_DragList_ResetScreen($hWnd)
					Return 1
				Case $DL_DRAGGING
					Local $iEndDragID = _DragList_GetItemFromPoint($hList, $stPoint)
					_DragList_DrawInsertArrow($hWnd, $hList, $iEndDragID)
				Case $DL_DROPPED
					_DragList_ResetScreen($hWnd)
					Local $iEndDragID = _DragList_GetItemFromPoint($hList, $stPoint)
					Local $sBeginDragItemText = _GUICtrlListBox_GetText($n_List, $iBeginDragID)
					
					If $iBeginDragID = $iEndDragID Or $iEndDragID = -1 Then Return 1
					
					If $iBeginDragID > $iEndDragID Then ;Drag from bottom to top
						_GUICtrlListBox_InsertString($n_List, $sBeginDragItemText, $iEndDragID)
						_GUICtrlListBox_DeleteString($n_List, $iBeginDragID+1)
						_GUICtrlListBox_SelectString($n_List, $sBeginDragItemText, $iEndDragID)
					ElseIf $iBeginDragID < $iEndDragID Then ;Drag from top to bottom
						_GUICtrlListBox_InsertString($n_List, $sBeginDragItemText, $iEndDragID)
						_GUICtrlListBox_DeleteString($n_List, $iBeginDragID)
						_GUICtrlListBox_SelectString($n_List, $sBeginDragItemText, $iEndDragID-1)
					EndIf
					
					Return 1
			EndSwitch
		
			ExitLoop
		EndIf
	Next
	
	Return $GUI_RUNDEFMSG
EndFunc

Func _DragList_Create($hWnd)
	If Not IsHwnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	
	Local $aRet = DllCall("comctl32.dll", "int", "MakeDragList","hwnd", $hWnd) ;$aRet is 0 if unsucccesful
	Return $aRet[0]
EndFunc

Func _DragList_DrawInsertArrow($hWnd, $hList, $nItem)
	Local $aRet = DllCall("comctl32.dll", "int", "DrawInsert", "hwnd", $hWnd, "hwnd", $hList, "int", $nItem)
	Return $aRet[0]
EndFunc

Func _DragList_GetItemFromPoint($hList, $stPoint, $iAutoscroll = 0)
	;The return value contains the index of the nearest item in the low-order word.
	;The high-order word is zero if the specified point is in the client area of the list box,
	;or one if it is outside the client area.>>>Note. this call to sendmessage always results in the same number<<<
	Local $iX = DllStructGetData($stPoint, 1)
	Local $iY = DllStructGetData($stPoint, 2)
	
	Local $aRet = DllCall("comctl32.dll", "int", "LBItemFromPt", "hwnd", $hList, "int", $iX, "int", $iY,  "int", $iAutoscroll)
	Return $aRet[0]
EndFunc

Func _DragList_ResetScreen($hWnd)
	DllCall("User32.dll", "int", "RedrawWindow", "hwnd", $hWnd, "ptr", 0, "int", 0, "int", 5)
	
;~ 	Local Const $SWP_NOMOVE = 0x0002, $SWP_NOSIZE = 0x0001, $SWP_NOZORDER = 0x0004, $SWP_FRAMECHANGED = 0x0020 ;from Winuser.h
;~ 	
;~ 	DllCall("user32.dll", "long", "SetWindowPos", "hwnd", $hWnd, _
;~ 		"hwnd", $hWnd, "int", 0, "int", 0, "int", 0, "int", 0, _
;~ 		"long", BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
EndFunc
