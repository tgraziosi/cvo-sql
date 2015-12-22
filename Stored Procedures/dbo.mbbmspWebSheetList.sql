SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspWebSheetList]
	@HostCompany    varchar(8),
	@UserID		varchar(30)	= NULL,
	@PlanID		int,
	@Admin		smallint
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
	SET NOCOUNT ON
	if @UserID is null OR @Admin=1 OR @UserID='Admin' or @UserID in (select UserID from mbbmPlanSec where PlanID = @PlanID) or @UserID = (Select PlanManager from mbbmPlan74 Where PlanID = @PlanID)
		BEGIN
		SELECT SheetKey, [Description] as 'DESC', SheetID, SheetType, Locked, 0 AS ManagerViaParent, '?companyCode='+ HostCompany 
			+ '&planID=' + convert(varchar(16),PlanID) 
			+ '&sheetID=' + convert(varchar(16),SheetID) 
			+ '&revisionID=' + convert(varchar(16),ActiveRevision) 
			as 'LKUP', CheckedOut, CheckedOutTo

		FROM mbbmPlanSheet74
		WHERE SheetType=0
			AND ActiveRevision > 0
			AND HostCompany=@HostCompany
			AND PlanID=@PlanID
		ORDER BY SheetKey
		END
	else
		BEGIN
		DECLARE @host	varchar(32),
			@plan	int,
			@sheet 	int,
			@CurrentLevel	int

		CREATE TABLE #mgsheets(HostCompany varchar(8),PlanID int, SheetID int)
		declare curmgsheets insensitive cursor for select * from #mgsheets

		CREATE TABLE #mbbmPT(	PlanID          int,
					SheetID         int,
					NodeLevel       int)
		CREATE TABLE #mbbmPTFinal(PlanID        int,
					SheetID         int,
					NodeLevel       int)

		INSERT into #mgsheets SELECT HostCompany,PlanID,SheetID FROM mbbmPlanSheet74 p 
			where SheetManager = @UserID AND HostCompany=@HostCompany AND PlanID=@PlanID
		open curmgsheets
		fetch curmgsheets into @host, @plan, @sheet
		while (@@FETCH_STATUS = 0) BEGIN
			
			SELECT @CurrentLevel = 0
			INSERT INTO #mbbmPT VALUES(@plan, @sheet, 1)
	
			WHILE @@rowcount > 0 BEGIN
				SELECT @CurrentLevel = @CurrentLevel + 1
	
				INSERT  #mbbmPT
				SELECT  PlanID,	SheetID,@CurrentLevel + 1
				FROM    mbbmPlanSheet74
				WHERE   Parent IN (SELECT SheetID FROM #mbbmPT WHERE NodeLevel = @CurrentLevel)
			END

			fetch next from curmgsheets into @host, @plan, @sheet
			INSERT INTO #mbbmPTFinal  SELECT * FROM #mbbmPT
			TRUNCATE TABLE #mbbmPT
		END
		close curmgsheets

		SELECT SheetKey, [Description] as 'DESC', p.SheetID, p.SheetType, p.Locked, 1 AS ManagerViaParent, '?companyCode='+ HostCompany
			+ '&planID=' + convert(varchar(16),p.PlanID) 
			+ '&sheetID=' + convert(varchar(16),p.SheetID) 
			+ '&revisionID=' + convert(varchar(16),ActiveRevision)
			as 'LKUP', CheckedOut, CheckedOutTo

		FROM mbbmPlanSheet74 p join #mbbmPTFinal pt on p.PlanID = pt.PlanID --and p.HostCompany=pt.HostCompany
			AND p.SheetID=pt.SheetID
		WHERE p.SheetType=0 
			AND p.ActiveRevision > 0
		UNION
		SELECT SheetKey, [Description] as 'DESC', p.SheetID, p.SheetType, p.Locked, 0 AS ManagerViaParent, '?companyCode='+ HostCompany
			+ '&planID=' + convert(varchar(16),p.PlanID) 
			+ '&sheetID=' + convert(varchar(16),p.SheetID) 
			+ '&revisionID=' + convert(varchar(16),ActiveRevision)
			as 'LKUP', CheckedOut, CheckedOutTo

		FROM mbbmPlanSheet74 p join mbbmPlanSheetSec s on p.SheetID=s.SheetID
		WHERE p.SheetType=0
			AND p.ActiveRevision > 0
			AND s.UserID = @UserID
			AND HostCompany=@HostCompany
			AND p.PlanID=@PlanID
			AND p.SheetID NOT IN (SELECT SheetID FROM #mbbmPTFinal WHERE HostCompany = @HostCompany AND PlanID = @PlanID)
		ORDER BY SheetKey

		DEALLOCATE curmgsheets
		drop table #mbbmPT
		drop table #mbbmPTFinal
		drop table #mgsheets
		END
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebSheetList] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebSheetList] TO [public]
GO
