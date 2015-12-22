CREATE TABLE [dbo].[cvo_tdc_log_written]
(
[spid] [int] NULL,
[order_no] [int] NULL,
[ext] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_tdc_log_written] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_tdc_log_written] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_tdc_log_written] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_tdc_log_written] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_tdc_log_written] TO [public]
GO
