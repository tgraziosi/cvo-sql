CREATE TABLE [dbo].[nbtrxcre]
(
[timestamp] [timestamp] NOT NULL,
[net_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[amt_net] [float] NOT NULL,
[amt_payment] [float] NOT NULL,
[amt_committed] [float] NOT NULL,
[date_applied] [int] NOT NULL,
[date_posted] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [nbtrxcre_ind_0] ON [dbo].[nbtrxcre] ([net_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[nbtrxcre] TO [public]
GO
GRANT SELECT ON  [dbo].[nbtrxcre] TO [public]
GO
GRANT INSERT ON  [dbo].[nbtrxcre] TO [public]
GO
GRANT DELETE ON  [dbo].[nbtrxcre] TO [public]
GO
GRANT UPDATE ON  [dbo].[nbtrxcre] TO [public]
GO
