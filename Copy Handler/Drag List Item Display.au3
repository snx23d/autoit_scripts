#include <GuiConstantsEx.au3>
#include <DragList_UDF.au3>

$hGUI = GUICreate("_DragList_... Demo", 400, 200)

$nList1 = GUICtrlCreateList("", 20, 10, 160, 140, $WS_BORDER+$WS_VSCROLL)
GUICtrlSetData($nList1, "Hi,|How|Are|You?")

$nList2 = GUICtrlCreateList("", 220, 10, 160, 140, $WS_BORDER+$WS_VSCROLL)
GUICtrlSetData($nList2, "AutoIt|Is|The|Best!")

$SetList1_CheckBox = GUICtrlCreateCheckBox("Set List 1", 60, 160, 70, 20)
$SetList2_CheckBox = GUICtrlCreateCheckBox("Set List 2", 260, 160, 70, 20)

GUISetState(@SW_SHOW)

While 1
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			Exit
		Case $SetList1_CheckBox
			If GUICtrlRead($SetList1_CheckBox) = $GUI_CHECKED Then
				_DragList_SetList($nList1, $hGUI)
			Else
				_DragList_SetList($nList1)
			EndIf
		Case $SetList2_CheckBox
			If GUICtrlRead($SetList2_CheckBox) = $GUI_CHECKED Then
				_DragList_SetList($nList2, $hGUI)
			Else
				_DragList_SetList($nList2)
			EndIf
	EndSwitch
Wend
