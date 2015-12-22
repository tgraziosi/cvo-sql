CREATE TABLE [dbo].[apaprtrx]
(
[timestamp] [timestamp] NOT NULL,
[user_id] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[amount] [float] NOT NULL,
[approved_flag] [smallint] NOT NULL,
[disappr_flag] [smallint] NOT NULL,
[display_flag] [smallint] NOT NULL,
[disable_flag] [smallint] NOT NULL,
[date_approved] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[date_assigned] [int] NOT NULL,
[appr_user_id] [smallint] NOT NULL,
[disappr_user_id] [smallint] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_flag] [smallint] NOT NULL,
[appr_seq_id] [int] NOT NULL,
[appr_complete] [smallint] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[changed_flag] [smallint] NOT NULL,
[origin_flag] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apaprtrx_ind_0] ON [dbo].[apaprtrx] ([user_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [apaprtrx_ind_1] ON [dbo].[apaprtrx] ([user_id], [trx_ctrl_num], [trx_type], [approval_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apaprtrx] TO [public]
GO
GRANT SELECT ON  [dbo].[apaprtrx] TO [public]
GO
GRANT INSERT ON  [dbo].[apaprtrx] TO [public]
GO
GRANT DELETE ON  [dbo].[apaprtrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[apaprtrx] TO [public]
GO
