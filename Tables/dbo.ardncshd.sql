CREATE TABLE [dbo].[ardncshd]
(
[timestamp] [timestamp] NULL,
[dunn_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_generate] [int] NULL,
[lower_sep_day] [int] NULL,
[upper_sep_day] [int] NULL,
[amt_extra] [float] NULL,
[amt_due] [float] NOT NULL,
[amt_paid] [float] NOT NULL,
[amt_extra_projected] [float] NULL,
[chk_hold] [smallint] NULL,
[void_fin_chg] [smallint] NULL,
[print_fin_only] [smallint] NULL,
[printed_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ardncshd_0] ON [dbo].[ardncshd] ([dunn_ctrl_num], [customer_code], [nat_cur_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ardncshd] TO [public]
GO
GRANT SELECT ON  [dbo].[ardncshd] TO [public]
GO
GRANT INSERT ON  [dbo].[ardncshd] TO [public]
GO
GRANT DELETE ON  [dbo].[ardncshd] TO [public]
GO
GRANT UPDATE ON  [dbo].[ardncshd] TO [public]
GO
