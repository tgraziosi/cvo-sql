CREATE TABLE [dbo].[cvo_soft_alloc_hdr_posted]
(
[soft_alloc_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bo_hold] [int] NOT NULL,
[status] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_hdr_posted_ind0] ON [dbo].[cvo_soft_alloc_hdr_posted] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_soft_alloc_hdr_posted] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_soft_alloc_hdr_posted] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_soft_alloc_hdr_posted] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_soft_alloc_hdr_posted] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_soft_alloc_hdr_posted] TO [public]
GO
