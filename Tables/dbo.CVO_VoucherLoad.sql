CREATE TABLE [dbo].[CVO_VoucherLoad]
(
[row] [int] NOT NULL IDENTITY(1, 1),
[vendor] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_type] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[due_date] [datetime] NULL,
[balance] [float] NULL,
[current] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x] [float] NULL,
[VType] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CDATE] [datetime] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_VoucherLoad] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_VoucherLoad] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_VoucherLoad] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_VoucherLoad] TO [public]
GO
