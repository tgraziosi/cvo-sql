CREATE TABLE [dbo].[cvo_designation_rebates_old]
(
[progyear] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[interval] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[goal1] [decimal] (20, 8) NULL,
[rebatepct1] [decimal] (20, 8) NULL,
[goal2] [decimal] (20, 8) NULL,
[rebatepct2] [decimal] (20, 8) NULL,
[goal3] [decimal] (20, 8) NULL,
[rebatepct3] [decimal] (20, 8) NULL,
[PrimaryOnly] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CurrentlyOnly] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RRLess] [decimal] (20, 8) NULL,
[COOPOvr] [decimal] (20, 8) NULL,
[date_entered] [datetime] NULL,
[who_entered] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_designation_rebates_old] ADD CONSTRAINT [PK__cvo_designation___28FEBE15] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO