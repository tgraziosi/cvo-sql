CREATE TABLE [dbo].[cvo_email_ship_confirmation]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [int] NULL,
[order_ext] [int] NULL,
[email_address] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_created] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_sent] [int] NULL,
[sent_date] [datetime] NULL,
[invoice_no] [int] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[etype] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_email_ship_confirmation_ind_0] ON [dbo].[cvo_email_ship_confirmation] ([row_id], [order_no], [order_ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_email_ship_confirmation] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_email_ship_confirmation] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_email_ship_confirmation] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_email_ship_confirmation] TO [public]
GO
