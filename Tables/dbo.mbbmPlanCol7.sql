CREATE TABLE [dbo].[mbbmPlanCol7]
(
[TimeStamp] [timestamp] NOT NULL,
[RevisionID] [int] NOT NULL,
[Position] [smallint] NOT NULL,
[GroupKey] [dbo].[mbbmudtGroupKey] NOT NULL,
[ColumnKey] [dbo].[mbbmudtColumnKey] NOT NULL,
[Description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FromPeriodType] [tinyint] NOT NULL,
[FromPeriod] [smallint] NOT NULL,
[FromPeriodAct] [smallint] NOT NULL,
[ThruPeriodType] [tinyint] NOT NULL,
[ThruPeriod] [smallint] NOT NULL,
[ThruPeriodAct] [smallint] NOT NULL,
[FromDate] [dbo].[mbbmudtAppDate] NULL,
[ThruDate] [dbo].[mbbmudtAppDate] NULL,
[Valuation] [tinyint] NOT NULL,
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DimValue1] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DimValue2] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DimValue3] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DimValue4] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ColSetKey] [dbo].[mbbmudtGroupKey] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE TRIGGER [dbo].[mbbmPlanCol7_Ins] ON [dbo].[mbbmPlanCol7] FOR INSERT
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
	FROM mbbmPlanCustCol7 p
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
CREATE TRIGGER [dbo].[mbbmPlanCol7_Upd] ON [dbo].[mbbmPlanCol7] FOR UPDATE
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
	FROM mbbmPlanCustCol7 p
	WHERE p.RevisionID = @RevID AND p.ColumnKey = @ColKey 
	
	IF (@Cnt <> 0)
	BEGIN
		SELECT @Msg = 'Column Key ' + @ColKey + ' already exists.'
		RAISERROR 99999 @Msg
		ROLLBACK TRANSACTION

	END
END
GO
ALTER TABLE [dbo].[mbbmPlanCol7] ADD CONSTRAINT [PK_mbbmPlanCol7] PRIMARY KEY CLUSTERED  ([RevisionID], [Position]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanCol7] ADD CONSTRAINT [UK_mbbmPlanCol7] UNIQUE NONCLUSTERED  ([RevisionID], [ColumnKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanCol7] ADD CONSTRAINT [FK_mbbmPlanCol7_RevisionID] FOREIGN KEY ([RevisionID]) REFERENCES [dbo].[mbbmPlanSheetRev74] ([RevisionID])
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanCol7] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanCol7] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanCol7] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanCol7] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanCol7] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanCol7] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanCol7] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanCol7] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanCol7] TO [public]
GO
