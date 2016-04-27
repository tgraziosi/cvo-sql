CREATE TABLE [dbo].[epicor_debug_cvo_soft_alloc_hdr]
(
[soft_alloc_no] [int] NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[tran_date] [datetime] NULL,
[new_status] [int] NULL,
[old_status] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epicor_debug_cvo_soft_alloc_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[epicor_debug_cvo_soft_alloc_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[epicor_debug_cvo_soft_alloc_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[epicor_debug_cvo_soft_alloc_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[epicor_debug_cvo_soft_alloc_hdr] TO [public]
GO
