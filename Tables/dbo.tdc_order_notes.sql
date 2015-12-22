CREATE TABLE [dbo].[tdc_order_notes]
(
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_order_notes] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_order_notes] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_order_notes] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_order_notes] TO [public]
GO
