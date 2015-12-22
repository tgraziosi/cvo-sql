CREATE TABLE [dbo].[cvo_raf_det_archive]
(
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[display_line] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_raf_det_archive_pk] ON [dbo].[cvo_raf_det_archive] ([order_no], [ext], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_raf_det_archive] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_raf_det_archive] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_raf_det_archive] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_raf_det_archive] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_raf_det_archive] TO [public]
GO
