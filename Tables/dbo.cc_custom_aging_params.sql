CREATE TABLE [dbo].[cc_custom_aging_params]
(
[from_cust] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thru_cust] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_terr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thru_terr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_type_parm] [smallint] NULL,
[balance_over] [smallint] NULL,
[from_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thru_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[exclude_on_accts] [smallint] NULL,
[all_cust_flag] [smallint] NULL,
[all_terr_flag] [smallint] NULL,
[all_name_flag] [smallint] NULL,
[balance_over_amt] [decimal] (28, 2) NULL,
[sequence] [smallint] NULL,
[str_date_asof] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bal_over_flag] [smallint] NULL,
[days_over_flag] [smallint] NULL,
[bal_over_operand] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[days_over_operand] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[days_over_num] [smallint] NULL,
[meet_cond] [smallint] NULL,
[all_post_flag] [smallint] NULL,
[from_post] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thru_post] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[all_workload_flag] [smallint] NULL,
[from_workload] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thru_workload] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[include_comments] [smallint] NULL,
[inc_future] [smallint] NULL,
[terr_from_cust] [smallint] NULL,
[print_all_comments] [smallint] NULL,
[currency_basis] [smallint] NULL,
[agebrk_user_id] [int] NULL,
[all_org_flag] [smallint] NULL,
[from_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thru_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_custom_aging_params] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_custom_aging_params] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_custom_aging_params] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_custom_aging_params] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_custom_aging_params] TO [public]
GO
