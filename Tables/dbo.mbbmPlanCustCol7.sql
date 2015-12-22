CREATE TABLE [dbo].[mbbmPlanCustCol7]
(
[TimeStamp] [timestamp] NOT NULL,
[RevisionID] [int] NOT NULL,
[Position] [smallint] NOT NULL,
[ColumnKey] [dbo].[mbbmudtColumnKey] NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DimCode] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DimAttrName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DataType] [smallint] NOT NULL,
[TextFormat] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TypeDateSeparator] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TypeDateCentury] [tinyint] NOT NULL,
[ColSetKey] [dbo].[mbbmudtGroupKey] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlanCustCol7_Ins] ON [dbo].[mbbmPlanCustCol7] FOR INSERT
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
	/* Get the range of level for this job type from the jobs table. */
	DECLARE 	@Cnt tinyint,
			@Msg varchar(50),
			@ColKey varchar(16),
			@RevID int
	
	SELECT 	@ColKey = i.ColumnKey, 
			@RevID = i.RevisionID
	FROM inserted i
	
	SELECT @Cnt = COUNT(*)
	FROM mbbmPlanCol7 p
	WHERE p.RevisionID = @RevID AND p.ColumnKey = @ColKey 
	
	IF (@Cnt <> 0)
	BEGIN
		SELECT @Msg = 'Column Key ' + @ColKey + ' already exists.'
		RAISERROR 99999 @Msg
		ROLLBACK TRANSACTION

	END
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlanCustCol7_Upd] ON [dbo].[mbbmPlanCustCol7] FOR UPDATE
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
	/* Get the range of level for this job type from the jobs table. */
	DECLARE 	@Cnt tinyint,
			@Msg varchar(50),
			@ColKey varchar(16),
			@RevID int
	
	SELECT 	@ColKey = i.ColumnKey, 
			@RevID = i.RevisionID
	FROM inserted i
	
	SELECT @Cnt = COUNT(*)
	FROM mbbmPlanCol7 p
	WHERE p.RevisionID = @RevID AND p.ColumnKey = @ColKey 
	
	IF (@Cnt <> 0)
	BEGIN
		SELECT @Msg = 'Column Key ' + @ColKey + ' already exists.'
		RAISERROR 99999 @Msg
		ROLLBACK TRANSACTION

	END
END
GO
ALTER TABLE [dbo].[mbbmPlanCustCol7] ADD CONSTRAINT [PK_mbbmPlanCustCol7] PRIMARY KEY CLUSTERED  ([RevisionID], [Position]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanCustCol7] ADD CONSTRAINT [UK_mbbmPlanCustCol7] UNIQUE NONCLUSTERED  ([RevisionID], [ColumnKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanCustCol7] ADD CONSTRAINT [FK_mbbmPlanCustCol7_RevisionID] FOREIGN KEY ([RevisionID]) REFERENCES [dbo].[mbbmPlanSheetRev74] ([RevisionID])
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanCustCol7] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanCustCol7] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanCustCol7] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanCustCol7] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanCustCol7] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanCustCol7] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanCustCol7] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanCustCol7] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanCustCol7] TO [public]
GO
