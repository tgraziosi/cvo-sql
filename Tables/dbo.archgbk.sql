CREATE TABLE [dbo].[archgbk]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[chargeref] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[chargeamt] [float] NULL CONSTRAINT [DF__archgbk__chargea__16A2E080] DEFAULT ((0.0)),
[cb_reason_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_responsibility_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_memo] [smallint] NULL CONSTRAINT [DF__archgbk__credit___179704B9] DEFAULT ((0)),
[cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [archgbk_ind_0] ON [dbo].[archgbk] ([trx_ctrl_num]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [archgbk_ind_1] ON [dbo].[archgbk] ([trx_ctrl_num], [chargeref]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[archgbk] TO [public]
GO
GRANT SELECT ON  [dbo].[archgbk] TO [public]
GO
GRANT INSERT ON  [dbo].[archgbk] TO [public]
GO
GRANT DELETE ON  [dbo].[archgbk] TO [public]
GO
GRANT UPDATE ON  [dbo].[archgbk] TO [public]
GO
