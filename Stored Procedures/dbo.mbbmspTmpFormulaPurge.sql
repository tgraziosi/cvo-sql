SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspTmpFormulaPurge]
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

	DELETE  mbbmTmpFormulaQry
	WHERE   Spid = @Spid

	DELETE  mbbmTmpFormulaAccountDim
	WHERE   Spid = @Spid

	DELETE  mbbmTmpFormulaPubQry
	WHERE   Spid = @Spid

	DELETE  mbbmTmpFormulaLines 
	WHERE   Spid = @Spid

	DELETE  mbbmTmpFormula 
	WHERE   Spid = @Spid

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpFormulaPurge] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspTmpFormulaPurge] TO [public]
GO
