SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspFormulaToTmp]
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
	EXEC    mbbmspTmpFormulaPurge @Spid

	INSERT  mbbmTmpFormula
		(Spid,  FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate)
	SELECT  @Spid, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate 
	FROM    mbbmFormula74
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = 1
		AND FormulaOwnerType    = @FormulaOwnerType 
		AND FormulaOwnerID      = @FormulaOwnerID 

	INSERT  mbbmTmpFormulaLines
		(Spid,  FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue)
	SELECT  @Spid, FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue
	FROM    mbbmFormulaLines74
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = 1
		AND FormulaOwnerType    = @FormulaOwnerType 
		AND FormulaOwnerID      = @FormulaOwnerID

	INSERT  mbbmTmpFormulaQry
		(Spid,  FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query)
	SELECT  @Spid, FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query
	FROM    mbbmFormulaQry74
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = 1
		AND FormulaOwnerType    = @FormulaOwnerType 
		AND FormulaOwnerID      = @FormulaOwnerID

	INSERT  mbbmTmpFormulaAccountDim
		(Spid,  FormulaKey, Sequence, AccountDim, FromValue, ThruValue)
	SELECT  @Spid, FormulaKey, Sequence,  AccountDim, FromValue, ThruValue
	FROM    mbbmFormulaAccountDim
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = 1
		AND FormulaOwnerType    = @FormulaOwnerType 
		AND FormulaOwnerID      = @FormulaOwnerID

	INSERT  mbbmTmpFormulaPubQry
		(Spid,  FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues)
	SELECT  @Spid, FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues
	FROM    mbbmFormulaPubQry
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = 1
		AND FormulaOwnerType    = @FormulaOwnerType 
		AND FormulaOwnerID      = @FormulaOwnerID

	INSERT  mbbmTmpFormulaQryTables
		(Spid,  FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer)
	SELECT  @Spid, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer
	FROM    mbbmFormulaQryTables74
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = 1
		AND FormulaOwnerType    = @FormulaOwnerType 
		AND FormulaOwnerID      = @FormulaOwnerID
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspFormulaToTmp] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspFormulaToTmp] TO [public]
GO
