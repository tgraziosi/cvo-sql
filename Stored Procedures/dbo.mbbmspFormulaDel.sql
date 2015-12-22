SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspFormulaDel] 
	@HostCompany            mbbmudtCompanyCode,
	@FormulaType            mbbmudtFormulaType,
	@FormulaOwnerType       tinyint,
	@FormulaOwnerID         int,
	@FormulaKey             mbbmudtFormulaKey
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
	DELETE  mbbmFormulaQryTables74
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = @FormulaType
		AND FormulaOwnerType    = @FormulaOwnerType
		AND FormulaOwnerID      = @FormulaOwnerID
		AND FormulaKey          = @FormulaKey

	DELETE  mbbmFormulaQry74
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = @FormulaType
		AND FormulaOwnerType    = @FormulaOwnerType
		AND FormulaOwnerID      = @FormulaOwnerID
		AND FormulaKey          = @FormulaKey

	DELETE  mbbmFormulaAccountDim
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = @FormulaType
		AND FormulaOwnerType    = @FormulaOwnerType
		AND FormulaOwnerID      = @FormulaOwnerID
		AND FormulaKey          = @FormulaKey

	DELETE  mbbmFormulaPubQry
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = @FormulaType
		AND FormulaOwnerType    = @FormulaOwnerType
		AND FormulaOwnerID      = @FormulaOwnerID
		AND FormulaKey          = @FormulaKey

	DELETE  mbbmFormulaLines74 
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = @FormulaType
		AND FormulaOwnerType    = @FormulaOwnerType
		AND FormulaOwnerID      = @FormulaOwnerID
		AND FormulaKey          = @FormulaKey

	DELETE  mbbmFormula74 
	WHERE   HostCompany             = @HostCompany
		AND FormulaType         = @FormulaType
		AND FormulaOwnerType    = @FormulaOwnerType
		AND FormulaOwnerID      = @FormulaOwnerID
		AND FormulaKey          = @FormulaKey
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspFormulaDel] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspFormulaDel] TO [public]
GO
