#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------
#include <File.au3>
; Script Start - Add your code below here



$temp = _FileListToArray(@ScriptDir,"*.txt")

Local $temp2;

;_ArrayDisplay($temp)

For $i = 1 to UBound($temp)-1

	$temp2 = StringTrimLeft($temp[$i],5) ;quitando el prefijo

	FileCopy(@ScriptDir & "/" & $temp[$i], @ScriptDir & "/" & $temp2, $FC_OVERWRITE)

	;FileDelete(@ScriptDir & "/" & $temp[$i])

	Next


