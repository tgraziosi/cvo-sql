SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
create procedure [dbo].[mbbmspWebPlanList] 
   @HostCompany varchar(8),
   @UserID	varchar(30) =NULL,
   @Admin	smallint
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
IF @Admin = 1
	SELECT p.PlanID, p.PlanKey + ' - '+ p.[Description] as 'PlanDesc', @UserID as 'UserID'  FROM mbbmPlan74 p
	Where p.HostCompany = @HostCompany
	ORDER BY p.PlanKey
ELSE
BEGIN
	SELECT p.PlanID, p.PlanKey + ' - '+ p.[Description] as 'PlanDesc', @UserID as 'UserID'  FROM mbbmPlan74 p 
	join mbbmPlanSheet74 ps on p.PlanID=ps.PlanID
	join mbbmPlanSheetSec ss on ps.SheetID=ss.SheetID 
	WHERE p.HostCompany = @HostCompany and UserID=@UserID
	UNION	
	SELECT p.PlanID, p.PlanKey + ' - '+ p.[Description] as 'PlanDesc', @UserID as 'UserID'  FROM mbbmPlan74 p 
	join mbbmPlanSheet74 ps on p.PlanID=ps.PlanID
	WHERE p.HostCompany = @HostCompany and ps.SheetManager = @UserID
	UNION
	SELECT p.PlanID, p.PlanKey + ' - '+ p.[Description] as 'PlanDesc', @UserID as 'UserID'  FROM mbbmPlan74 p 
	join mbbmPlanSec ps on p.PlanID=ps.PlanID
	WHERE p.HostCompany = @HostCompany and UserID=@UserID
	UNION
	SELECT p.PlanID, p.PlanKey + ' - '+ p.[Description] as 'PlanDesc', @UserID as 'UserID'  FROM mbbmPlan74 p 
	WHERE p.HostCompany = @HostCompany and PlanManager = @UserID
	ORDER BY PlanDesc

END

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebPlanList] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebPlanList] TO [public]
GO
