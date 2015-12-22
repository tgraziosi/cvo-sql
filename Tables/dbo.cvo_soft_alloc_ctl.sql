CREATE TABLE [dbo].[cvo_soft_alloc_ctl]
(
[soft_alloc_no] [int] NOT NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[date_entered] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_ctl_ind0] ON [dbo].[cvo_soft_alloc_ctl] ([soft_alloc_no], [date_entered]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_soft_alloc_ctl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_soft_alloc_ctl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_soft_alloc_ctl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_soft_alloc_ctl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_soft_alloc_ctl] TO [public]
GO
