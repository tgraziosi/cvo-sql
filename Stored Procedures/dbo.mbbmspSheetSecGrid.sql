SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspSheetSecGrid]
	@UserID         mbbmudtUser,
	@SheetType	int,
	@HostCompany    mbbmudtCompanyCode
	--------------------------------------------------------------------------
	--SheetType - 0 plan sheet, 1 excel sheet, 2 model definition sheet,    --
        --3 model source sheet, 4 template definition sheet, 5 template source  --
	--Pass in -1 for types <=2 & 4 returned     				--
	--------------------------------------------------------------------------
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

------------------------------------------------------------
--NOTE: this is a duplicate routine to mbbmspSheetSecList,--
--only it uses a different output temp table name         --
--If you change this, change the other routine            --
------------------------------------------------------------

	---------------------------
	--Create Temporary Tables--
	---------------------------
	CREATE TABLE #mbbmRecursion
	(SheetID        int     Null,
	 SheetLevel     int     Null)

	CREATE INDEX #mbbmRecursionIndex ON #mbbmRecursion (SheetID)

	CREATE TABLE #mbbmFinal
	(SheetID        int     Null,
	 SheetLevel     int     Null)


	DECLARE @SheetID        int,
		@CurLevel       int,
		@PlanID         int

	--------------------------------------------------------------------------
	--SheetType - 0 plan sheet, 1 excel sheet, 2 model definition sheet,    --
        --3 model source sheet, 4 template definition sheet, 5 template source  --
	--Pass in -1 for types <= 2 & 4 returned       			        --
	--------------------------------------------------------------------------

	-----------------------------------------------------------------------------------------------
	--Update the #mbbmFinal table with all sheets for a particular plan if user is a Plan Manager--
	-----------------------------------------------------------------------------------------------
	INSERT	#mbbmFinal
	SELECT 	SheetID, 0
	FROM    mbbmPlanSheet74 ps, mbbmPlan74 p
	WHERE   ps.PlanID = p.PlanID AND
		ps.HostCompany = @HostCompany AND
		p.PlanManager = @UserID AND
		(ps.SheetType = @SheetType OR (@SheetType = -1 AND (ps.SheetType <= 2 OR ps.SheetType = 4)))

	-----------------------------------------------------------------------------------------------
	--Update the #mbbmFinal table with all sheets for a particular plan if user is a Plan Planner--
	-----------------------------------------------------------------------------------------------
	INSERT 	#mbbmFinal
	SELECT	SheetID, 0
	FROM    mbbmPlanSheet74 ps, mbbmPlanSec p
	WHERE   ps.PlanID = p.PlanID AND
		ps.HostCompany = @HostCompany AND
		p.UserID = @UserID AND
		(ps.SheetType = @SheetType OR (@SheetType = -1 AND (ps.SheetType <= 2 OR ps.SheetType = 4)))

	------------------------------------------------------------------------------------------------
	--Update the #mbbmFinal table with all sheets for a particular plan if user is a Sheet Manager--
	------------------------------------------------------------------------------------------------
	DECLARE	crsMgrs CURSOR FOR 
	SELECT 	SheetID 
	FROM	mbbmPlanSheet74 
	WHERE	SheetManager = @UserID AND
		HostCompany = @HostCompany AND
		(SheetType = @SheetType OR (@SheetType = -1 AND (SheetType <= 2 OR SheetType = 4))) AND
		SheetID NOT IN (SELECT SheetID FROM #mbbmFinal)
                                         
	OPEN crsMgrs
	FETCH NEXT FROM crsMgrs INTO @SheetID

	WHILE @@FETCH_STATUS = 0
	BEGIN

		IF @SheetID NOT IN (SELECT SheetID FROM #mbbmFinal)
		BEGIN
			INSERT INTO #mbbmRecursion (SheetID, SheetLevel) VALUES (@SheetID, 1)
	
			SELECT @CurLevel = 0
	
			WHILE @@rowcount > 0
			BEGIN
				SELECT @CurLevel = @CurLevel + 1

				INSERT #mbbmRecursion
				SELECT  ps.SheetID, 
					@CurLevel + 1           
				FROM    mbbmPlanSheet74 ps,
					#mbbmRecursion rc
				WHERE   rc.SheetID = ps.Parent AND
					ps.HostCompany = @HostCompany AND
					rc.SheetLevel = @CurLevel

			END
		
			INSERT  #mbbmFinal
			SELECT  SheetID,
				SheetLevel
			FROM    #mbbmRecursion


			DELETE FROM #mbbmRecursion
		END


		FETCH NEXT FROM crsMgrs INTO @SheetID
	END

	CLOSE crsMgrs 
	DEALLOCATE crsMgrs 

	---------------------------------------------------------------------------------------------------------
	--Update the #mbbmFinal table with all sheets for a particular plan if user is a Sheet Planner/Reviewer--
	---------------------------------------------------------------------------------------------------------
	INSERT  #mbbmFinal
	SELECT  ps.SheetID,
		999
	FROM    mbbmPlanSheet74 ps, mbbmPlanSheetSec p
	WHERE   p.UserID = @UserID AND
		ps.HostCompany = @HostCompany AND
		ps.SheetID = p.SheetID

	----------------------------------
	--Begin building the Lookup File--
	----------------------------------
	INSERT  #mbbmSecPSList
	SELECT DISTINCT SheetID, 0, '', '', '', 0, '', 0, '', 0, 0, 0, '' FROM #mbbmFinal

	UPDATE #mbbmSecPSList 
	SET 	PlanID = p.PlanID,
	        SheetKey = p.SheetKey,
            	Description = p.Description,
	        ActiveRevision = p.ActiveRevision,
		SheetManager = p.SheetManager,
		SheetType = p.SheetType,
		Status = p.Status,
		Locked = p.Locked,
		GeneratedBy = p.GeneratedBy, 
		CheckedOut = p.CheckedOut,
		CheckedOutTo = p.CheckedOutTo
	FROM 	#mbbmSecPSList l, mbbmPlanSheet74 p
	WHERE 	l.SheetID = p.SheetID AND
		p.HostCompany = @HostCompany

	UPDATE 	#mbbmSecPSList 
	SET 	PlanKey = p.PlanKey
	FROM 	#mbbmSecPSList l, mbbmPlan74 p
	WHERE 	l.PlanID = p.PlanID AND       
		p.HostCompany = @HostCompany

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspSheetSecGrid] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspSheetSecGrid] TO [public]
GO
