SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspPlanBranchUpdate]
	@PlanID         int = 0,
	@SheetID        int = 0,
	@BitWiseUpdate	int = 0,
	@Status		varchar(16) = '',
	@SheetManager	mbbmudtUser = '',
	@Internet	mbbmudtYesNo = 0,
	@Locked		mbbmudtYesNo = 0,
	@Revision	varchar(8) = '',
	@RevUpdate	int = 0,
	@SheetPublish	mbbmudtYesNo = 1,
	@GroupPublish   mbbmudtYesNo = 1,
	@Group		varchar(16) = '',
	@RowsAffected	int OUTPUT

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
		@UpdStatus		int,
		@UpdSheetMngr		int,
		@UpdLocked		int,
		@UpdInternet		int,
		@UpdRevision		int,
		@UndoCheckouts		int,
		@UpdRevisionLock	int,
		@UpdSheetPublish	int,
		@UpdGroupPublish	int,

		@SQLSetString		varchar(255),
		@TmpPlanID		int,
		@TmpSheetID		int,
                @TmpSheetType           int, 
		@TmpActiveRevision	int,
		@TmpMatchRevisionID	int,
		@TmpRevisionKey		varchar(8),
		@TmpOldRevisionKey      varchar(8),
                @TmpGroupKey		varchar(16),
		@TmpGroupPublish	int,

		@OldStatus		varchar(16),
		@OldSheetManager	mbbmudtUser,
		@OldLocked		mbbmudtYesNo,
		@OldRevision		varchar(8),
		@OldSheetPublish	mbbmudtYesNo,
		@OldGroupPublish	mbbmudtYesNo,
		@OldGroup		varchar(16),
			
                @ExcelType              int,
		@PlanSheetType		int,
		@TemplateType		int,
		@FirstCount             int,
                @SecondCount            int,
		@ThirdCount		int,
		@FourthCount		int,
		@FifthCount		int,
		@NewRevID		int,
		@LastCount		int,
		@HostCompany		mbbmudtCompanyCode

	-- Setup bit operators, these must be matched in the calling sub
	SELECT @UpdStatus = 1
	SELECT @UpdSheetMngr = 2
	SELECT @UpdLocked = 4
	SELECT @UpdInternet = 8
	SELECT @UpdRevision = 16
	SELECT @UndoCheckouts = 32
	SELECT @UpdRevisionLock = 64
	SELECT @UpdSheetPublish = 128
	SELECT @UpdGroupPublish = 256

	SELECT @SQLSetString = ''

	SELECT @ExcelType = 1
	SELECT @PlanSheetType = 0
	SELECT @TemplateType = 4
        SELECT @FirstCount = 0
        SELECT @SecondCount = 0
	SELECT @ThirdCount = 0
	SELECT @FourthCount = 0
	SELECT @FifthCount = 0
	SELECT @LastCount = 0

	CREATE TABLE #tbBranchTmp  (PlanID	int,
				   SheetID	int,
				   NodeLevel	int,
                                   SheetType    int)

	IF @BitWiseUpdate <> 0 BEGIN

		BEGIN TRANSACTION

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
			WHERE   Parent IN (SELECT SheetID FROM #tbBranchTmp WHERE NodeLevel = @CurrentLevel)
			AND	PlanID = @PlanID
		END

		-- Update the mbbmPlanHist table with the changes
		DECLARE crsOldValues CURSOR FOR
		SELECT  aPS.PlanID, aPS.SheetID, aPS.Status, aPS.SheetManager, aPS.Locked, aPS.SheetType, aPS.Publish
		FROM    mbbmPlanSheet74 aPS, #tbBranchTmp aBT WHERE aPS.PlanID = aBT.PlanID AND aPS.SheetID = aBT.SheetID

		OPEN    crsOldValues
		FETCH   crsOldValues
		INTO    @TmpPlanID, @TmpSheetID, @OldStatus, @OldSheetManager, @OldLocked, @TmpSheetType, @OldSheetPublish

		WHILE (@@FETCH_STATUS = 0) BEGIN
			IF (@BitWiseUpdate & @UpdStatus) = @UpdStatus AND @OldStatus <> @Status BEGIN
				INSERT mbbmPlanHist(PlanID, SheetID, RevisionID, ChangeTime, EventCode, OldValue, NewValue, Description)
				VALUES(@TmpPlanID, @TmpSheetID, 0, '12:00:00', 2022, @OldStatus, @Status, '')
				INSERT #mbStatusChange (SheetID) VALUES (@TmpSheetID)
			END
			IF (@BitWiseUpdate & @UpdLocked) = @UpdLocked AND @OldLocked <> @Locked AND @TmpSheetType <> @ExcelType BEGIN
				INSERT mbbmPlanHist(PlanID, SheetID, RevisionID, ChangeTime, EventCode, OldValue, NewValue, Description)
				VALUES(@TmpPlanID, @TmpSheetID, 0, '12:00:00', 2021, CONVERT(varchar(16), @OldLocked), CONVERT(varchar(16), @Locked), '')
			END
			IF (@BitWiseUpdate & @UpdSheetMngr) = @UpdSheetMngr AND @OldSheetManager <> @SheetManager BEGIN
				INSERT mbbmPlanHist(PlanID, SheetID, RevisionID, ChangeTime, EventCode, OldValue, NewValue, Description)
				VALUES(@TmpPlanID, @TmpSheetID, 0, '12:00:00', 2011, @OldSheetManager, @SheetManager, '')
			END

			IF (@BitWiseUpdate & @UpdSheetPublish) = @UpdSheetPublish AND @OldSheetPublish <> @SheetPublish BEGIN
				INSERT mbbmPlanHist(PlanID, SheetID, RevisionID, ChangeTime, EventCode, OldValue, NewValue, Description)
				VALUES(@TmpPlanID, @TmpSheetID, 0, '12:00:00', 2025, @OldSheetPublish, @SheetPublish, '')
			END

			FETCH crsOldValues
			INTO @TmpPlanID, @TmpSheetID, @OldStatus, @OldSheetManager, @OldLocked, @TmpSheetType, @OldSheetPublish
		END
		CLOSE crsOldValues
		DEALLOCATE crsOldValues

		IF (@BitWiseUpdate & @UpdStatus) = @UpdStatus BEGIN
			IF @SQLSetString <> '' BEGIN
				SELECT @SQLSetString = @SQLSetString + ', '
			END
			SELECT @SQLSetString = @SQLSetString + 'Status = ''' + @Status + ''''
		END
		IF (@BitWiseUpdate & @UpdInternet) = @UpdInternet BEGIN
			IF @SQLSetString <> '' BEGIN
				SELECT @SQLSetString = @SQLSetString + ', '
			END
			SELECT @SQLSetString = @SQLSetString + 'InternetEnabled = ' + CONVERT(varchar(1), @Internet)
		END
		IF (@BitWiseUpdate & @UpdSheetMngr) = @UpdSheetMngr BEGIN
			IF @SQLSetString <> '' BEGIN
				SELECT @SQLSetString = @SQLSetString + ', '
			END
			SELECT @SQLSetString = @SQLSetString + 'SheetManager = ''' + @SheetManager + ''''
		END

		IF @SQLSetString <> '' BEGIN
			SELECT @SQLSetString = 'UPDATE mbbmPlanSheet74 SET ' + @SQLSetString + 
				' FROM mbbmPlanSheet74 aPS, #tbBranchTmp aBT WHERE aPS.PlanID = aBT.PlanID AND aPS.SheetID = aBT.SheetID'

			EXECUTE (@SQLSetString)

			SELECT @FirstCount = @@ROWCOUNT
		END 

		IF (@BitWiseUpdate & @UpdSheetPublish) = @UpdSheetPublish BEGIN
			SELECT @SQLSetString = 'Publish = ' + CONVERT(varchar(1), @SheetPublish)

			SELECT @SQLSetString = 'UPDATE mbbmPlanSheet74 SET ' + @SQLSetString + 
				' FROM mbbmPlanSheet74 aPS, #tbBranchTmp aBT WHERE aPS.PlanID = aBT.PlanID AND aPS.SheetID = aBT.SheetID AND aPS.SheetType <> 1 '

			EXECUTE (@SQLSetString)

			SELECT @FourthCount = @@ROWCOUNT
		END

		IF (@BitWiseUpdate & @UpdGroupPublish) = @UpdGroupPublish BEGIN
			DECLARE crsOldValues CURSOR FOR
			SELECT  aPS.PlanID, aPS.SheetID, aPS.SheetType, aPS.ActiveRevision, 
                                aGP.GroupKey, aGP.Publish
			FROM    #tbBranchTmp aBT 
	                INNER JOIN mbbmPlanSheet74 aPS 
	                ON (aPS.PlanID = aBT.PlanID AND 
	                    aPS.SheetID = aBT.SheetID AND 
	                    aPS.SheetType <> 1)
			INNER JOIN mbbmPlanSheetRev74 aRV 
	                ON (aPS.SheetID = aRV.SheetID AND
	                    aRV.RevisionID = aPS.ActiveRevision)
			INNER JOIN mbbmPlanGrp74 aGP 
	                ON (aGP.RevisionID = aRV.RevisionID AND 
			    aGP.Publish <> @GroupPublish AND 
                            aGP.GroupKey = @Group)

			OPEN    crsOldValues
			FETCH   crsOldValues
			INTO    @TmpPlanID, @TmpSheetID, @TmpSheetType, @TmpActiveRevision, 
                                @TmpGroupKey, @TmpGroupPublish
	
			WHILE (@@FETCH_STATUS = 0) BEGIN
				UPDATE mbbmPlanGrp74  
				SET Publish = @GroupPublish
				WHERE RevisionID = @TmpActiveRevision AND
				GroupKey = @TmpGroupKey 

				SELECT @FifthCount = @@ROWCOUNT

				FETCH crsOldValues
				INTO  @TmpPlanID, @TmpSheetID, @TmpSheetType, @TmpActiveRevision, 
	                              @TmpGroupKey, @TmpGroupPublish
			END
			CLOSE crsOldValues
			DEALLOCATE crsOldValues
		END

		IF (@BitWiseUpdate & @UpdLocked) = @UpdLocked BEGIN
			SELECT @SQLSetString = 'Locked = ' + CONVERT(varchar(1), @Locked)

			SELECT @SQLSetString = 'UPDATE mbbmPlanSheet74 SET ' + @SQLSetString + 
				' FROM mbbmPlanSheet74 aPS, #tbBranchTmp aBT WHERE aPS.PlanID = aBT.PlanID AND aPS.SheetID = aBT.SheetID AND aPS.SheetType <> 1 AND aPS.CheckedOut = 0'

			EXECUTE (@SQLSetString)

			SELECT @SecondCount = @@ROWCOUNT
		END

		IF (@BitWiseUpdate & @UpdRevision) = @UpdRevision BEGIN

			DECLARE crsOldValues CURSOR FOR
			SELECT  aPS.PlanID, aPS.SheetID, aPS.SheetType, aPS.ActiveRevision, 
                                aRV.RevisionID, aRV.RevisionKey, aRVO.RevisionKey AS OldRevKey
			FROM    #tbBranchTmp aBT 
	                INNER JOIN mbbmPlanSheet74 aPS 
	                ON (aPS.PlanID = aBT.PlanID AND 
	                    aPS.SheetID = aBT.SheetID AND 
	                    (aPS.SheetType = @PlanSheetType OR aPS.SheetType = @TemplateType))
			LEFT JOIN mbbmPlanSheetRev74 aRV 
	                ON (aPS.SheetID = aRV.SheetID AND
	                    aRV.RevisionKey = @Revision)
			LEFT JOIN mbbmPlanSheetRev74 aRVO 
	                ON (aPS.SheetID = aRVO.SheetID AND
	                    aRVO.RevisionID = aPS.ActiveRevision)

			OPEN    crsOldValues
			FETCH   crsOldValues
			INTO    @TmpPlanID, @TmpSheetID, @TmpSheetType, @TmpActiveRevision, @TmpMatchRevisionID, 
                                @TmpRevisionKey, @TmpOldRevisionKey
	
			WHILE (@@FETCH_STATUS = 0) BEGIN
				IF @TmpMatchRevisionID IS NOT NULL BEGIN
					IF @TmpActiveRevision <> @TmpMatchRevisionID BEGIN

						UPDATE mbbmPlanSheet74 
						SET ActiveRevision = @TmpMatchRevisionID
						WHERE PlanID = @TmpPlanID
						AND SheetID = @TmpSheetID
						
						SELECT @LastCount = @@ROWCOUNT

						IF @LastCount > 0 BEGIN
							SELECT @ThirdCount = @ThirdCount + @LastCount

							INSERT mbbmPlanHist(PlanID, SheetID, RevisionID, ChangeTime, EventCode, OldValue, NewValue, Description)
							VALUES(@TmpPlanID, @TmpSheetID, 0, GETDATE(), 3021, ISNULL(@TmpOldRevisionKey,''), @Revision, '')

						END
					END
					ELSE BEGIN
						SELECT @ThirdCount = @ThirdCount + 1
					END
				END
				ELSE BEGIN
					IF @RevUpdate = 0 BEGIN
						IF @TmpActiveRevision <> 0 BEGIN
							INSERT mbbmPlanSheetRev74(SheetID, RevisionKey, CurrentDate, PrintSettings, Spreadsheet, RowIDGen, ParIDGen, RowIDFunc, ParIDFunc, BaseDateType)
							SELECT SheetID, @Revision, CurrentDate, PrintSettings, Spreadsheet, RowIDGen, ParIDGen, RowIDFunc, ParIDFunc, BaseDateType
                                	                FROM   mbbmPlanSheetRev74
                                        	        WHERE  SheetID = @TmpSheetID
                                                	AND    RevisionID = @TmpActiveRevision
							
							SELECT @NewRevID = (SELECT RevisionID FROM mbbmPlanSheetRev74 WHERE SheetID = @TmpSheetID AND RevisionKey = @Revision)

							EXEC mbbmspCopySheetRevDependents @HostCompany, @TmpActiveRevision, @NewRevID

							UPDATE mbbmPlanSheet74
							SET ActiveRevision = @NewRevID
							WHERE PlanID = @TmpPlanID
							AND SheetID = @TmpSheetID

							SELECT @LastCount = @@ROWCOUNT
		
							IF @LastCount > 0 BEGIN
								SELECT @ThirdCount = @ThirdCount + @LastCount

								INSERT mbbmPlanHist(PlanID, SheetID, RevisionID, ChangeTime, EventCode, OldValue, NewValue, Description)
								VALUES(@TmpPlanID, @TmpSheetID, @NewRevID, GETDATE(), 3001, @Revision, @Revision, '')

								INSERT mbbmPlanHist(PlanID, SheetID, RevisionID, ChangeTime, EventCode, OldValue, NewValue, Description)
								VALUES(@TmpPlanID, @TmpSheetID, 0, GETDATE(), 3021, ISNULL(@TmpOldRevisionKey,''), @Revision, '')

							END
						END
						ELSE BEGIN
							SELECT @ThirdCount = @ThirdCount + 1
						END
					END
					ELSE BEGIN
						SELECT @ThirdCount = @ThirdCount + 1
					END
				END


				FETCH crsOldValues
				INTO    @TmpPlanID, @TmpSheetID, @TmpSheetType, @TmpActiveRevision, @TmpMatchRevisionID, @TmpRevisionKey, @TmpOldRevisionKey
			END
			CLOSE crsOldValues
			DEALLOCATE crsOldValues
		END

		IF (@FirstCount + @SecondCount + @ThirdCount + @FourthCount + @FifthCount) = 0 BEGIN
			SELECT @RowsAffected = 0
			ROLLBACK TRANSACTION
		END
		ELSE BEGIN
			SELECT @RowsAffected = @FirstCount + @SecondCount + @ThirdCount + @FourthCount + @FifthCount
			COMMIT TRANSACTION
		END
	END
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanBranchUpdate] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspPlanBranchUpdate] TO [public]
GO
