CREATE TABLE [dbo].[cvo_auto_receive_credit_return]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[processed] [smallint] NOT NULL,
[processed_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_auto_receive_credit_return_inx01] ON [dbo].[cvo_auto_receive_credit_return] ([order_no], [ext], [processed]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_auto_receive_credit_return_inx02] ON [dbo].[cvo_auto_receive_credit_return] ([processed]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_auto_receive_credit_return_pk] ON [dbo].[cvo_auto_receive_credit_return] ([rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_auto_receive_credit_return] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_auto_receive_credit_return] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_auto_receive_credit_return] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_auto_receive_credit_return] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_auto_receive_credit_return] TO [public]
GO
