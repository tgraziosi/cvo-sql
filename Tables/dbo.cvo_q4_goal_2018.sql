CREATE TABLE [dbo].[cvo_q4_goal_2018]
(
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Q4_G1] [decimal] (20, 8) NULL,
[Q4_G2] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_q4_goal_2018] ADD CONSTRAINT [PK__cvo_q4_goal_2018__47E466D3] PRIMARY KEY CLUSTERED  ([territory]) ON [PRIMARY]
GO
