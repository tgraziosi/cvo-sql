CREATE TABLE [dbo].[rpt_glcocon]
(
[parent_comp_id] [smallint] NOT NULL,
[sub_comp_id] [smallint] NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_db_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[init_period] [int] NOT NULL,
[next_period] [int] NOT NULL,
[gain_loss_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_type] [smallint] NOT NULL,
[owner_percent] [float] NOT NULL,
[rate_mode] [smallint] NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent_comp_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_comp_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code_mask] [varchar] (41) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[consol_account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glcocon] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glcocon] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glcocon] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glcocon] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glcocon] TO [public]
GO
