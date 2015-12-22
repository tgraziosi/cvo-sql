CREATE TABLE [dbo].[artrxrev]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [smallint] NOT NULL,
[rev_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_amt] [float] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [artrxrev_ind_0] ON [dbo].[artrxrev] ([trx_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artrxrev] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxrev] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxrev] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxrev] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxrev] TO [public]
GO
