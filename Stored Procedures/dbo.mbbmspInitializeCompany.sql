SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspInitializeCompany]
	@Company        mbbmudtCompanyCode,
	@LoadData       mbbmudtYesNo
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
		DELETE  from mbbmSheetStatusCode6 where HostCompany = @Company and Code = 'A'
		INSERT  mbbmSheetStatusCode6 (HostCompany, Code, Description, SetDistList, SetUserID, SetMessage, SaveDistList, SaveUserID, SaveMessage, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime) 
		SELECT  @Company, 'A', 'Approved', 0, '', '', 0, '', '', hostname, GETDATE(), hostname, GETDATE()
		FROM    master..sysprocesses WHERE spid = @@SPID

		DELETE  from mbbmSheetStatusCode6 where HostCompany = @Company and Code = 'C'
		INSERT  mbbmSheetStatusCode6 (HostCompany, Code, Description, SetDistList, SetUserID, SetMessage, SaveDistList, SaveUserID, SaveMessage, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime) 
		SELECT  @Company, 'C', 'Complete', 0, '', '', 0, '', '', hostname, GETDATE(), hostname, GETDATE()
		FROM    master..sysprocesses WHERE spid = @@SPID

		DELETE  from mbbmSheetStatusCode6 where HostCompany = @Company and Code = 'IP'
		INSERT  mbbmSheetStatusCode6 (HostCompany, Code, Description, SetDistList, SetUserID, SetMessage, SaveDistList, SaveUserID, SaveMessage, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime) 
		SELECT  @Company, 'IP', 'In Process', 0, '', '', 0, '', '', hostname, GETDATE(), hostname, GETDATE()
		FROM    master..sysprocesses WHERE spid = @@SPID

		DELETE  from mbbmSheetStatusCode6 where HostCompany = @Company and Code = 'UR'
		INSERT  mbbmSheetStatusCode6 (HostCompany, Code, Description, SetDistList, SetUserID, SetMessage, SaveDistList, SaveUserID, SaveMessage, CreatedBy, CreatedTime, UpdatedBy, UpdatedTime) 
		SELECT  @Company, 'UR', 'Under Review', 0, '', '', 0, '', '', hostname, GETDATE(), hostname, GETDATE()
		FROM    master..sysprocesses WHERE spid = @@SPID
	END
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspInitializeCompany] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspInitializeCompany] TO [public]
GO
