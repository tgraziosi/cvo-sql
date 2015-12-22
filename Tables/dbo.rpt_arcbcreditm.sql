CREATE TABLE [dbo].[rpt_arcbcreditm]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [smallint] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_responsibility_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prompt1_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_net] [float] NULL,
[chargeref] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcbcreditm] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcbcreditm] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcbcreditm] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcbcreditm] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcbcreditm] TO [public]
GO
