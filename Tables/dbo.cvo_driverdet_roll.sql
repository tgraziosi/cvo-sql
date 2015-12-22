CREATE TABLE [dbo].[cvo_driverdet_roll]
(
[row] [int] NOT NULL IDENTITY(1, 1),
[A] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[B] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[C] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[E] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_driverdet_roll] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_driverdet_roll] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_driverdet_roll] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_driverdet_roll] TO [public]
GO
