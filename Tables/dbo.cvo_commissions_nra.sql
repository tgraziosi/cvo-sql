CREATE TABLE [dbo].[cvo_commissions_nra]
(
[terr] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[slp_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[slp_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_commi__slp_c__38F65DA7] DEFAULT (NULL),
[status_type] [tinyint] NOT NULL CONSTRAINT [DF__cvo_commi__statu__3DBB12C4] DEFAULT ('1'),
[stamptime] [datetime] NULL CONSTRAINT [DF__cvo_commi__stamp__2E43C50A] DEFAULT (getdate())
) ON [PRIMARY]
GO
