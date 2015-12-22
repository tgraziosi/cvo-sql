CREATE TABLE [dbo].[tdc_transaction_type]
(
[tran_type] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_transaction_type] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_transaction_type] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_transaction_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_transaction_type] TO [public]
GO
