CREATE TABLE [dbo].[cvo_order_queue_cancellation]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[tran_id] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_order_queue_cancellation_ind0] ON [dbo].[cvo_order_queue_cancellation] ([tran_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_order_queue_cancellation] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_order_queue_cancellation] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_order_queue_cancellation] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_order_queue_cancellation] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_order_queue_cancellation] TO [public]
GO
