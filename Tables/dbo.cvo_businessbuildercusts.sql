CREATE TABLE [dbo].[cvo_businessbuildercusts]
(
[progyear] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[master_cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[goal1] [decimal] (20, 8) NULL,
[rebatepct1] [decimal] (20, 8) NULL,
[goal2] [decimal] (20, 8) NULL,
[rebatepct2] [decimal] (20, 8) NULL,
[goal3] [decimal] (20, 8) NULL,
[rebatepct3] [decimal] (20, 8) NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_businessbuildercusts] ADD CONSTRAINT [PK__cvo_businessbuil__2634FDFE] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_bbcust_01] ON [dbo].[cvo_businessbuildercusts] ([progyear], [master_cust_code], [cust_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_businessbuildercusts] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_businessbuildercusts] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_businessbuildercusts] TO [public]
GO
