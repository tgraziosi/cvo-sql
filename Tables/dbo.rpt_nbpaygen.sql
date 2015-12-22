CREATE TABLE [dbo].[rpt_nbpaygen]
(
[net_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_nbpaygen] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_nbpaygen] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_nbpaygen] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_nbpaygen] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_nbpaygen] TO [public]
GO
