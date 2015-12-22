SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspTmpToFormula]
	@HostCompany            mbbmudtCompanyCode,
	@FormulaOwnerType       tinyint,
	@FormulaOwnerID         int,
	@Spid                   int
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
	EXEC    mbbmspFormulaPurge @HostCompany, 1, @FormulaOwnerType, @FormulaOwnerID

	INSERT  mbbmFormula74
		(HostCompany, FormulaType,  FormulaOwnerType,  FormulaOwnerID, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate)
	SELECT  @HostCompany, 1, @FormulaOwnerType, @FormulaOwnerID, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate 
	FROM    mbbmTmpFormula
	WHERE   Spid = @Spid

	INSERT  mbbmFormulaLines74
		(HostCompany, FormulaType,  FormulaOwnerType,  FormulaOwnerID, FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue)
	SELECT  @HostCompany, 1, @FormulaOwnerType, @FormulaOwnerID, FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue
	FROM    mbbmTmpFormulaLines
	WHERE   Spid = @Spid

	INSERT  mbbmFormulaQry74
		(HostCompany, FormulaType,  FormulaOwnerType,  FormulaOwnerID, FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query)
	SELECT  @HostCompany, 1, @FormulaOwnerType, @FormulaOwnerID, FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query
	FROM    mbbmTmpFormulaQry
	WHERE   Spid = @Spid

	INSERT  mbbmFormulaAccountDim
		(HostCompany, FormulaType,  FormulaOwnerType,  FormulaOwnerID, FormulaKey, Sequence, AccountDim, FromValue, ThruValue)
	SELECT  @HostCompany, 1, @FormulaOwnerType, @FormulaOwnerID, FormulaKey, Sequence,  AccountDim, FromValue, ThruValue
	FROM    mbbmTmpFormulaAccountDim
	WHERE   Spid = @Spid

	INSERT  mbbmFormulaPubQry
		(HostCompany, FormulaType,  FormulaOwnerType,  FormulaOwnerID, FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues)
	SELECT  @HostCompany, 1, @FormulaOwnerType, @FormulaOwnerID, FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues
	FROM    mbbmTmpFormulaPubQry
	WHERE   Spid = @Spid

	INSERT  mbbmFormulaQryTables74
		(HostCompany, FormulaType,  FormulaOwnerType,  FormulaOwnerID, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer)
	SELECT  @HostCompany, 1, @FormulaOwnerType, @FormulaOwnerID, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer
	FROM    mbbmTmpFormulaQryTables
	WHERE   Spid = @Spid
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpToFormula] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpToFormula] TO [public]
GO
