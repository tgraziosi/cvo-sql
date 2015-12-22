CREATE TABLE [dbo].[cmtrx_all]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[gl_trx_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_posted] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmtrx_all_ind_0] ON [dbo].[cmtrx_all] ([trx_ctrl_num], [trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmtrx_all] TO [public]
GO
GRANT SELECT ON  [dbo].[cmtrx_all] TO [public]
GO
GRANT INSERT ON  [dbo].[cmtrx_all] TO [public]
GO
GRANT DELETE ON  [dbo].[cmtrx_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmtrx_all] TO [public]
GO
