SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspPlanSheetDelete]
	@PlanID         int             = 0,
	@SheetID        int             = 0,
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
	DECLARE @ByPlan			tinyint
	DECLARE @CubeName		varchar(60)
	DECLARE @CurrentLevel           int
	DECLARE @DimSet			varchar(255)
	DECLARE @ExcelType		int
	DECLARE @ModelDefinitionType    int
	DECLARE @ModelSourceType        int
	DECLARE @TemplateDefinitionType int
	DECLARE @TemplateSourceType     int
	DECLARE @SheetType		int
	DECLARE @HostCompany            mbbmudtCompanyCode
	DECLARE @Work                   varchar(200)
	DECLARE @SheetLookupID          int
	DECLARE @GeneratedByTemplate    int
	DECLARE @Count			int

	SELECT @ModelDefinitionType = 2
	SELECT @ModelSourceType = 3
        SELECT @TemplateDefinitionType = 4
        SELECT @TemplateSourceType = 5
	SELECT @GeneratedByTemplate = 2
	SELECT @ExcelType = 1

	CREATE TABLE #mbbmPlanTreeDelete(PlanID          int,
					 SheetID         int,
					 NodeLevel       int)

	IF @DeleteChildren <> 0 and @SheetID <> 0 BEGIN
		--Build list of plan.sheets to delete

		SELECT @CurrentLevel = 0
		INSERT INTO #mbbmPlanTreeDelete VALUES(@PlanID, @SheetID, 1)

		WHILE @@rowcount > 0 BEGIN
			SELECT @CurrentLevel = @CurrentLevel + 1

			INSERT  #mbbmPlanTreeDelete
			SELECT  PlanID,
				SheetID,
				@CurrentLevel + 1
			FROM    mbbmPlanSheet74
			WHERE   Parent IN (SELECT SheetID FROM #mbbmPlanTreeDelete WHERE NodeLevel = @CurrentLevel)
		END

		--Filter sheets for checkout status
		IF @ForceOverCheckOut = 0 BEGIN
			
			--set parent to 0 for any sheets which have
			--a parent which is being deleted
			UPDATE  mbbmPlanSheet74 SET 
				Parent = 0
			WHERE PlanID = @PlanID AND 
			SheetID IN (

			SELECT a.SheetID
			FROM #mbbmPlanTreeDelete a
			INNER JOIN mbbmPlanSheet74 b
			ON (a.PlanID = b.PlanID AND 
                            a.SheetID = b.SheetID AND
			    b.SheetType <> @ExcelType AND
			    (b.CheckedOut = 2 OR
                             (b.CheckedOut = 1 AND
			      b.CheckedOutTo <> @User))))


			--remove from deletion list if:
			--not excel AND
			--(process check out OR
			--(check out and not checked out to you))
			DELETE #mbbmPlanTreeDelete
			FROM #mbbmPlanTreeDelete a
			INNER JOIN mbbmPlanSheet74 b
			ON (a.PlanID = b.PlanID AND 
                            a.SheetID = b.SheetID AND
			    b.SheetType <> @ExcelType AND
			    (b.CheckedOut = 2 OR
                             (b.CheckedOut = 1 AND
			      b.CheckedOutTo <> @User)))

		END

		--Build list of direct source sheets to delete for single model sheet selected
		INSERT  #mbbmPlanTreeDelete
		SELECT  c.PlanID, c.SheetID, 1
		FROM    mbbmPlanSheet74 c
		WHERE   c.PlanID = @PlanID AND
                        c.SheetType = @ModelSourceType AND
			Parent IN (SELECT a.SheetID FROM #mbbmPlanTreeDelete a
		  		   INNER JOIN mbbmPlanSheet74 b
	  			   ON (a.PlanID = b.PlanID AND 
	                	   a.SheetID = b.SheetID AND
				   b.SheetType = @ModelDefinitionType))
	END             

	ELSE BEGIN
		-- single entry
		INSERT  #mbbmPlanTreeDelete VALUES  (@PlanID, @SheetID, 1) 


		--Filter sheets for checkout status
		IF @ForceOverCheckOut = 0 BEGIN
			
			--remove from deletion list if:
			--not excel AND
			--(process check out OR
			--(check out and not checked out to you))
			DELETE #mbbmPlanTreeDelete
			FROM #mbbmPlanTreeDelete a
			INNER JOIN mbbmPlanSheet74 b
			ON (a.PlanID = b.PlanID AND 
                            a.SheetID = b.SheetID AND
			    b.SheetType <> @ExcelType AND
			    (b.CheckedOut = 2 OR
                             (b.CheckedOut = 1 AND
			      b.CheckedOutTo <> @User)))
	
		END

		SELECT @Count = (SELECT COUNT(*) FROM #mbbmPlanTreeDelete)


		IF @Count > 0 BEGIN
			SELECT @SheetType = (SELECT SheetType
				     FROM mbbmPlanSheet74 
				     WHERE PlanID = @PlanID and SheetID = @SheetID)

			IF @SheetType = @ModelDefinitionType BEGIN
				--Build list of direct source sheets to delete for single model sheet selected
	
				INSERT  #mbbmPlanTreeDelete
				SELECT  PlanID, SheetID, 1
					FROM    mbbmPlanSheet74
					WHERE   Parent = @SheetID AND SheetType = @ModelSourceType
			END
		END
	END

	--Adjust Model Related Items
	DECLARE crsDeleted CURSOR FOR
	SELECT c.SheetID
        FROM #mbbmPlanTreeDelete d 
	INNER JOIN mbbmPlanSheet74 a
	ON (a.SheetType = @ModelDefinitionType AND a.PlanID = d.PlanID AND (a.SheetID = d.SheetID OR d.SheetID = 0))
	INNER JOIN mbbmPlanSheet74 b
	ON (b.PlanID = a.PlanID AND b.SheetType = @ModelSourceType AND b.Parent = a.SheetID AND b.GeneratedBy = 1)
	INNER JOIN mbbmPlanSheet74 c
	ON (c.PlanID = b.PlanID AND c.SheetType = 0 AND c.GeneratedBy = 1 AND c.SheetKey = b.FileName)

	OPEN    crsDeleted
	FETCH   crsDeleted
	INTO    @SheetLookupID
	WHILE (@@FETCH_STATUS = 0) BEGIN
		UPDATE	mbbmPlanSheet74
                SET	GeneratedBy = 0
		WHERE	PlanID = @PlanID AND
			SheetID = @SheetLookupID

          FETCH   crsDeleted
          INTO    @SheetLookupID
        END
        CLOSE crsDeleted
        DEALLOCATE crsDeleted

	IF @DeleteChildren = 0 OR @SheetID = 0 BEGIN
		-- If this sheet has subsheets, their parent pointers need updating
		IF @SheetID <> 0 BEGIN
			UPDATE  mbbmPlanSheet74 SET 
				Parent = 0
				WHERE Parent = @SheetID
		END
	END

	IF @SheetID <> 0 BEGIN
		IF EXISTS(SELECT * FROM mbbmPlan74 WHERE PlanID = @PlanID AND PrimarySheet = @SheetID)
			UPDATE mbbmPlan74 SET PrimarySheet = 0 WHERE PlanID = @PlanID
	END

	--Delete Formula Related Items
	DELETE  mbbmFormulaQryTables74
	WHERE   FormulaType = 1 
		AND FormulaOwnerType = 2 
		AND FormulaOwnerID IN ( SELECT  RevisionID 
					FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
					WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID 
						AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
						AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
							OR #mbbmPlanTreeDelete.SheetID = 0) )
	DELETE  mbbmFormulaQry74 
	WHERE   FormulaType = 1 
		AND FormulaOwnerType = 2 
		AND FormulaOwnerID IN ( SELECT  RevisionID 
					FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
					WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID 
						AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
						AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
							OR #mbbmPlanTreeDelete.SheetID = 0) )

	DELETE  mbbmFormulaAccountDim 
	WHERE   FormulaType = 1 
		AND FormulaOwnerType = 2 
		AND FormulaOwnerID IN ( SELECT  RevisionID 
					FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
					WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID 
						AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
						AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
							OR #mbbmPlanTreeDelete.SheetID = 0) )

	DELETE  mbbmFormulaPubQry 
	WHERE   FormulaType = 1 
		AND FormulaOwnerType = 2 
		AND FormulaOwnerID IN ( SELECT  RevisionID 
					FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
					WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID 
						AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
						AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
							OR #mbbmPlanTreeDelete.SheetID = 0) )

	DELETE  mbbmFormulaLines74 
	WHERE   FormulaType = 1 
		AND FormulaOwnerType = 2 
		AND FormulaOwnerID IN ( SELECT  RevisionID 
					FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
					WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
						AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
						AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
							OR #mbbmPlanTreeDelete.SheetID = 0) )


	DELETE  mbbmFormula74 
	WHERE   FormulaType = 1 
		AND FormulaOwnerType = 2 
		AND FormulaOwnerID IN ( SELECT  RevisionID 
					FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
					WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
						AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
						AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
							OR #mbbmPlanTreeDelete.SheetID = 0) )

	--Delete Publication Related Items
	DECLARE crsDeleted CURSOR FOR
	SELECT p.HostCompany, d.SheetID
        FROM #mbbmPlanTreeDelete d, mbbmPlan74 p
        WHERE p.PlanID = d.PlanID 

	OPEN    crsDeleted
	FETCH   crsDeleted
	INTO    @HostCompany, @SheetLookupID
	WHILE (@@FETCH_STATUS = 0) BEGIN
          SELECT @Work = @PublicationDatabase + '..mbbmspPublicationDelete'
	  SELECT @DimSet = ''
	  SELECT @ByPlan = 1
	  IF @SheetLookupID <> 0 
            BEGIN
	          EXEC mbbmspSheetDimensionSet @SheetLookupID, @DimSet OUTPUT
		  SELECT @ByPlan = 0
	    END
          EXEC @Work @HostCompany, @PlanID, @SheetLookupID, 0, @ByPlan, @DimSet
          FETCH   crsDeleted
          INTO    @HostCompany, @SheetLookupID
	  SELECT @@FETCH_STATUS
        END
        CLOSE crsDeleted
        DEALLOCATE crsDeleted

	--Delete Revision Related Items
	DELETE  mbbmPlanHfc
	WHERE   RevisionID IN ( SELECT  RevisionID 
				FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
				WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
					AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
					AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
						OR #mbbmPlanTreeDelete.SheetID = 0) )


	DELETE  mbbmPlanCol7 
	WHERE   RevisionID IN ( SELECT  RevisionID 
				FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
				WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
					AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
					AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
						OR #mbbmPlanTreeDelete.SheetID = 0) )


	DELETE  mbbmPlanGrp74 
	WHERE   RevisionID IN ( SELECT  RevisionID 
				FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
				WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
					AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
					AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
						OR #mbbmPlanTreeDelete.SheetID = 0) )


	DELETE  mbbmPlanColSet 
	WHERE   RevisionID IN ( SELECT  RevisionID 
				FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
				WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
					AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
					AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
						OR #mbbmPlanTreeDelete.SheetID = 0) )

	DELETE  mbbmPlanCustCol7 
	WHERE   RevisionID IN ( SELECT  RevisionID 
				FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
				WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
					AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
					AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
						OR #mbbmPlanTreeDelete.SheetID = 0) )

	DELETE  mbbmPlanSheetSections 
	WHERE   RevisionID IN ( SELECT  RevisionID 
				FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
				WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
					AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
					AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
						OR #mbbmPlanTreeDelete.SheetID = 0) )

	DELETE  mbbmPlanSheetDimensions74
	WHERE   RevisionID IN ( SELECT  RevisionID 
				FROM    mbbmPlanSheetRev74, mbbmPlanSheet74, #mbbmPlanTreeDelete 
				WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
					AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
					AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
						OR #mbbmPlanTreeDelete.SheetID = 0) )

	DELETE  mbbmPlanSheetRev74 
	FROM    mbbmPlanSheet74, #mbbmPlanTreeDelete
	WHERE   mbbmPlanSheetRev74.SheetID = mbbmPlanSheet74.SheetID
		AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
		AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
			OR #mbbmPlanTreeDelete.SheetID = 0) 

	--Delete Sheet Related Items

	DELETE  mbbmPlanHist 
	FROM    mbbmPlanSheet74, #mbbmPlanTreeDelete
	WHERE   mbbmPlanHist.SheetID = mbbmPlanSheet74.SheetID
		AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
		AND mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 

	DELETE  mbbmPlanSheetSec 
	FROM    mbbmPlanSheet74, #mbbmPlanTreeDelete
	WHERE   mbbmPlanSheetSec.SheetID = mbbmPlanSheet74.SheetID
		AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
		AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
			OR #mbbmPlanTreeDelete.SheetID = 0) 

	DELETE  mbbmPlanView 
	FROM    mbbmPlanSheet74, #mbbmPlanTreeDelete
	WHERE   mbbmPlanView.SheetID = mbbmPlanSheet74.SheetID
		AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
		AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
			OR #mbbmPlanTreeDelete.SheetID = 0) 

	--Adjust Template Related Items
	DECLARE crsDeleted CURSOR FOR
	SELECT p.SheetID
        FROM #mbbmPlanTreeDelete d, mbbmPlanSheet74 p
        WHERE p.SheetType = @TemplateDefinitionType
	AND (p.PlanID = d.PlanID 
	AND (p.SheetID = d.SheetID 
        OR d.SheetID = 0))

	OPEN    crsDeleted
	FETCH   crsDeleted
	INTO    @SheetLookupID
	WHILE (@@FETCH_STATUS = 0) BEGIN
		UPDATE	mbbmPlanSheet74
                SET	GeneratedBy = 0
		FROM	mbbmPlanSheet74 s, mbbmTemplateSheets b
		WHERE	s.SheetKey = b.SheetKey AND 
			s.PlanID = b.PlanID AND
			b.PlanID = @PlanID AND 
			b.SheetID = @SheetLookupID
          FETCH   crsDeleted
          INTO    @SheetLookupID
        END
        CLOSE crsDeleted
        DEALLOCATE crsDeleted

	DELETE  mbbmTemplateValues 
	FROM    mbbmPlanSheet74, #mbbmPlanTreeDelete
	WHERE   mbbmTemplateValues.SheetID = mbbmPlanSheet74.SheetID
		AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
		AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
			OR #mbbmPlanTreeDelete.SheetID = 0) 

	DELETE  mbbmTemplateSheets 
	FROM    mbbmPlanSheet74, #mbbmPlanTreeDelete
	WHERE   mbbmTemplateSheets.SheetID = mbbmPlanSheet74.SheetID
		AND mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
		AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID 
			OR #mbbmPlanTreeDelete.SheetID = 0) 

        DECLARE crsCube CURSOR FOR
	SELECT p.HostCompany, p.SheetID, c.Name
        FROM #mbbmPlanTreeDelete d, mbbmPlanSheet74 p, mbbmCubes75 c
        WHERE (p.PlanID = d.PlanID 
        AND (p.SheetID = d.SheetID 
        OR d.SheetID = 0)
        AND c.HostCompany = p.HostCompany
        AND c.PlanID = d.PlanID)
	
	OPEN    crsCube
	FETCH   crsCube
	INTO    @HostCompany, @SheetLookupID, @CubeName
	  WHILE (@@FETCH_STATUS = 0) BEGIN
            SELECT @Work = @PublicationDatabase + '..mbbmspFactDataDelete'
            EXEC @Work @CubeName, @SheetLookupID
            FETCH   crsCube
            INTO    @HostCompany, @SheetLookupID, @CubeName
          END
          CLOSE crsCube
          DEALLOCATE crsCube

	--Delete Plan Sheets
	DELETE  mbbmPlanSheet74 
	FROM    #mbbmPlanTreeDelete
	WHERE   mbbmPlanSheet74.PlanID = #mbbmPlanTreeDelete.PlanID
		AND (mbbmPlanSheet74.SheetID = #mbbmPlanTreeDelete.SheetID
			OR #mbbmPlanTreeDelete.SheetID = 0) 

	--Delete Plan Related Items
	IF @SheetID = 0 BEGIN
		--Delete Cube Related Items
		DELETE  mbbmCubeDimAttributes
		FROM    #mbbmPlanTreeDelete d 
			JOIN mbbmPlan74 p ON
        	        (d.PlanID = p.PlanID) 
			JOIN mbbmCubes75 c ON
			(p.PlanID = c.PlanID AND p.HostCompany = c.HostCompany)
			JOIN mbbmCubeDimAttributes a ON
                        (c.HostCompany = a.HostCompany AND c.Name = a.CubeName)

		DELETE  mbbmOLAPSecurityCell
		FROM    #mbbmPlanTreeDelete d 
			JOIN mbbmPlan74 p ON
        	        (d.PlanID = p.PlanID) 
			JOIN mbbmCubes75 c ON
			(p.PlanID = c.PlanID AND p.HostCompany = c.HostCompany)
			JOIN mbbmOLAPSecurityCell s ON
                        (c.HostCompany = s.HostCompany AND c.Name = s.CubeName)

		DELETE  mbbmOLAPSecurityCube
		FROM    #mbbmPlanTreeDelete d 
			JOIN mbbmPlan74 p ON
        	        (d.PlanID = p.PlanID) 
			JOIN mbbmCubes75 c ON
			(p.PlanID = c.PlanID AND p.HostCompany = c.HostCompany)
			JOIN mbbmOLAPSecurityCube s ON
                        (c.HostCompany = s.HostCompany AND c.Name = s.CubeName)

		DELETE  mbbmCubes75
		FROM    #mbbmPlanTreeDelete d 
			JOIN mbbmPlan74 p ON
        	        (d.PlanID = p.PlanID) 
			JOIN mbbmCubes75 c ON
			(p.PlanID = c.PlanID AND p.HostCompany = c.HostCompany)

		DELETE  mbbmPlanHist
		WHERE   PlanID = @PlanID

		DELETE  mbbmPlanSec 
		WHERE   PlanID = @PlanID

		DELETE  mbbmPlan74 
		WHERE   PlanID = @PlanID
	END

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanSheetDelete] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanSheetDelete] TO [public]
GO
