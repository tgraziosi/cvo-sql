CREATE TABLE [dbo].[tdc_cons_ords]
(
[consolidation_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_no] [int] NULL,
[print_count] [int] NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[alloc_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_cons_ords] ADD CONSTRAINT [PK_tdc_cons_ords2__12] PRIMARY KEY CLUSTERED  ([consolidation_no], [order_no], [order_ext], [location], [order_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cons_ords5] ON [dbo].[tdc_cons_ords] ([consolidation_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cons_ords1] ON [dbo].[tdc_cons_ords] ([consolidation_no], [order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cons_ords3] ON [dbo].[tdc_cons_ords] ([order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cons_ords4] ON [dbo].[tdc_cons_ords] ([order_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cons_ords2] ON [dbo].[tdc_cons_ords] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_cons_ords] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_cons_ords] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_cons_ords] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_cons_ords] TO [public]
GO
