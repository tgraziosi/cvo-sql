SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[mbbmvwJournalType]
WITH ENCRYPTION
AS
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/
SELECT  HostCompany	= company_code,
	JournalType	= journal_type,
	Description	= type_description
FROM	gljtype, glco
GO
GRANT REFERENCES ON  [dbo].[mbbmvwJournalType] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwJournalType] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmvwJournalType] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmvwJournalType] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmvwJournalType] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwJournalType] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmvwJournalType] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmvwJournalType] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmvwJournalType] TO [public]
GO
