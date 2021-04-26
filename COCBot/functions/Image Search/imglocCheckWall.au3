; #FUNCTION# ====================================================================================================================
; Name ..........: imglocCheckWall
; Description ...: Search for The Specific Wall Levels Using Imgloc Image Search *NEW* And Builder Icon List and then select them
;										To Upgrade at the next step.
; Syntax ........:
; Parameters ....:
; Return values .:
; Author ........: Trlopes (06-2016)
; Modified ......: Dissociable (2021)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func imglocCheckWall()
	Local $iXClickOffset = 0
	Local $iYClickOffset = 0
	Local $iXRange = 16
	Local $iYRange = 14
	Local $iLastGoodWallx = $g_aiLastGoodWallPos[0]
	Local $iLastGoodWally = $g_aiLastGoodWallPos[1]
	ConvertToVillagePos($iLastGoodWallx, $iLastGoodWally)

	If _Sleep(500) Then Return

	Local $levelWall = $g_iCmbUpgradeWallsLevel + 4

	Switch $levelWall
		Case 10
			$iXClickOffset = 2
			$iYClickOffset = 2
		Case 11
			$iXClickOffset = 1
			$iYClickOffset = -2
	EndSwitch


	SetLog("Searching for Wall(s) level: " & $levelWall & ". Using imgloc: ", $COLOR_SUCCESS)
	;name , level , coords
	Local $FoundWalls[1]
	$FoundWalls[0] = "" ; empty value to make sure return value filled
	If ($g_aiLastGoodWallPos[0] > 0) And ($g_aiLastGoodWallPos[1] > 0) Then ; Last known good position exists, trying to find upgradeable walls there
		_CaptureRegion2($iLastGoodWallx - $iXRange, $iLastGoodWally - $iYRange, $iLastGoodWallx + $iXRange, $iLastGoodWally + $iYRange)
		$FoundWalls = imglocFindWalls($levelWall, "FV", "FV", 4) ; lets get up to 4 surrounding points
		If $g_bDebugImageSave Then SaveDebugImage("WallUpgrade", False)
	EndIf
	If ($FoundWalls[0] = "") Then ; nothing found
		$g_aiLastGoodWallPos[0] = -1
		$g_aiLastGoodWallPos[1] = -1
		SetLog("No wall(s) next to previously upgraded found.", $COLOR_ERROR)
		SetLog("Looking further away.", $COLOR_SUCCESS)
		_CaptureRegion2()
		$FoundWalls = imglocFindWalls($levelWall, "ECD", "ECD", 10) ; lets get 10 points just to make sure we discard false positives
	EndIf

	;ClickP($aAway, 1, 0, "#0505") ; to prevent bot 'Anyone there ?'
	ClickAway()

	If ($FoundWalls[0] = "") Then ; nothing found
		SetLog("No wall(s) level: " & $levelWall & " found by image search.", $COLOR_ERROR)
		SetLog("Going for Plan B lmao...", $COLOR_INFO)

		ClickAway()
		If _sleep($DELAYAUTOUPGRADEBUILDING1) Then Return

		; check if builder head is clickable
		If Not (_ColorCheck(_GetPixelColor(275, 15, True), "F5F5ED", 20) = True) Then
			SetLog("Unable to find the Builder menu button... Exiting Auto Upgrade...", $COLOR_ERROR)
			Return False
		EndIf

		; open the builders menu
		Click(295, 30)
		If _Sleep($DELAYAUTOUPGRADEBUILDING1) Then Return False

		; Ensure that we're at the start of list
		Local $iXDragStart = Random(235, 380)
		Local $iYDragStart = Random(115, 135) + $g_iMidOffsetY
		ClickDrag($iXDragStart, $iYDragStart, $iXDragStart + Random(5, 20) - Random(5, 20), Random(400, 480))

		Local $iMaxLoop = Random(2, 5)
		For $k = 0 To $iMaxLoop
			Local $vResult = CheckForWallsInBuilderMenu($levelWall, $k > 0) ; Don't Scroll Down at the first loop
			If $vResult <> "" Then
				If $vResult = False Then
					SetLog("Wall upgrade is not suggested in Builder Menu", $COLOR_RED)
				EndIf
				Return $vResult
			EndIf
		Next
	Else
		For $i = 0 To UBound($FoundWalls) - 1
			Local $WallCoordsArray = decodeMultipleCoords($FoundWalls[$i])
			SetLog("Found: " & UBound($WallCoordsArray) & " possible Wall position: " & $FoundWalls[$i], $COLOR_SUCCESS)
			If ($g_aiLastGoodWallPos[0] > 0) And ($g_aiLastGoodWallPos[1] > 0) Then
				SetLog("relative to " & ($iLastGoodWallx - $iXRange) & ", " & ($iLastGoodWally - $iYRange) & ".", $COLOR_SUCCESS)
			EndIf
			For $fc = 0 To UBound($WallCoordsArray) - 1
				Local $aCoord = $WallCoordsArray[$fc]
				If ($g_aiLastGoodWallPos[0] > 0) And ($g_aiLastGoodWallPos[1] > 0) Then
					$aCoord[0] = $aCoord[0] + $iLastGoodWallx - $iXRange
					$aCoord[1] = $aCoord[1] + $iLastGoodWally - $iYRange
				EndIf
				$aCoord[0] = $aCoord[0] + $iXClickOffset
				$aCoord[1] = $aCoord[1] + $iYClickOffset
				SetLog("Checking if found position is a Wall and of desired level.", $COLOR_SUCCESS)
				;try click
				GemClick($aCoord[0], $aCoord[1])
				If _Sleep(500) Then Return
				Local $aResult = BuildingInfo(245, 490 + $g_iBottomOffsetY) ; Get building name and level with OCR
				If $aResult[0] = 2 Then ; We found a valid building name
					If StringInStr($aResult[1], "wall") = True And Number($aResult[2]) = $levelWall Then ; we found a wall
						SetLog("Position : " & $aCoord[0] & ", " & $aCoord[1] & " is a Wall Level: " & $levelWall & ".")
						$g_aiLastGoodWallPos[0] = $aCoord[0]
						$g_aiLastGoodWallPos[1] = $aCoord[1]
						ConvertFromVillagePos($g_aiLastGoodWallPos[0], $g_aiLastGoodWallPos[1])
						Return True
					Else
						;ClickP($aAway, 1, 0, "#0931") ;Click Away
						ClickAway()
						If $g_bDebugSetlog Then
							SetDebugLog("Position : " & $aCoord[0] & ", " & $aCoord[1] & " is not a Wall Level: " & $levelWall & ". It was: " & $aResult[1] & ", " & $aResult[2] & " !", $COLOR_DEBUG) ;debug
						Else
							SetLog("Position : " & $aCoord[0] & ", " & $aCoord[1] & " is not a Wall Level: " & $levelWall & ".", $COLOR_ERROR)
							SetDebugLog("It was: " & $aResult[1] & ", " & $aResult[2], $COLOR_DEBUG, True) ; log actual wall values to file log only
						EndIf
					EndIf
				Else
					;ClickP($aAway, 1, 0, "#0932") ;Click Away
					ClickAway()
				EndIf
			Next
		Next
		$g_aiLastGoodWallPos[0] = -1
		$g_aiLastGoodWallPos[1] = -1
	EndIf
	Return False

EndFunc   ;==>imglocCheckWall

Func CheckForWallsInBuilderMenu($wallLevel, $bScroll = Default)
	If ($bScroll = Default) Then
		$bScroll = True
	EndIf

	If $bScroll = True Then
		Local $iXDragStart = Random(235, 380)
		Local $iYDragStart = Random(340, 350) + $g_iMidOffsetY
		ClickDrag($iXDragStart, $iYDragStart, $iXDragStart + Random(5, 20) - Random(5, 20), $iYDragStart - Random(165, 175))
	EndIf

	If _Sleep($DELAYAUTOUPGRADEBUILDING1) Then Return False
	Local $sWallsInBuilderMenu = DFind($g_sBuilderMenuDMatB, 220, 70, 450, 400)

	If ($sWallsInBuilderMenu = "") Then Return "" ; If No Match Found for "Wall" in Builder Menu List

	Local $aDecodedDMatchingResult = DMDecodeMatches($sWallsInBuilderMenu)
	For $i = 0 To UBound($aDecodedDMatchingResult) - 1         ; Loop Through found "Wall" Text in Builder Menu List
		If StringInStr($aDecodedDMatchingResult[$i][0], "Wall", 0, 1) > 0 Then
			; Get the Cost
			Local $sTheCost = getOcrAndCaptureDOCR($g_sBuilderMenuPricesDOCRPath, $aDecodedDMatchingResult[$i][2], $aDecodedDMatchingResult[$i][3], 230, $aDecodedDMatchingResult[$i][5] + 5, False, False)
			SetLog("Found Wall Upgrade Suggestion that Costs " & $sTheCost, $COLOR_INFO)
			If $g_iWallCost == Number(StringStripWS(StringReplace($sTheCost, "|", ""), $STR_STRIPALL)) Then
				SetLog("Upgrading The Wall that Costs " & $sTheCost, $COLOR_SUCCESS)

				Click(Random($aDecodedDMatchingResult[$i][2], $aDecodedDMatchingResult[$i][2] + 200), $aDecodedDMatchingResult[$i][3], 1, 0, "Select Builder Menu Wall")         ; Click on The Wall Suggestion Text

				If _Sleep(500) Then Return False
				Local $aResult = BuildingInfo(245, 490 + $g_iBottomOffsetY)         ; Get building name and level with OCR
				If $aResult[0] = 2 Then         ; We found a valid building name
					If StringInStr($aResult[1], "wall") = True And Number($aResult[2]) = $wallLevel Then         ; we found a wall
						SetLog("Selected Wall is a Wall Level: " & $wallLevel & ".")
						Return True
					Else
						;ClickP($aAway, 1, 0, "#0931") ;Click Away
						ClickAway()
						If $g_bDebugSetlog Then
							SetDebugLog("Selected Wall is not a Wall Level: " & $wallLevel & ". It was: " & $aResult[1] & ", " & $aResult[2] & " !", $COLOR_DEBUG)         ;debug
						Else
							SetLog("Selected Wall is not a Wall Level: " & $wallLevel & ".", $COLOR_ERROR)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		Return ""
	Next
EndFunc   ;==>CheckForWallsInBuilderMenu

Func imglocFindWalls($wallLevel, $searcharea = "DCD", $redline = "", $maxreturn = 0)
	; Will find maxreturn Wall in specified diamond

	;name , level , coords
	Local $FoundWalls[1] = [""] ;

	Local $redLines = $redline
	Local $minLevel = (IsNumber($wallLevel) ? $wallLevel : 1)
	Local $maxLevel = (IsNumber($wallLevel) ? $wallLevel : 14)
	Local $maxReturnPoints = $maxreturn

	; Perform the search
	Local $result = DllCallMyBot("SearchMultipleTilesBetweenLevels", "handle", $g_hHBitmap2, "str", $g_sImgCheckWallDir, "str", $searcharea, "Int", $maxReturnPoints, "str", $redLines, "Int", $minLevel, "Int", $maxLevel)
	Local $error = @error ; Store error values as they reset at next function call
	Local $extError = @extended

	If $error Then
		_logErrorDLLCall($g_sLibMyBotPath, $error)
		SetLog(" imgloc DLL Error imgloc " & $error & " --- " & $extError, $COLOR_RED)
		SetError(2, $extError, $error) ; Set external error code = 2 for DLL error
		Return $FoundWalls
	EndIf

	If checkImglocError($result, "imglocFindWalls", $g_sImgCheckWallDir) = True Then
		Return $FoundWalls
	EndIf

	; Process results
	If $result[0] <> "" Then
		; Get the keys for the dictionary item.
		If $g_bDebugSetlog Then SetDebugLog(" imglocFindMyWall search returned : " & $result[0])
		Local $aKeys = StringSplit($result[0], "|", $STR_NOCOUNT)
		; Loop through the array
		ReDim $FoundWalls[UBound($aKeys)]
		For $i = 0 To UBound($aKeys) - 1
			; Get the property values
			; Loop through the found object names
			Local $aCoords = RetrieveImglocProperty($aKeys[$i], "objectpoints")
			$FoundWalls[$i] = $aCoords
		Next
	EndIf
	Return $FoundWalls
EndFunc   ;==>imglocFindWalls
