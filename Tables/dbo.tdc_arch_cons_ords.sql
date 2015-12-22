CREATE TABLE [dbo].[tdc_arch_cons_ords]
(
[consolidation_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_no] [int] NULL,
[print_count] [int] NULL,
[date_archived] [datetime] NULL,
[who_archived] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_arch_cons_ords] ADD CONSTRAINT [PK_tdc_arch_cons_ords2] PRIMARY KEY CLUSTERED  ([consolidation_no], [order_no], [order_ext], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_arch_cons_ords1] ON [dbo].[tdc_arch_cons_ords] ([consolidation_no], [order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_arch_cons_ords2] ON [dbo].[tdc_arch_cons_ords] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_arch_cons_ords] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_arch_cons_ords] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_arch_cons_ords] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_arch_cons_ords] TO [public]
GO
