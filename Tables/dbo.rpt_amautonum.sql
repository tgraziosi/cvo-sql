CREATE TABLE [dbo].[rpt_amautonum]
(
[auto_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[automatic_next] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amautonum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amautonum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amautonum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amautonum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amautonum] TO [public]
GO
