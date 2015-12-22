CREATE TABLE [dbo].[tdc_arch_order]
(
[Order_no] [int] NOT NULL,
[Order_ext] [int] NOT NULL,
[status] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[date_shipped] [datetime] NULL,
[date_archived] [datetime] NULL,
[who_archived] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_arch_order] ADD CONSTRAINT [pk_tdc_arch_order] PRIMARY KEY NONCLUSTERED  ([Order_no], [Order_ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_arch_order] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_arch_order] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_arch_order] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_arch_order] TO [public]
GO
