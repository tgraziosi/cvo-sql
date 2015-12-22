CREATE TABLE [dbo].[appydet]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_aging] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[amt_applied] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_flag] [smallint] NOT NULL,
[vo_amt_applied] [float] NOT NULL,
[vo_amt_disc_taken] [float] NOT NULL,
[gain_home] [float] NOT NULL,
[gain_oper] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [appydet_ind_1] ON [dbo].[appydet] ([apply_to_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [appydet_ind_0] ON [dbo].[appydet] ([trx_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[appydet] TO [public]
GO
GRANT SELECT ON  [dbo].[appydet] TO [public]
GO
GRANT INSERT ON  [dbo].[appydet] TO [public]
GO
GRANT DELETE ON  [dbo].[appydet] TO [public]
GO
GRANT UPDATE ON  [dbo].[appydet] TO [public]
GO
