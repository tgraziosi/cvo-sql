CREATE TABLE [dbo].[artrxcom]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_commission] [float] NOT NULL,
[percent_flag] [smallint] NOT NULL,
[exclusive_flag] [smallint] NOT NULL,
[split_flag] [smallint] NOT NULL,
[commission_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxcom_ind_1] ON [dbo].[artrxcom] ([salesperson_code]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [artrxcom_ind_0] ON [dbo].[artrxcom] ([trx_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artrxcom] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxcom] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxcom] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxcom] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxcom] TO [public]
GO
