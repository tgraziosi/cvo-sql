SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspTmpFormulaDel] 
	@FormulaKey     mbbmudtFormulaKey,
	@Spid           int
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
	DELETE  mbbmTmpFormulaQryTables
	WHERE   Spid = @Spid
		AND FormulaKey = @FormulaKey

	DELETE  mbbmTmpFormulaQry
	WHERE   Spid = @Spid
		AND FormulaKey = @FormulaKey

	DELETE  mbbmTmpFormulaAccountDim
	WHERE   Spid = @Spid
		AND FormulaKey = @FormulaKey

	DELETE  mbbmTmpFormulaPubQry
	WHERE   Spid = @Spid
		AND FormulaKey = @FormulaKey

	DELETE  mbbmTmpFormulaLines 
	WHERE   Spid = @Spid
		AND FormulaKey = @FormulaKey

	DELETE  mbbmTmpFormula 
	WHERE   Spid = @Spid
		AND FormulaKey = @FormulaKey

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpFormulaDel] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpFormulaDel] TO [public]
GO
