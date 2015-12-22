SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspCopyFormula] 
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

	INSERT  mbbmFormulaAccountDim (HostCompany, FormulaType, FormulaOwnerType, FormulaOwnerID, FormulaKey, Sequence, AccountDim, FromValue, ThruValue)
		SELECT  HostCompany, FormulaType, FormulaOwnerType, @NewRevisionID, FormulaKey, Sequence, AccountDim, FromValue, ThruValue
		FROM    mbbmFormulaAccountDim
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
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspCopyFormula] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspCopyFormula] TO [public]
GO
