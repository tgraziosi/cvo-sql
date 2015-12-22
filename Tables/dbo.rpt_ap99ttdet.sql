CREATE TABLE [dbo].[rpt_ap99ttdet]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[year] [smallint] NULL,
[amount] [float] NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_id] [smallint] NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_amt] [float] NULL,
[vendor_flag] [smallint] NULL,
[remito_flag] [smallint] NULL,
[flag_1099] [smallint] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ap99ttdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ap99ttdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ap99ttdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ap99ttdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ap99ttdet] TO [public]
GO
