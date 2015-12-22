CREATE TABLE [dbo].[arcbinv]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[chargeref] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_reason_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_status_code] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_cb_reason_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_cb_status_code] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_responsibility_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_cb_resp_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arcbinv_ind_0] ON [dbo].[arcbinv] ([trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcbinv] TO [public]
GO
GRANT SELECT ON  [dbo].[arcbinv] TO [public]
GO
GRANT INSERT ON  [dbo].[arcbinv] TO [public]
GO
GRANT DELETE ON  [dbo].[arcbinv] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcbinv] TO [public]
GO
