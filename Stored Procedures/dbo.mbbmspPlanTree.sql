SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspPlanTree] 
	@PlanID         int,
	@SheetID        int,
	@User		varchar(30),
	@CompCode	varchar(8),
	@UseTempTable 	int

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
	DECLARE @CurrentLevel           int,
		@PlanKey                mbbmudtBudgetKey,
		@GetOrphans             mbbmudtYesNo,
		@ModelSource		int,
                @TemplateSource         int

	SELECT	@ModelSource = 3
	SELECT  @TemplateSource = 5

        -----------------------------------------------------
        -- This procedure now excludes model source sheets.--
        -----------------------------------------------------
	
	SELECT  @PlanKey = PlanKey
	FROM    mbbmPlan74
	WHERE   PlanID = @PlanID

	SELECT @CurrentLevel = 0

	SELECT  s.PlanID,
		@PlanKey "PlanKey",
		s.SheetID,
		s.SheetKey,
		s.SheetManager,
		s.Description,
		s.Status,
		s.Locked,
		s.Parent,
		s.SheetType,
		s.FileName,
		s.ActiveRevision,
		r.RevisionKey,
		PrimarySheet = 0,
		Indexer = 1,
		s.GeneratedBy,
		s.OfflineLocked,
		s.UpdatedBy,
		s.Publish,
		s.CheckedOut,
		s.CheckedOutTo,
		s.CheckedOutProcessID,
		s.CheckedOutProcessType
	INTO    #mbbmPlanTree 
	FROM    mbbmPlanSheet74 s, mbbmPlanSheetRev74 r
	WHERE   1 = 0

	--Orphans only
	SELECT @GetOrphans = 0
	IF @SheetID = -1 BEGIN
		SELECT @SheetID = 0
		SELECT @GetOrphans = 1
	END

	IF @SheetID <> 0 
		INSERT  #mbbmPlanTree 
		SELECT  s.PlanID,
			@PlanKey,
			s.SheetID,
			s.SheetKey,
			s.SheetManager,
			s.Description,
			s.Status,
			s.Locked,
			s.Parent,
			s.SheetType,
			s.FileName,
			s.ActiveRevision,
			isnull(r.RevisionKey, ''),
			PrimarySheet = 0,
			Indexer = 1,
			s.GeneratedBy,
			s.OfflineLocked,
			s.UpdatedBy,
			s.Publish,
			s.CheckedOut,
			s.CheckedOutTo,
			s.CheckedOutProcessID,
			s.CheckedOutProcessType
		FROM    mbbmPlanSheet74 s LEFT OUTER JOIN 
			mbbmPlanSheetRev74 r
                ON 	(r.RevisionID = s.ActiveRevision)
		WHERE   s.PlanID = @PlanID
			AND s.SheetID = @SheetID
			AND (s.SheetType <> @ModelSource)
                        AND (s.SheetType <> @TemplateSource)
	ELSE
		INSERT  #mbbmPlanTree 
		SELECT  s.PlanID,
			@PlanKey,
			s.SheetID,
			s.SheetKey,
			s.SheetManager,
			s.Description,
			s.Status,
			s.Locked,
			s.Parent,
			s.SheetType,
			s.FileName,
			s.ActiveRevision,
			isnull(r.RevisionKey, ''),
			PrimarySheet = (SELECT Count(*) FROM mbbmPlan74 p WHERE p.PlanID = @PlanID AND PrimarySheet = s.SheetID),
			Indexer = 1,
			s.GeneratedBy,
			s.OfflineLocked,
			s.UpdatedBy,
			s.Publish,
			s.CheckedOut,
			s.CheckedOutTo,
			s.CheckedOutProcessID,
			s.CheckedOutProcessType
		FROM    mbbmPlanSheet74 s LEFT OUTER JOIN 
			mbbmPlanSheetRev74 r
                ON 	(r.RevisionID = s.ActiveRevision)
		WHERE   s.PlanID = @PlanID
			AND s.Parent = 0
			AND ((@GetOrphans = 0)
				OR (@GetOrphans = 1 AND
				EXISTS  (SELECT PrimarySheet 
						FROM mbbmPlan74 p
						WHERE   p.PlanID = @PlanID
							AND p.PrimarySheet <>  s.SheetID)))
			AND (s.SheetType <> @ModelSource)
                        AND (s.SheetType <> @TemplateSource)

	WHILE @@rowcount > 0 BEGIN
		SELECT @CurrentLevel = @CurrentLevel + 1

		INSERT  #mbbmPlanTree
		SELECT  s.PlanID,
			@PlanKey "PlanKey",
			s.SheetID,
			s.SheetKey,
			s.SheetManager,
			s.Description,
			s.Status,
			s.Locked,
			s.Parent,
			s.SheetType,
			s.FileName,
			s.ActiveRevision,
			isnull(r.RevisionKey, ''),
			0,
			@CurrentLevel + 1,
			s.GeneratedBy,
			s.OfflineLocked,
			s.UpdatedBy,
			s.Publish,
			s.CheckedOut,
			s.CheckedOutTo,
			s.CheckedOutProcessID,
			s.CheckedOutProcessType
		FROM    mbbmPlanSheet74 s LEFT OUTER JOIN 
			mbbmPlanSheetRev74 r
                ON 	(r.RevisionID = s.ActiveRevision)
		WHERE   s.Parent IN (SELECT SheetID FROM #mbbmPlanTree WHERE Indexer = @CurrentLevel)
			AND (s.SheetType <> @ModelSource)
                        AND (s.SheetType <> @TemplateSource)
	END
	
	IF @UseTempTable = 1	
		SELECT  PlanID,
			PlanKey,
			SheetID,
			SheetKey,
			SheetManager,
			Description,
			Status,
			Locked,
			Parent,
			SheetType,
			FileName,
			ActiveRevision,
			RevisionKey,
			PrimarySheet,
			GeneratedBy,
			Indexer,
			OfflineLocked, 
			UpdatedBy,
			3 As MainIcon,
			Publish,
			CheckedOut,
			CheckedOutTo,
			CheckedOutProcessID,
			CheckedOutProcessType
        	FROM    #TEMPTREELST
		WHERE Not Exists 
		(select #mbbmPlanTree.SheetID from #mbbmPlanTree WHERE #mbbmPlanTree.SheetID = #TEMPTREELST.SheetID 
									AND #mbbmPlanTree.OfflineLocked = 1) 
		
	
		UNION
	
		SELECT  PlanID,
			PlanKey,
			SheetID,
			SheetKey,
			SheetManager,
			Description,
			Status,
			Locked,
			Parent,
			SheetType,
			FileName,
			ActiveRevision,
			RevisionKey,
			PrimarySheet,
			GeneratedBy,
			Indexer,
			OfflineLocked, 
			UpdatedBy,
			
			CASE OfflineLocked 
                		WHEN 0 THEN 0 
                        	WHEN 1 THEN 
                            	CASE WHEN UpdatedBy = @User THEN 1 
      					ELSE 2 
                            		END
          		END As MainIcon,
			Publish,
			CheckedOut,
			CheckedOutTo,
			CheckedOutProcessID,
			CheckedOutProcessType
        	FROM    #mbbmPlanTree
		ORDER BY Indexer
	ELSE
		SELECT  PlanID,
			PlanKey,
			SheetID,
			SheetKey,
			SheetManager,
			Description,
			Status,
			Locked,
			Parent,
			SheetType,
			FileName,
			ActiveRevision,
			RevisionKey,
			PrimarySheet,
			GeneratedBy,
			Indexer,
			OfflineLocked, 
			UpdatedBy,
			
			CASE OfflineLocked 
                		WHEN 0 THEN 0 
                        	WHEN 1 THEN 
                            	CASE WHEN UpdatedBy = @User THEN 1 
      					ELSE 2 
                            		END
          		END As MainIcon,
			Publish,
			CheckedOut,
			CheckedOutTo,
			CheckedOutProcessID,
			CheckedOutProcessType
        	FROM    #mbbmPlanTree
		ORDER BY Indexer
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanTree] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanTree] TO [public]
GO
