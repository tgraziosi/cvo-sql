SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspDuplicateSheetDependents] 
	@HostCompany    mbbmudtCompanyCode,
	@SheetID        int,
	@NewSheetID     int
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
	DECLARE @RevisionID     int,
		@RevisionKey    varchar(16),
		@NewRevisionID  int,
		@HistPlanID     int

	SELECT  @HistPlanID = PlanID FROM mbbmPlanSheet74 WHERE SheetID = @NewSheetID

	INSERT  mbbmPlanSheetSec (SheetID, UserID, SecLevel) 
		SELECT  @NewSheetID, UserID, SecLevel 
		FROM    mbbmPlanSheetSec 
		WHERE   SheetID = @SheetID
	
	INSERT  mbbmPlanView (HostCompany, SheetID, GroupKey, Type, Value) 
		SELECT  HostCompany, @NewSheetID, GroupKey, Type, Value 
		FROM    mbbmPlanView 
		WHERE   SheetID = @SheetID

	DECLARE crsRevision CURSOR FOR
	SELECT  RevisionID,
		RevisionKey
	FROM    mbbmPlanSheetRev74
	WHERE   SheetID = @SheetID

	OPEN    crsRevision

	FETCH   crsRevision
	INTO    @RevisionID,
		@RevisionKey

	WHILE (@@FETCH_STATUS = 0) BEGIN
		INSERT  mbbmPlanSheetRev74 (SheetID, RevisionKey, CurrentDate, PrintSettings, Spreadsheet, RowIDGen, ParIDGen, RowIDFunc, ParIDFunc, BaseDateType) 
			SELECT  @NewSheetID, RevisionKey, CurrentDate, PrintSettings, Spreadsheet, RowIDGen, ParIDGen, RowIDFunc, ParIDFunc, BaseDateType 
			FROM    mbbmPlanSheetRev74 
			WHERE   RevisionID = @RevisionID

		SELECT  @NewRevisionID = RevisionID
		FROM    mbbmPlanSheetRev74
		WHERE   SheetID = @NewSheetID
			AND RevisionKey = @RevisionKey

		INSERT  mbbmPlanHist (PlanID, SheetID, RevisionID, EventCode, OldValue, NewValue, Description) 
		VALUES  (@HistPlanID, @NewSheetID, @NewRevisionID, 3001, '', '', '')

		INSERT  mbbmPlanSheetDimensions74 (RevisionID, Axis, Member, TierCode, GroupCode, Code, FromValue, ThruValue, Flags, Mask, Length)
			SELECT  @NewRevisionID, Axis, Member, TierCode, GroupCode, Code, FromValue, ThruValue, Flags, Mask, Length
			FROM    mbbmPlanSheetDimensions74
			WHERE   RevisionID = @RevisionID

		INSERT  mbbmPlanHfc (RevisionID, CellType, Section, Line, Text, FontName, FontSize, FontAttrib) 
			SELECT  @NewRevisionID, CellType, Section, Line, Text, FontName, FontSize, FontAttrib 
			FROM    mbbmPlanHfc 
			WHERE   RevisionID = @RevisionID

		INSERT  mbbmPlanGrp74 (RevisionID, GroupKey, Description, CurrentDateType, CurrentDate, YearOffset, PeriodOffset, BalanceType, BalanceCode, ModelOrder, ModelColumnPrefix, ModelColumnDescription, ModelValuation, ModelFromPeriodType, ModelFromPeriod, ModelThruPeriodType, ModelThruPeriod, ModelLastFromPeriod, ModelLastThruPeriod, ModelFromIncrement, ModelThruIncrement, ModelLayoutStyle, ModelColumnTotal, Publish, GroupCalculation, MeasureName, ModelViewColumn, ModelViewTotal, UsePlanBudgetCode) 
			SELECT  @NewRevisionID, GroupKey, Description, CurrentDateType, CurrentDate, YearOffset, PeriodOffset, BalanceType, BalanceCode, ModelOrder, ModelColumnPrefix, ModelColumnDescription, ModelValuation, ModelFromPeriodType, ModelFromPeriod, ModelThruPeriodType, ModelThruPeriod, ModelLastFromPeriod, ModelLastThruPeriod, ModelFromIncrement, ModelThruIncrement, ModelLayoutStyle, ModelColumnTotal, Publish, GroupCalculation, MeasureName, ModelViewColumn, ModelViewTotal, UsePlanBudgetCode  
			FROM    mbbmPlanGrp74 
			WHERE   RevisionID = @RevisionID

		INSERT  mbbmPlanColSet (RevisionID, ColSetKey, Description) 
			SELECT  @NewRevisionID, ColSetKey, Description  
			FROM    mbbmPlanColSet 
			WHERE   RevisionID = @RevisionID

		INSERT  mbbmPlanSheetSections (RevisionID, SectionKey)
			SELECT	@NewRevisionID, SectionKey
			FROM    mbbmPlanSheetSections
			WHERE   RevisionID = @RevisionID

		INSERT  mbbmPlanCol7 (RevisionID, Position, GroupKey, ColumnKey, Description, FromPeriodType, FromPeriod, FromPeriodAct, ThruPeriodType, ThruPeriod, ThruPeriodAct, FromDate, ThruDate, Valuation, Title, DimValue1, DimValue2, DimValue3, DimValue4, ColSetKey) 
			SELECT  @NewRevisionID, Position, GroupKey, ColumnKey, Description, FromPeriodType, FromPeriod, FromPeriodAct, ThruPeriodType, ThruPeriod, ThruPeriodAct, FromDate, ThruDate, Valuation, Title, DimValue1, DimValue2, DimValue3, DimValue4, ColSetKey
			FROM    mbbmPlanCol7 
			WHERE   RevisionID = @RevisionID

		INSERT  mbbmPlanCustCol7 (RevisionID, Position, ColumnKey, Description, Title, DimCode, DimAttrName, DataType, TextFormat, TypeDateSeparator, TypeDateCentury, ColSetKey) 
			SELECT  @NewRevisionID, Position, ColumnKey, Description, Title, DimCode, DimAttrName, DataType, TextFormat, TypeDateSeparator, TypeDateCentury, ColSetKey
			FROM    mbbmPlanCustCol7 
			WHERE   RevisionID = @RevisionID

		INSERT  mbbmFormula74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate)
			SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate 
			FROM    mbbmFormula74
			WHERE   HostCompany = @HostCompany
				AND     FormulaType = 1
				AND     FormulaOwnerType = 2 
				AND     FormulaOwnerID = @RevisionID

		INSERT  mbbmFormulaLines74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue)
			SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue
			FROM    mbbmFormulaLines74
			WHERE   HostCompany = @HostCompany
				AND     FormulaType = 1
				AND     FormulaOwnerType = 2 
				AND     FormulaOwnerID = @RevisionID

		INSERT  mbbmFormulaQry74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query)
			SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query
			FROM    mbbmFormulaQry74
			WHERE   HostCompany = @HostCompany
				AND     FormulaType = 1
				AND     FormulaOwnerType = 2 
				AND     FormulaOwnerID = @RevisionID

		INSERT  mbbmFormulaPubQry (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues)
			SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues
			FROM    mbbmFormulaPubQry
			WHERE   HostCompany = @HostCompany
				AND     FormulaType = 1
				AND     FormulaOwnerType = 2 
				AND     FormulaOwnerID = @RevisionID

		INSERT  mbbmFormulaQryTables74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer)
			SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer
			FROM    mbbmFormulaQryTables74
			WHERE   HostCompany = @HostCompany
				AND     FormulaType = 1
				AND     FormulaOwnerType = 2 
				AND     FormulaOwnerID = @RevisionID

		INSERT  mbbmFormulaAccountDim (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, AccountDim, FromValue, ThruValue)
			SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Sequence, AccountDim, FromValue, ThruValue
			FROM    mbbmFormulaAccountDim
			WHERE   HostCompany = @HostCompany
				AND     FormulaType = 1
				AND     FormulaOwnerType = 2 
				AND     FormulaOwnerID = @RevisionID

		FETCH   crsRevision
		INTO    @RevisionID,
			@RevisionKey
	END
	CLOSE crsRevision
	DEALLOCATE crsRevision

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspDuplicateSheetDependents] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspDuplicateSheetDependents] TO [public]
GO
