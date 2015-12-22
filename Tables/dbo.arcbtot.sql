CREATE TABLE [dbo].[arcbtot]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[total_chargebacks] [float] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arcbtot_ind_0] ON [dbo].[arcbtot] ([trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcbtot] TO [public]
GO
GRANT SELECT ON  [dbo].[arcbtot] TO [public]
GO
GRANT INSERT ON  [dbo].[arcbtot] TO [public]
GO
GRANT DELETE ON  [dbo].[arcbtot] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcbtot] TO [public]
GO
