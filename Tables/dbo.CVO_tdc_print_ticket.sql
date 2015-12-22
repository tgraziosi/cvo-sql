CREATE TABLE [dbo].[CVO_tdc_print_ticket]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[print_value] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_id] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_print_102015] ON [dbo].[CVO_tdc_print_ticket] ([process_id]) INCLUDE ([print_value], [row_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [pt_idx1] ON [dbo].[CVO_tdc_print_ticket] ([row_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_tdc_print_ticket] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_tdc_print_ticket] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_tdc_print_ticket] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_tdc_print_ticket] TO [public]
GO
