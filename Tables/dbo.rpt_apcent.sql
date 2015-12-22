CREATE TABLE [dbo].[rpt_apcent]
(
[timestamp] [timestamp] NOT NULL,
[cents_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cents_code_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[groupby] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [rpt_apcent_idx_0] ON [dbo].[rpt_apcent] ([cents_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apcent] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apcent] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apcent] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apcent] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apcent] TO [public]
GO
