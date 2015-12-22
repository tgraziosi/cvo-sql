SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspGroupPublished]
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
SELECT g.GroupKey, g.[Description], g.Publish,s.SheetKey  
FROM mbbmPlanGrp74 g JOIN mbbmPlanSheetRev74 r  on  g.RevisionID = r.RevisionID
JOIN mbbmPlanSheet74 s on s.ActiveRevision = r.RevisionID
WHERE s.PlanID = @PlanID and s.SheetID = @SheetID

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspGroupPublished] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspGroupPublished] TO [public]
GO
