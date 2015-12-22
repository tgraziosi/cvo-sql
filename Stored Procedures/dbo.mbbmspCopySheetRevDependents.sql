SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspCopySheetRevDependents] 
	@HostCompany    mbbmudtCompanyCode,
	@RevisionID     int,
	@NewRevisionID  int
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
	DECLARE @HistPlanKeyPrefix varchar(17)
	DECLARE @HistPlanKeyPrefixLen int

	DECLARE @NewPlanKeyPrefix varchar(17)
	DECLARE @NewPlanKeyPrefixLen int

	SELECT  @HistPlanKeyPrefix = mbbmPlan74.PlanKey + '.' FROM mbbmPlan74, mbbmPlanSheet74, mbbmPlanSheetRev74
	WHERE   mbbmPlan74.PlanID = mbbmPlanSheet74.PlanID
        AND     mbbmPlanSheet74.SheetID = mbbmPlanSheetRev74.SheetID
	AND     mbbmPlanSheetRev74.RevisionID = @RevisionID

	SELECT @HistPlanKeyPrefixLen = LEN(@HistPlanKeyPrefix)

	SELECT  @NewPlanKeyPrefix = mbbmPlan74.PlanKey + '.' FROM mbbmPlan74, mbbmPlanSheet74, mbbmPlanSheetRev74
	WHERE   mbbmPlan74.PlanID = mbbmPlanSheet74.PlanID
        AND     mbbmPlanSheet74.SheetID = mbbmPlanSheetRev74.SheetID
	AND     mbbmPlanSheetRev74.RevisionID = @NewRevisionID

	SELECT @NewPlanKeyPrefixLen = LEN(@NewPlanKeyPrefix)

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
		SELECT  @NewRevisionID, SectionKey
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

	INSERT  mbbmPlanSheetDimensions74 (RevisionID, Axis, Member, TierCode, GroupCode, Code, FromValue, ThruValue, Flags, Mask, Length)
		SELECT  @NewRevisionID, Axis, Member, TierCode, GroupCode, Code, FromValue, ThruValue, Flags, Mask, Length
		FROM    mbbmPlanSheetDimensions74
		WHERE   RevisionID = @RevisionID

	INSERT  mbbmFormula74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate 
		FROM    mbbmFormula74
		WHERE   HostCompany = @HostCompany
			AND     FormulaType = 1
			AND     FormulaOwnerType = 2 
			AND     FormulaOwnerID = @RevisionID

	INSERT  mbbmFormulaLines74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Sequence, OpenParen, 
                        LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, 

			CASE 
			  WHEN (LineType = 3 OR LineType = 4 OR LineType = 5) AND (LEFT(BalanceTypeCode,@HistPlanKeyPrefixLen) = @HistPlanKeyPrefix)
                            THEN @NewPlanKeyPrefix + RIGHT(BalanceTypeCode, LEN(BalanceTypeCode) - @HistPlanKeyPrefixLen)
		          ELSE BalanceTypeCode			
			END

			, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant,
			FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue

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

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspCopySheetRevDependents] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspCopySheetRevDependents] TO [public]
GO
