SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspPlanSheetRevDel]
	@HostCompany    mbbmudtCompanyCode,
	@RevisionID     int,
	@Success        mbbmudtYesNo OUTPUT 
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
	DECLARE @RevCount       int

	SELECT  @RevCount = COUNT(*) 
	FROM    mbbmPlanSheetRev74 a,
		mbbmPlanSheetRev74 b
	WHERE   a.SheetID = b.SheetID
		AND b.RevisionID = @RevisionID
	
	IF @RevCount > 1 BEGIN
		EXEC   mbbmspFormulaPurge @HostCompany, 1, 2, @RevisionID
		DELETE mbbmPlanHist     	WHERE RevisionID = @RevisionID
		DELETE mbbmPlanHfc      	WHERE RevisionID = @RevisionID
		DELETE mbbmPlanGrp74    	WHERE RevisionID = @RevisionID
		DELETE mbbmPlanColSet   	WHERE RevisionID = @RevisionID
		DELETE mbbmPlanSheetSections 	WHERE RevisionID = @RevisionID
		DELETE mbbmPlanCol7     	WHERE RevisionID = @RevisionID
		DELETE mbbmPlanCustCol7  	WHERE RevisionID = @RevisionID
		DELETE mbbmPlanSheetDimensions74 WHERE RevisionID = @RevisionID
		DELETE mbbmPlanSheetRev74 	WHERE RevisionID = @RevisionID
		SELECT @Success = 1
	END
	ELSE
		SELECT @Success = 0
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanSheetRevDel] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanSheetRevDel] TO [public]
GO
