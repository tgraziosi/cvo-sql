SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspPlanSheetTempAdjust]
	@PlanID         int             = 0,
	@SheetID        int             = 0,
	@DeleteSheets   mbbmudtYesNo    = 0,
	@DeleteChildren mbbmudtYesNo    = 0,
        @PublicationDatabase varchar(100) = " ",
        @User		varchar(30)	= " ",
	@ForceOverCheckOut mbbmudtYesNo = 0
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
	DECLARE @DelPlanID	int
	DECLARE @DelSheetID	int

	IF @DeleteSheets = 1 BEGIN
		--Delete Template Generated Sheets
		DECLARE crsDeleted CURSOR FOR
		SELECT a.PlanID, a.SheetID
		FROM mbbmPlanSheet74 a
		INNER JOIN mbbmTemplateSheets b 
	        ON
		(a.SheetKey = b.SheetKey AND
        	 b.PlanID = @PlanID AND
	         b.SheetID = @SheetID AND
 		 a.PlanID = b.PlanID)
		WHERE a.GeneratedBy = 2

		OPEN    crsDeleted
		FETCH   crsDeleted
		INTO    @DelPlanID, @DelSheetID
		WHILE (@@FETCH_STATUS = 0) BEGIN
        	  EXEC mbbmspPlanSheetDelete @DelPlanID, @DelSheetID, @DeleteChildren, @PublicationDatabase, @User, @ForceOverCheckOut
	          FETCH   crsDeleted
        	  INTO    @DelPlanID, @DelSheetID
	        END
        	CLOSE crsDeleted
	        DEALLOCATE crsDeleted
	END
	ELSE BEGIN
		UPDATE mbbmPlanSheet74
		SET GeneratedBy = 0
		FROM mbbmPlanSheet74, mbbmTemplateSheets
		WHERE
		mbbmPlanSheet74.SheetKey = mbbmTemplateSheets.SheetKey AND
        	mbbmTemplateSheets.PlanID = @PlanID AND
	        mbbmTemplateSheets.SheetID = @SheetID AND
 		mbbmPlanSheet74.PlanID = mbbmTemplateSheets.PlanID AND
		mbbmPlanSheet74.GeneratedBy = 2
	END

	DELETE
        FROM mbbmTemplateValues
        WHERE
        PlanID = @PlanID AND
        SheetID = @SheetID

	DELETE
        FROM mbbmTemplateSheets
        WHERE
        PlanID = @PlanID AND
        SheetID = @SheetID
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanSheetTempAdjust] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanSheetTempAdjust] TO [public]
GO
