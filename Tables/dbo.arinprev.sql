CREATE TABLE [dbo].[arinprev]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[rev_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_amt] [float] NOT NULL,
[trx_type] [smallint] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [arinprev_ind_0] ON [dbo].[arinprev] ([trx_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arinprev] TO [public]
GO
GRANT SELECT ON  [dbo].[arinprev] TO [public]
GO
GRANT INSERT ON  [dbo].[arinprev] TO [public]
GO
GRANT DELETE ON  [dbo].[arinprev] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinprev] TO [public]
GO
