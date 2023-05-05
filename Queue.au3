#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.12.0
 Author:         Przemyslaw Szoka (kibic)

 Script Function:
	queue handling functions

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here


#include-once
#include <Array.au3>


; #FUNCTION# ====================================================================================================================
; Name...........: _Queue_Create
; Description ...: Iniates a Queue
; Syntax.........: _Queue_Create(int size)
; Parameters ....: $size - The size of the Queue, the default is 20
;				   A Queue size will automatically double in size if needed, so the user doesn't need to worry about checking size
; Return values .: Success - Returns the array
;                  Failure - Returns false, only happens if you try passing a number less than 0
; Author ........: Achilles
; ===============================================================================================================================
Func _Queue_Create($size)
	If $size < 0 then Return False

	Local $QArray[$size + 1]

	$QArray[0] = 1 ;1 is the index to push/pop/peek at

	Return $QArray
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Queue_Empty
; Description ...: Empties a Queue
; Syntax.........: _Queue_Empty(Queue array)
; Parameters ....: $QArray - pass a Queue array item
; Return values .: Always returns true
; Author ........: Achilles
; ===============================================================================================================================
Func _Queue_Empty(ByRef $QArray)

	If $QArray[0]<=1 Then
		Return False

	Else

	For $i = 1 to $QArray[0]
		$QArray[$i-1] = ""
	Next

	ReDim $QArray[1]
	$QArray[0] = 1
	EndIf
	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Queue_GetSize
; Description ...: Returns the size of the Queue
; Syntax.........: _Queue_GetSize(Queue array)
; Parameters ....: $QArray - pass a Queue array item
; Return values .: Returns the size of the Queue
; Author ........: Achilles
; ===============================================================================================================================
Func _Queue_GetSize($QArray)
	Return $QArray[0] - 1
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Queue_IsEmpty
; Description ...: Checks if a Queue is empty
; Syntax.........: _Queue_IsEmpty(Queue array)
; Parameters ....: $QArray - pass a Queue array item
; Return values .: True if the Queue is empty, otherwise false
; Author ........: Achilles
; ===============================================================================================================================
Func _Queue_IsEmpty($QArray)

	If $QArray[0] = 1 Then
		Return True
		Else
	Return False
	EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Queue_Peek
; Description ...: Returns the item at the front of the Queue, without removing it from the Queue
; Syntax.........: _Queue_Peek(Queue array)
; Parameters ....: $QArray - pass a Queue array item
; Return values .: Returns the top item of a Queue without removing it
; Author ........: Achilles
; ===============================================================================================================================
Func _Queue_Peek($QArray)
	If Not _Queue_IsEmpty($QArray) then
		Return $QArray[1]
	Else
		Return -1
	EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Queue_Pop
; Description ...: Returns the item at the front of the Queue, removing it from the Queue
; Syntax.........: _Queue_Pop(Queue array)
; Parameters ....: $QArray - pass a Queue array item
; Return values .: Returns the item at the top of the Queue, removing it from the Queue
; Author ........: Achilles
; ===============================================================================================================================
Func _Queue_Pop(ByRef $QArray)
	If Not _Queue_IsEmpty($QArray) then
		$QArray[0] -= 1
		$ret = $QArray[1]
		_ArrayDelete($QArray, 1)
		ReDim $QArray[UBound($QArray) + 1]
		Return $ret
	Else
		Return -1
	EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Queue_Push
; Description ...: Adds an item to the end of a Queue
; Syntax.........: _Queue_Push(Queue array, $item)
; Parameters ....: $QArray - pass a Queue array item
;				   $item  - item to be added, can be anything that can be added to an array
; Return values .: Always returns true
; Author ........: Achilles
; ===============================================================================================================================
Func _Queue_Push(ByRef $QArray, $item)

	If UBound($QArray)<10 Then ReDim $QArray[10]

	If $QArray[0] + 1 > UBound($QArray) then

		ReDim $QArray[Floor(UBound($QArray) * 1.5)] ; 1.5 size if limit is reached
	EndIf


	$QArray[0] += 1
	$QArray[$QArray[0] - 1] = $item

	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........:		 _Queue_SaveToFile
; Description ...:		 saves queue to the specified file
; Syntax.........: 		_Queue_SaveToFile(Queue array, File path)
; Parameters ....: 	$QArray - pass a Queue array item
;				   			File path  - fullpath to file including filename
; Return values .: 	Always returns true
; ===============================================================================================================================

;~ Func _Queue_SaveToFile(ByRef $QArray, $FilePath)
;~
;~
;~
;~ EndFunc
