SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspRetrieveSheetSections]
	@PlanID         int             = 0,
	@SheetID        int             = 0,
	@AllSheets	mbbmudtYesNo    = 0
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
	DECLARE @CurrentLevel           int
	DECLARE @ExitFlag		int

	CREATE TABLE #mbbmPlanTreeQuery(PlanID          int,
					SheetID         int,
					NodeLevel       int)

	IF @SheetID <> 0 BEGIN
		IF @AllSheets <> 0 BEGIN
			--Build list of plan.sheets to query

			SELECT @CurrentLevel = 0

			INSERT INTO #mbbmPlanTreeQuery VALUES(@PlanID, @SheetID, 1)

			WHILE @@rowcount > 0 BEGIN
				SELECT @CurrentLevel = @CurrentLevel + 1

				INSERT  #mbbmPlanTreeQuery
				SELECT  PlanID,
					SheetID,
					@CurrentLevel + 1
				FROM    mbbmPlanSheet74
				WHERE   Parent IN (SELECT SheetID FROM #mbbmPlanTreeQuery WHERE NodeLevel = @CurrentLevel)
			END
		END
		ELSE BEGIN
			--Build list of plan.sheets to query

			SELECT @CurrentLevel = 0

			INSERT INTO #mbbmPlanTreeQuery VALUES(@PlanID, @SheetID, 1)

			SELECT @CurrentLevel = @CurrentLevel + 1

			INSERT  #mbbmPlanTreeQuery
			SELECT  PlanID,
				SheetID,
				@CurrentLevel + 1
			FROM    mbbmPlanSheet74
			WHERE   Parent IN (SELECT SheetID FROM #mbbmPlanTreeQuery WHERE NodeLevel = @CurrentLevel)
		END
	END             

	SELECT 		SectionKey, #mbbmPlanTreeQuery.SheetID 
	FROM    	mbbmPlanSheetRev74, #mbbmPlanTreeQuery, mbbmPlanSheetSections
	WHERE   	mbbmPlanSheetRev74.SheetID = #mbbmPlanTreeQuery.SheetID
				AND mbbmPlanSheetRev74.RevisionID = mbbmPlanSheetSections.RevisionID
	ORDER BY	SectionKey

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspRetrieveSheetSections] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspRetrieveSheetSections] TO [public]
GO
