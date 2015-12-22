CREATE TABLE [dbo].[tdc_graphical_bin_store]
(
[template_id] [int] NOT NULL,
[row] [int] NOT NULL,
[col] [int] NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_graphical_bin_store_idx] ON [dbo].[tdc_graphical_bin_store] ([template_id], [row], [col]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_graphical_bin_store] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_graphical_bin_store] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_graphical_bin_store] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_graphical_bin_store] TO [public]
GO
