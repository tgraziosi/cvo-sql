CREATE TABLE [dbo].[CVO_email_credit_return_raf]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[contact_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attachment] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sent] [smallint] NOT NULL,
[date_sent] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_email_credit_return_raf_inx01] ON [dbo].[CVO_email_credit_return_raf] ([order_no], [ext], [sent]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_email_credit_return_raf_pk] ON [dbo].[CVO_email_credit_return_raf] ([rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_email_credit_return_raf] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_email_credit_return_raf] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_email_credit_return_raf] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_email_credit_return_raf] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_email_credit_return_raf] TO [public]
GO
