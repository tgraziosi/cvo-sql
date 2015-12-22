CREATE TABLE [dbo].[cvo_raf_det]
(
[spid] [int] NOT NULL,
[display_line] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[upc_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_raf_det_inx01] ON [dbo].[cvo_raf_det] ([spid]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_raf_det_pk] ON [dbo].[cvo_raf_det] ([spid], [display_line]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_raf_det] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_raf_det] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_raf_det] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_raf_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_raf_det] TO [public]
GO
