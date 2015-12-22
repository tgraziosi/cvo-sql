CREATE TABLE [dbo].[rpt_apapr]
(
[timestamp] [timestamp] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_flag] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[groupby] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [rpt_apapr_idx_0] ON [dbo].[rpt_apapr] ([approval_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apapr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apapr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apapr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apapr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apapr] TO [public]
GO
