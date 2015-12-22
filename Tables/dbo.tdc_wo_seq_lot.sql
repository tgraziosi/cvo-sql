CREATE TABLE [dbo].[tdc_wo_seq_lot]
(
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL,
[last_seq_lot] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wo_seq_lot] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wo_seq_lot] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wo_seq_lot] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wo_seq_lot] TO [public]
GO
