CREATE TABLE [dbo].[cvo_territory_goal]
(
[mmonth] [int] NOT NULL,
[yyear] [int] NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[goal_amt] [float] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_territory_goal] ADD CONSTRAINT [PK_cvo_territory_goal] PRIMARY KEY CLUSTERED  ([mmonth], [yyear], [territory_code], [goal_amt]) ON [PRIMARY]
GO
