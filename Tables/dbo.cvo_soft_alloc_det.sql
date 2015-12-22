CREATE TABLE [dbo].[cvo_soft_alloc_det]
(
[soft_alloc_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [decimal] (20, 8) NULL,
[kit_part] [smallint] NOT NULL,
[change] [smallint] NOT NULL,
[deleted] [smallint] NOT NULL,
[is_case] [smallint] NOT NULL,
[is_pattern] [smallint] NOT NULL,
[is_pop_gift] [smallint] NOT NULL,
[status] [smallint] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[add_case_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[case_adjust] [decimal] (20, 8) NULL CONSTRAINT [DF__cvo_soft___case___7EE55B5C] DEFAULT ((0)),
[inv_avail] [smallint] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_det_ind3_041913] ON [dbo].[cvo_soft_alloc_det] ([location], [part_no], [soft_alloc_no], [status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_det_ind6_101613] ON [dbo].[cvo_soft_alloc_det] ([location], [part_no], [soft_alloc_no], [status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_det_ind5_043013] ON [dbo].[cvo_soft_alloc_det] ([location], [part_no], [soft_alloc_no], [status]) INCLUDE ([deleted], [quantity]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_det_ind1] ON [dbo].[cvo_soft_alloc_det] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_det_ind4_042313] ON [dbo].[cvo_soft_alloc_det] ([order_no], [order_ext], [status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_det_ind2] ON [dbo].[cvo_soft_alloc_det] ([row_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_det_ind0] ON [dbo].[cvo_soft_alloc_det] ([soft_alloc_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_soft_alloc_det] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_soft_alloc_det] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_soft_alloc_det] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_soft_alloc_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_soft_alloc_det] TO [public]
GO
