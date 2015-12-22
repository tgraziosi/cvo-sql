CREATE TABLE [dbo].[amapnew]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[amapnew] TO [public]
GO
GRANT SELECT ON  [dbo].[amapnew] TO [public]
GO
GRANT INSERT ON  [dbo].[amapnew] TO [public]
GO
GRANT DELETE ON  [dbo].[amapnew] TO [public]
GO
GRANT UPDATE ON  [dbo].[amapnew] TO [public]
GO
