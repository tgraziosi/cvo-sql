SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspInitializeCompanyEx]
	@HostCompany		mbbmudtCompanyCode,
	@LoadData		mbbmudtYesNo
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
	IF @LoadData = 1 BEGIN
		DELETE mbbmOptions75 WHERE HostCompany = @HostCompany
		INSERT mbbmOptions75 (HostCompany, JournalCode, BatchNoOption, BatchControlMask, BatchControlNo,
			JournalNoOption, JournalControlMask, JournalControlNo, 
			AvgDailyBalExclSat, AvgDailyBalExclSun, UpdatedBy, UpdatedTime,
			ExclInactiveAccts, AccountSizeUnmasked, NextProcessID, UploadMultiUser, OverwriteEntire)
		SELECT	@HostCompany, 'GJ', 0, 'ALLOC000000', 1, 0, 'ALLOC000000', 1, 0, 0, hostname, GETDATE(), 0, 0, 1, 0, 0
		FROM	master..sysprocesses WHERE spid = @@SPID
	END


	INSERT INTO mbbmAccountDimensions74([HostCompany], [Dimension_Num], [Dimension_Code], [Dimension_Mask], [Description], [Dimension_Active])
		VALUES (@HostCompany, 1, 'REFCODE','!###############################','Reference Code', 1)

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspInitializeCompanyEx] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspInitializeCompanyEx] TO [public]
GO
