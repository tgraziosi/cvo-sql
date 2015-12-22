SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspDimensionSetList]
            @PlanID	int,
            @CubeName   varchar(40)
	-------------------------------------------------------------------
	--@CubeName - fill with cube you are working on (if any)         --
        --this way the list will include the dimension set you were using--
	----------------------------------------------------------------------------
WITH ENCRYPTION
AS
BEGIN
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/
	---------------------------
	--Create Temporary Tables--
	---------------------------
	CREATE TABLE #mbbmSheetRecursion
	(
	 SheetID        int     	Null,
	 Dimensions     varchar(255)    Null
        )

	DECLARE		@SheetID	int,
			@Code    	varchar(255)

	------------------------------------------
	--Create accumulation records for sheets--
	------------------------------------------
	INSERT   	#mbbmSheetRecursion
	SELECT 		SheetID, ''
        FROM   		mbbmPlanSheet74
        WHERE           PlanID = @PlanID
        AND             SheetType = 0
        AND             ActiveRevision <> 0
	AND             Publish = 1
        ORDER BY	SheetID

	CREATE INDEX #mbbmSheetRecursionIndex ON #mbbmSheetRecursion (SheetID)

	--------------------------------------------------------
	--Update the #mbbmSheetRecursion table with dimensions--
	--------------------------------------------------------
	DECLARE	crsSheetRecursion CURSOR FOR 
	SELECT 		s.SheetID,
			RTRIM(d.Code)
	FROM            mbbmPlanSheet74 s INNER JOIN mbbmPlanSheetRev74 r ON (s.ActiveRevision = r.RevisionID) 
			LEFT OUTER JOIN mbbmPlanSheetDimensions74 d ON (r.RevisionID = d.RevisionID)
	WHERE           s.PlanID = @PlanID
        AND             s.SheetType = 0
        AND             s.ActiveRevision <> 0
	AND             Publish = 1
	ORDER BY	s.SheetID, d.Code

	OPEN crsSheetRecursion
	FETCH NEXT FROM crsSheetRecursion INTO @SheetID, @Code

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE #mbbmSheetRecursion
                SET    Dimensions = Dimensions + ';' + @Code
		WHERE  SheetID = @SheetID

		FETCH NEXT FROM crsSheetRecursion INTO @SheetID, @Code
	END

	CLOSE crsSheetRecursion 
	DEALLOCATE crsSheetRecursion 

	-------------------------------------------------------------
	--Remove initial space caused by db compatibility set to 65--
	-------------------------------------------------------------
	UPDATE	#mbbmSheetRecursion
	SET 	Dimensions = RIGHT(Dimensions, LEN(Dimensions)-1)
	WHERE   LEN(Dimensions) > 0 AND SUBSTRING(Dimensions,1,1) = ' '

	----------------------------
	--Remove initial semicolon--
	----------------------------
	UPDATE	#mbbmSheetRecursion
	SET 	Dimensions = RIGHT(Dimensions, LEN(Dimensions)-1) + ';'
	WHERE   LEN(Dimensions) > 0

	-----------------------------------------------------------------
	--Insert distinct dimension sets into #mbbmDimensionSetList--
	-----------------------------------------------------------------
	INSERT #mbbmDimensionSetList
	SELECT DISTINCT Dimensions
        FROM #mbbmSheetRecursion r
	WHERE r.Dimensions NOT IN
              (SELECT DimensionSet 
               FROM mbbmCubes75 
               WHERE PlanID = @PlanID
               AND   Name <> @CubeName)
	ORDER BY r.Dimensions

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspDimensionSetList] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspDimensionSetList] TO [public]
GO
