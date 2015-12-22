SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspCopyPlanFormulas] 
	@HostCompany    mbbmudtCompanyCode,
	@PlanID     int,
	@NewPlanID  int
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

	SELECT  @HistPlanKeyPrefix = mbbmPlan74.PlanKey + '.' FROM mbbmPlan74
	WHERE   mbbmPlan74.PlanID = @PlanID

	SELECT @HistPlanKeyPrefixLen = LEN(@HistPlanKeyPrefix)

	SELECT  @NewPlanKeyPrefix = mbbmPlan74.PlanKey + '.' FROM mbbmPlan74, mbbmPlanSheet74, mbbmPlanSheetRev74
	WHERE   mbbmPlan74.PlanID = @NewPlanID

	SELECT @NewPlanKeyPrefixLen = LEN(@NewPlanKeyPrefix)

	INSERT  mbbmFormula74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewPlanID, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate 
		FROM    mbbmFormula74
		WHERE   HostCompany = @HostCompany 
			AND     FormulaType = 2
			AND     FormulaOwnerType = 4 
			AND     FormulaOwnerID = @PlanID

	INSERT  mbbmFormulaLines74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewPlanID, FormulaKey, Sequence, OpenParen, 
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
			AND     FormulaType = 2
			AND     FormulaOwnerType = 4 
			AND     FormulaOwnerID = @PlanID

	INSERT  mbbmFormulaQry74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewPlanID, FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query 
		FROM    mbbmFormulaQry74
		WHERE   HostCompany = @HostCompany
			AND     FormulaType = 2
			AND     FormulaOwnerType = 4 
			AND     FormulaOwnerID = @PlanID

	INSERT  mbbmFormulaAccountDim (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, AccountDim, FromValue, ThruValue)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewPlanID, FormulaKey, Sequence, AccountDim, FromValue, ThruValue 
		FROM    mbbmFormulaAccountDim
		WHERE   HostCompany = @HostCompany
			AND     FormulaType = 2
			AND     FormulaOwnerType = 4 
			AND     FormulaOwnerID = @PlanID

	INSERT  mbbmFormulaPubQry (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewPlanID, FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues 
		FROM    mbbmFormulaPubQry
		WHERE   HostCompany = @HostCompany
			AND     FormulaType = 2
			AND     FormulaOwnerType = 4 
			AND     FormulaOwnerID = @PlanID

	INSERT  mbbmFormulaQryTables74 (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewPlanID, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer 
		FROM    mbbmFormulaQryTables74
		WHERE   HostCompany = @HostCompany
			AND     FormulaType = 2
			AND     FormulaOwnerType = 4 
			AND     FormulaOwnerID = @PlanID

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspCopyPlanFormulas] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspCopyPlanFormulas] TO [public]
GO
