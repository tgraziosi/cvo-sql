CREATE TABLE [dbo].[rpt_arucashrcb]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[chargeref] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[chargeamt] [float] NULL CONSTRAINT [DF__rpt_aruca__charg__24F0FFD7] DEFAULT ((0.0)),
[cb_reason_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_responsibility_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_memo] [smallint] NULL CONSTRAINT [DF__rpt_aruca__credi__25E52410] DEFAULT ((0)),
[cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arucashrcb] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arucashrcb] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arucashrcb] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arucashrcb] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arucashrcb] TO [public]
GO
