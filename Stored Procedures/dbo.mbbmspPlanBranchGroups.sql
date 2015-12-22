SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspPlanBranchGroups]
	@PlanID         int = 0,
	@SheetID        int = 0
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
	DECLARE @CurrentLevel 		int,			
                @ExcelType              int,
		@PlanSheetType		int,
		@TemplateType		int,
		@NewRevID		int,
		@HostCompany		mbbmudtCompanyCode

	SELECT @ExcelType = 1
	SELECT @PlanSheetType = 0
	SELECT @TemplateType = 4

	CREATE TABLE #tbBranchTmp  (PlanID	int,
				   SheetID	int,
				   NodeLevel	int,
                                   SheetType    int)

	SELECT @HostCompany = (SELECT HostCompany FROM mbbmPlan74 WHERE PlanID = @PlanID)

	--Build list of plan.sheets
	SELECT @CurrentLevel = 0
	INSERT INTO #tbBranchTmp VALUES(@PlanID, @SheetID, 1, 0)

	WHILE @@rowcount > 0 BEGIN
		SELECT @CurrentLevel = @CurrentLevel + 1
		INSERT  #tbBranchTmp
		SELECT  PlanID,
			SheetID,
			@CurrentLevel + 1,
                        SheetType
		FROM    mbbmPlanSheet74
		WHERE   Parent IN (SELECT SheetID FROM #tbBranchTmp WHERE NodeLevel = @CurrentLevel) AND
			PlanID = @PlanID
		END

	SELECT DISTINCT aGP.GroupKey
	FROM    #tbBranchTmp aBT 
        INNER JOIN mbbmPlanSheet74 aPS 
        ON (aPS.PlanID = aBT.PlanID AND 
            aPS.SheetID = aBT.SheetID AND 
            aPS.SheetType <> 1)
	INNER JOIN mbbmPlanSheetRev74 aRV 
        ON (aPS.SheetID = aRV.SheetID AND
            aRV.RevisionID = aPS.ActiveRevision)
	INNER JOIN mbbmPlanGrp74 aGP 
        ON (aGP.RevisionID = aRV.RevisionID)
	ORDER BY GroupKey
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanBranchGroups] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanBranchGroups] TO [public]
GO
