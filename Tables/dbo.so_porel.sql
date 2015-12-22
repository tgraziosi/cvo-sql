CREATE TABLE [dbo].[so_porel]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_relation] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [so_porel_idx] ON [dbo].[so_porel] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[so_porel] TO [public]
GO
GRANT SELECT ON  [dbo].[so_porel] TO [public]
GO
GRANT INSERT ON  [dbo].[so_porel] TO [public]
GO
GRANT DELETE ON  [dbo].[so_porel] TO [public]
GO
GRANT UPDATE ON  [dbo].[so_porel] TO [public]
GO
