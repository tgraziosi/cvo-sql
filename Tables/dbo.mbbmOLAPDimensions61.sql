CREATE TABLE [dbo].[mbbmOLAPDimensions61]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[Name] [dbo].[mbbmudtOLAPDimName] NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AllLevel] [dbo].[mbbmudtYesNo] NOT NULL,
[AllCaption] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OLAPDimType] [dbo].[mbbmudtOLAPDimType] NOT NULL,
[AggregationUsage] [dbo].[mbbmudtOLAPDimAgg] NOT NULL,
[PeriodType] [dbo].[mbbmudtOLAPPeriodType] NOT NULL,
[FiscalStartDay] [dbo].[mbbmudtDayOfMonth] NOT NULL,
[FiscalStartMonth] [dbo].[mbbmudtMonthNum] NOT NULL,
[FreezeLevelNaming] [smallint] NOT NULL,
[CreatedBy] [dbo].[mbbmudtUser] NOT NULL,
[CreatedTime] [dbo].[mbbmudtTagDate] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOLAPDimensions61_Ins] ON [dbo].[mbbmOLAPDimensions61] FOR INSERT 
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
	UPDATE	mbbmOLAPDimensions61
	SET	mbbmOLAPDimensions61.CreatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPDimensions61.CreatedTime		= GETDATE(),
		mbbmOLAPDimensions61.UpdatedBy		= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPDimensions61.UpdatedTime		= GETDATE()
	FROM	mbbmOLAPDimensions61, inserted 
	WHERE	mbbmOLAPDimensions61.HostCompany 		= inserted.HostCompany 
		AND mbbmOLAPDimensions61.Name		= inserted.Name 
		AND mbbmOLAPDimensions61.CreatedBy	= ''
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmOLAPDimensions61_Upd] ON [dbo].[mbbmOLAPDimensions61] FOR UPDATE 
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
	IF (Update(UpdatedBy) OR Update(UpdatedTime)) RETURN --DS 11/28/2009 for recursive triggers on problem per Andy

	UPDATE  mbbmOLAPDimensions61
	SET     mbbmOLAPDimensions61.UpdatedBy	= (SELECT hostname FROM master..sysprocesses WHERE spid = @@SPID),
		mbbmOLAPDimensions61.UpdatedTime	= GETDATE()
	FROM    mbbmOLAPDimensions61, inserted 
	WHERE   mbbmOLAPDimensions61.HostCompany 	= inserted.HostCompany
		AND mbbmOLAPDimensions61.Name	= inserted.Name
END
GO
ALTER TABLE [dbo].[mbbmOLAPDimensions61] ADD CONSTRAINT [PK_mbbmOLAPDimensions61] PRIMARY KEY CLUSTERED  ([HostCompany], [Name]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmOLAPDimensions61].[AllLevel]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimensions61].[AllLevel]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPDimType]', N'[dbo].[mbbmOLAPDimensions61].[OLAPDimType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimensions61].[OLAPDimType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPDimAgg]', N'[dbo].[mbbmOLAPDimensions61].[AggregationUsage]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimensions61].[AggregationUsage]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPPeriodType]', N'[dbo].[mbbmOLAPDimensions61].[PeriodType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmOLAPDimensions61].[PeriodType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulDayOfMonth]', N'[dbo].[mbbmOLAPDimensions61].[FiscalStartDay]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulMonthNum]', N'[dbo].[mbbmOLAPDimensions61].[FiscalStartMonth]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPDimensions61].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPDimensions61].[CreatedTime]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmOLAPDimensions61].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmOLAPDimensions61].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmOLAPDimensions61] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPDimensions61] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPDimensions61] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPDimensions61] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPDimensions61] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmOLAPDimensions61] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmOLAPDimensions61] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmOLAPDimensions61] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmOLAPDimensions61] TO [public]
GO
