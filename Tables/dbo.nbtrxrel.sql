CREATE TABLE [dbo].[nbtrxrel]
(
[timestamp] [timestamp] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[net_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [nbtrxrel_ind_0] ON [dbo].[nbtrxrel] ([process_ctrl_num], [net_ctrl_num], [trx_ctrl_num], [trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[nbtrxrel] TO [public]
GO
GRANT SELECT ON  [dbo].[nbtrxrel] TO [public]
GO
GRANT INSERT ON  [dbo].[nbtrxrel] TO [public]
GO
GRANT DELETE ON  [dbo].[nbtrxrel] TO [public]
GO
GRANT UPDATE ON  [dbo].[nbtrxrel] TO [public]
GO
