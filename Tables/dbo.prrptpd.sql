CREATE TABLE [dbo].[prrptpd]
(
[detail_type] [smallint] NOT NULL,
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[member_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_sequence_id] [int] NULL,
[source_doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_type] [int] NULL,
[source_apply_date] [int] NULL,
[source_gross_amount] [float] NULL,
[amount_adjusted] [float] NULL,
[void_flag] [int] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_amount] [float] NULL,
[conv_adjusted] [float] NULL,
[conv_rebate_amount] [float] NULL,
[check_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_check_amount] [float] NULL,
[date_entered] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prrptpd] TO [public]
GO
GRANT SELECT ON  [dbo].[prrptpd] TO [public]
GO
GRANT INSERT ON  [dbo].[prrptpd] TO [public]
GO
GRANT DELETE ON  [dbo].[prrptpd] TO [public]
GO
GRANT UPDATE ON  [dbo].[prrptpd] TO [public]
GO
