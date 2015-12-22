CREATE TABLE [dbo].[rpt_glrefact]
(
[timestamp] [timestamp] NOT NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_flag] [smallint] NOT NULL,
[reference_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glrefact] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glrefact] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glrefact] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glrefact] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glrefact] TO [public]
GO
