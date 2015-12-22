SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspTmpFormulaToTmpFormula]
	@SourceSpid             int,
	@DestSpid               int
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

	INSERT  mbbmTmpFormula
		(Spid,  FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate)
	SELECT  @DestSpid, FormulaKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate
	FROM    mbbmTmpFormula
	WHERE   Spid = @SourceSpid

	INSERT  mbbmTmpFormulaLines
		(Spid,  FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue)
	SELECT  @DestSpid, FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue
	FROM    mbbmTmpFormulaLines
	WHERE   Spid = @SourceSpid

	INSERT  mbbmTmpFormulaQry
		(Spid,  FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query)
	SELECT  @DestSpid, FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query
	FROM    mbbmTmpFormulaQry
	WHERE   Spid = @SourceSpid

	INSERT  mbbmTmpFormulaAccountDim
		(Spid,  FormulaKey, Sequence, AccountDim, FromValue, ThruValue)
	SELECT  @DestSpid, FormulaKey, Sequence, AccountDim, FromValue, ThruValue
	FROM    mbbmTmpFormulaAccountDim
	WHERE   Spid = @SourceSpid

	INSERT  mbbmTmpFormulaPubQry
		(Spid,  FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues)
	SELECT  @DestSpid, FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues
	FROM    mbbmTmpFormulaPubQry
	WHERE   Spid = @SourceSpid

	INSERT  mbbmTmpFormulaQryTables
		(Spid, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer)
	SELECT  @DestSpid, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer
	FROM    mbbmTmpFormulaQryTables
	WHERE   Spid = @SourceSpid

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpFormulaToTmpFormula] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpFormulaToTmpFormula] TO [public]
GO
