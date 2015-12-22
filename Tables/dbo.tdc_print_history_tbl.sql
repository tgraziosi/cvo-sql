CREATE TABLE [dbo].[tdc_print_history_tbl]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[print_date] [datetime] NULL,
[printed_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_ticket_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_print_history_tbl_ix01] ON [dbo].[tdc_print_history_tbl] ([order_no], [order_ext], [location], [pick_ticket_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_print_history_tbl_ix02] ON [dbo].[tdc_print_history_tbl] ([print_date], [printed_by]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_print_history_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_print_history_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_print_history_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_print_history_tbl] TO [public]
GO
