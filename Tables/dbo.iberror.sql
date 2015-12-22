CREATE TABLE [dbo].[iberror]
(
[id] [uniqueidentifier] NOT NULL,
[error_code] [int] NOT NULL,
[info1] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[info2] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[infoint] [int] NOT NULL,
[infodecimal] [decimal] (20, 8) NOT NULL,
[link1] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[link2] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[link3] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process_ctrl_num] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[iberror] TO [public]
GO
GRANT SELECT ON  [dbo].[iberror] TO [public]
GO
GRANT INSERT ON  [dbo].[iberror] TO [public]
GO
GRANT DELETE ON  [dbo].[iberror] TO [public]
GO
GRANT UPDATE ON  [dbo].[iberror] TO [public]
GO
