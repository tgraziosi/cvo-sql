SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspSheetDescendents]
	@PlanID int, 
	@SheetID int
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
	DECLARE @CurrentLevel int
	DECLARE @Regular int

	SELECT  @Regular = 0


	CREATE TABLE #tbSheetDescTmp 
		(PlanID int, 
		SheetID int, 
		NodeLevel int, 
		SheetType int, 
		SheetKey varchar(32), 
		ActiveRevision int, 
		Description varchar(40), 
		Status varchar(5),
		UploadCompany varchar(40))

	INSERT  #tbSheetDescTmp
	SELECT  PlanID,
		SheetID,
		1,
                SheetType,
		SheetKey,
		ActiveRevision,
		Description,
		Status,
		UploadCompany
	FROM    mbbmPlanSheet74
	WHERE   PlanID = @PlanID AND SheetID = @SheetID AND
		SheetType = @Regular

	SELECT @CurrentLevel = 0
	WHILE @@rowcount > 0 BEGIN
		SELECT @CurrentLevel = @CurrentLevel + 1

		INSERT  #tbSheetDescTmp
		SELECT  PlanID,
			SheetID,
			@CurrentLevel + 1,
	                SheetType,
			SheetKey,
			ActiveRevision,
			Description,
			Status,
			UploadCompany
		FROM    mbbmPlanSheet74
		WHERE   Parent IN (SELECT SheetID FROM #tbSheetDescTmp WHERE NodeLevel = @CurrentLevel)
		AND	PlanID = @PlanID AND 
			SheetType = @Regular
	END

	SELECT * FROM #tbSheetDescTmp WHERE SheetID IN 
                (SELECT SheetID FROM mbbmPlanSheetRev74 r INNER JOIN mbbmPlanSheetDimensions74 d
                 ON (r.RevisionID = d.RevisionID AND d.Code = 'Accounts' AND d.Axis = 1))

	Drop Table #tbSheetDescTmp
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspSheetDescendents] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspSheetDescendents] TO [public]
GO
