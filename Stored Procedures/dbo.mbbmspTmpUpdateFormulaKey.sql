SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspTmpUpdateFormulaKey]
	@Spid           int,
	@OldKey		mbbmudtFormulaKey,
	@NewKey        	mbbmudtFormulaKey
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
	SELECT  Spid, @NewKey, Description, InclPrevAlloc, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime, FormulaFromTemplate
	FROM    mbbmTmpFormula
	WHERE   Spid = @Spid AND
                FormulaKey = @OldKey

	INSERT  mbbmTmpFormulaLines
		(Spid,  FormulaKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue)
	SELECT  Spid, @NewKey, Sequence, OpenParen, LineType, Year, FromPeriodType, FromPeriodNo, ThruPeriodType, ThruPeriodNo, BalanceType, BalanceTypeCode, CompanyCode, Currency, HomeNatural, ValuationMethod, Constant, FromAcct, ThruAcct, CloseParen, Operation, ReferenceType, ReferenceValue
	FROM    mbbmTmpFormulaLines
	WHERE   Spid = @Spid AND
                FormulaKey = @OldKey

	INSERT  mbbmTmpFormulaQry
		(Spid,  FormulaKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query)
	SELECT  Spid, @NewKey, Sequence, DataSourceType, Connect, QueryOptions, Advanced, Query
	FROM    mbbmTmpFormulaQry
	WHERE   Spid = @Spid AND
		FormulaKey = @OldKey

	INSERT  mbbmTmpFormulaAccountDim
		(Spid,  FormulaKey, Sequence, AccountDim, FromValue, ThruValue)
	SELECT  Spid, @NewKey, Sequence, AccountDim, FromValue, ThruValue
	FROM    mbbmTmpFormulaAccountDim
	WHERE   Spid = @Spid AND
		FormulaKey = @OldKey

	INSERT  mbbmTmpFormulaPubQry
		(Spid,  FormulaKey, Sequence, DimCode, FromValue, ThruValue, AllValues)
	SELECT  Spid, @NewKey, Sequence, DimCode, FromValue, ThruValue, AllValues
	FROM    mbbmTmpFormulaPubQry
	WHERE   Spid = @Spid AND
		FormulaKey = @OldKey

	INSERT  mbbmTmpFormulaQryTables
		(Spid, FormulaKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer)
	SELECT  Spid, @NewKey, Sequence, TableSequence, Alias, TableSpec, LinkedServer
	FROM    mbbmTmpFormulaQryTables
	WHERE   Spid = @Spid AND
		FormulaKey = @OldKey

	DELETE 
	FROM 	mbbmTmpFormulaQryTables
	WHERE	Spid = @Spid AND
		FormulaKey = @OldKey

	DELETE 
	FROM 	mbbmTmpFormulaQry
	WHERE	Spid = @Spid AND
		FormulaKey = @OldKey

	DELETE 
	FROM	mbbmTmpFormulaAccountDim
	WHERE   Spid = @Spid AND 
		FormulaKey = @OldKey

	DELETE 
	FROM 	mbbmTmpFormulaPubQry
	WHERE	Spid = @Spid AND
		FormulaKey = @OldKey

	DELETE 
	FROM 	mbbmTmpFormulaLines
	WHERE	Spid = @Spid AND
		FormulaKey = @OldKey

	DELETE 
	FROM 	mbbmTmpFormula
	WHERE	Spid = @Spid AND
		FormulaKey = @OldKey

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpUpdateFormulaKey] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpUpdateFormulaKey] TO [public]
GO
