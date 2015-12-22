CREATE TABLE [dbo].[tdc_cons_ords_arch]
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
ALTER TABLE [dbo].[tdc_cons_ords_arch] ADD CONSTRAINT [PK_tdc_cons_ords_arch_12] PRIMARY KEY CLUSTERED  ([consolidation_no], [order_no], [order_ext], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cons_ords_arch1] ON [dbo].[tdc_cons_ords_arch] ([consolidation_no], [order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cons_ords_arch2] ON [dbo].[tdc_cons_ords_arch] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_cons_ords_arch] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_cons_ords_arch] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_cons_ords_arch] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_cons_ords_arch] TO [public]
GO
