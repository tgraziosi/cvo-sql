CREATE TABLE [dbo].[arcbtrx]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[trx_type] [smallint] NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_trx_type] [smallint] NULL,
[chargeback] [smallint] NULL CONSTRAINT [DF__arcbtrx__chargeb__20222919] DEFAULT ((0)),
[chargeref] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arcbtrx__charger__21164D52] DEFAULT (''),
[cb_store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arcbtrx__cb_stor__220A718B] DEFAULT (''),
[cb_reason_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arcbtrx__cb_reas__22FE95C4] DEFAULT (''),
[cb_responsibility_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arcbtrx__cb_resp__23F2B9FD] DEFAULT (''),
[cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arcbtrx__cb_reas__24E6DE36] DEFAULT (''),
[chargeamt] [float] NULL CONSTRAINT [DF__arcbtrx__chargea__25DB026F] DEFAULT ((0.0))
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcbtrx] TO [public]
GO
GRANT SELECT ON  [dbo].[arcbtrx] TO [public]
GO
GRANT INSERT ON  [dbo].[arcbtrx] TO [public]
GO
GRANT DELETE ON  [dbo].[arcbtrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcbtrx] TO [public]
GO
