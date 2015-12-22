CREATE TABLE [dbo].[arcdtext]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[serial_id] [int] NOT NULL,
[ord_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[iv_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[iv_trx_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arcdtext_ind_0] ON [dbo].[arcdtext] ([trx_ctrl_num], [trx_type], [serial_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcdtext] TO [public]
GO
GRANT SELECT ON  [dbo].[arcdtext] TO [public]
GO
GRANT INSERT ON  [dbo].[arcdtext] TO [public]
GO
GRANT DELETE ON  [dbo].[arcdtext] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcdtext] TO [public]
GO
