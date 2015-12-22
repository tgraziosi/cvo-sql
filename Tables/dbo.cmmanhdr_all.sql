CREATE TABLE [dbo].[cmmanhdr_all]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[date_applied] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[total] [float] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[interbranch_flag] [int] NULL,
[temp_flag] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmmanhdr_all_ind_0] ON [dbo].[cmmanhdr_all] ([trx_ctrl_num], [trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmmanhdr_all] TO [public]
GO
GRANT SELECT ON  [dbo].[cmmanhdr_all] TO [public]
GO
GRANT INSERT ON  [dbo].[cmmanhdr_all] TO [public]
GO
GRANT DELETE ON  [dbo].[cmmanhdr_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmmanhdr_all] TO [public]
GO
