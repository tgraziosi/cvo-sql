SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspBranchPublished]
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
	DECLARE @CurrentLevel int,
		@primary int

	CREATE TABLE #tbmbSheetBP 
		(SheetID int, 
		SheetKey varchar(32), 
		[Description] varchar(40), 
		ParentNode varchar(32) NULL, 
		SheetType int,
		Publish tinyint,
		NodeLevel int)

	--regular plan sheet, model def, template def all included
	--in case other stuff below it is included in tree
	--(SheetType = 0 OR SheetType = 2 OR SheetType = 4)

	IF @SheetID = 0
	BEGIN
		INSERT  #tbmbSheetBP
		SELECT  s.SheetID, s.SheetKey, s.[Description], 'PLAN',s.SheetType,s.Publish,1
		FROM    mbbmPlanSheet74 s join mbbmPlan74  p on s.PlanID=p.PlanID
		WHERE   s.PlanID = @PlanID AND s.Parent = 0 AND p.PrimarySheet = s.SheetID

		SELECT @primary = PrimarySheet from mbbmPlan74 where PlanID = @PlanID
		INSERT  #tbmbSheetBP
		SELECT  SheetID, SheetKey, [Description], '~US',SheetType,Publish,1
		FROM    mbbmPlanSheet74
		WHERE   PlanID = @PlanID AND SheetID <> @primary AND Parent=0 
			AND (SheetType = 0 OR SheetType = 2 OR SheetType = 4)

	END

	IF @SheetID = -1
	BEGIN
		SELECT @primary = PrimarySheet from mbbmPlan74 where PlanID = @PlanID
		INSERT  #tbmbSheetBP
		SELECT  SheetID, SheetKey, [Description], '~US',SheetType,Publish,1
		FROM    mbbmPlanSheet74
		WHERE   PlanID = @PlanID AND SheetID <> @primary AND Parent=0
			AND (SheetType = 0 OR SheetType = 2 OR SheetType = 4)
	END

	IF @SheetID > 0
	BEGIN
		INSERT  #tbmbSheetBP
		SELECT  SheetID, SheetKey, [Description], NULL,SheetType,Publish,1
		FROM    mbbmPlanSheet74
		WHERE   PlanID = @PlanID AND SheetID = @SheetID
	END

	SELECT @CurrentLevel = 0
	WHILE @@rowcount > 0 BEGIN
		SELECT @CurrentLevel = @CurrentLevel + 1

		INSERT  #tbmbSheetBP
		SELECT  p7.SheetID, p7.SheetKey, p7.[Description], tt.SheetKey,p7.SheetType,p7.Publish,@CurrentLevel + 1
		FROM    mbbmPlanSheet74 p7 JOIN #tbmbSheetBP tt on p7.Parent = tt.SheetID
		WHERE   tt.NodeLevel = @CurrentLevel
			AND p7.PlanID = @PlanID
			AND (p7.SheetType = 0 OR p7.SheetType = 2 OR p7.SheetType = 4)
	END

	SELECT * FROM #tbmbSheetBP order by NodeLevel, SheetKey  

	Drop Table #tbmbSheetBP
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspBranchPublished] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspBranchPublished] TO [public]
GO
