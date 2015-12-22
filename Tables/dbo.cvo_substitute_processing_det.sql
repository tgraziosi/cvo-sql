CREATE TABLE [dbo].[cvo_substitute_processing_det]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[spid] [int] NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[order_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[so_priority] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type_sort] [smallint] NOT NULL,
[priority_sort] [smallint] NOT NULL,
[backorder_sort] [smallint] NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_date] [datetime] NULL,
[customer_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_substitute_processing_det_pk] ON [dbo].[cvo_substitute_processing_det] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_substitute_processing_det_inx01] ON [dbo].[cvo_substitute_processing_det] ([spid]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_substitute_processing_det] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_substitute_processing_det] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_substitute_processing_det] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_substitute_processing_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_substitute_processing_det] TO [public]
GO
