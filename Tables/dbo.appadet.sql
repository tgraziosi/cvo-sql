CREATE TABLE [dbo].[appadet]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[void_flag] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [appadet_ind_0] ON [dbo].[appadet] ([trx_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[appadet] TO [public]
GO
GRANT SELECT ON  [dbo].[appadet] TO [public]
GO
GRANT INSERT ON  [dbo].[appadet] TO [public]
GO
GRANT DELETE ON  [dbo].[appadet] TO [public]
GO
GRANT UPDATE ON  [dbo].[appadet] TO [public]
GO
