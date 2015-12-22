CREATE TABLE [dbo].[tdc_next_batch_no]
(
[prefix] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[issue_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_seq_no] [int] NOT NULL,
[batch_no] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_next_batch_no] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_next_batch_no] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_next_batch_no] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_next_batch_no] TO [public]
GO
