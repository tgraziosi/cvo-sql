SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[mbbmspSheetDimensionSet]
            @SheetID	int,
	    @DimSet	varchar(255) OUTPUT
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
	DECLARE		@Code    	varchar(255)

	SELECT @DimSet = ''

	DECLARE	crsSheetRecursion CURSOR FOR 
	SELECT 		RTRIM(d.Code)
	FROM            mbbmPlanSheet74 s INNER JOIN mbbmPlanSheetRev74 r ON (s.ActiveRevision = r.RevisionID) 
			LEFT OUTER JOIN mbbmPlanSheetDimensions74 d ON (r.RevisionID = d.RevisionID)
	WHERE           s.SheetID = @SheetID
        AND             s.SheetType = 0
        AND             s.ActiveRevision <> 0
	AND             Publish = 1
	ORDER BY	d.Code

	OPEN crsSheetRecursion
	FETCH NEXT FROM crsSheetRecursion INTO @Code

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @DimSet = @DimSet + ';' + @Code
		FETCH NEXT FROM crsSheetRecursion INTO @Code
	END

	CLOSE crsSheetRecursion 
	DEALLOCATE crsSheetRecursion 

	-------------------------------------------------------------
	--Remove initial space caused by db compatibility set to 65--
	-------------------------------------------------------------
	IF LEN(@DimSet) > 0 AND SUBSTRING(@DimSet,1,1) = ' '
		BEGIN
		SELECT @DimSet = RIGHT(@DimSet, LEN(@DimSet)-1)

	END

	----------------------------
	--Remove initial semicolon--
	----------------------------
	IF LEN(@DimSet) > 0
		BEGIN
		SELECT @DimSet = RIGHT(@DimSet, LEN(@DimSet)-1) + ';'

	END

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspSheetDimensionSet] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspSheetDimensionSet] TO [public]
GO
