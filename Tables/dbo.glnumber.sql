CREATE TABLE [dbo].[glnumber]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[next_jrnl_ctrl_code] [int] NOT NULL,
[jrnl_ctrl_code_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[jcc_start_col] [smallint] NOT NULL,
[jcc_length] [smallint] NOT NULL,
[next_recurring_code] [int] NOT NULL,
[recurring_code_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rcc_start_col] [smallint] NOT NULL,
[rcc_length] [smallint] NOT NULL,
[next_reallocate_code] [int] NOT NULL,
[reallocate_code_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_tax_ctrl_code] [int] NOT NULL,
[tax_ctrl_code_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_inv_ctrl_code] [int] NOT NULL,
[inv_ctrl_code_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_batch_ctrl_num] [int] NOT NULL,
[batch_ctrl_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_consol_ctrl_num] [int] NOT NULL,
[consol_ctrl_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_ib_code] [int] NOT NULL,
[ib_code_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ib_start_col] [smallint] NOT NULL,
[ib_length] [smallint] NOT NULL,
[next_batch_group_ctrl_num] [int] NOT NULL,
[batch_group_ctrl_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glnumber_ind_0] ON [dbo].[glnumber] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glnumber] TO [public]
GO
GRANT SELECT ON  [dbo].[glnumber] TO [public]
GO
GRANT INSERT ON  [dbo].[glnumber] TO [public]
GO
GRANT DELETE ON  [dbo].[glnumber] TO [public]
GO
GRANT UPDATE ON  [dbo].[glnumber] TO [public]
GO
