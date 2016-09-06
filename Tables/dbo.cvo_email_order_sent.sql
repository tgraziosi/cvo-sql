CREATE TABLE [dbo].[cvo_email_order_sent]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[email_address] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sent_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_email_order_sent] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_email_order_sent] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_email_order_sent] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_email_order_sent] TO [public]
GO
