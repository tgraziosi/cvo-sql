CREATE TABLE [dbo].[po_usrcateg]
(
[timestamp] [timestamp] NOT NULL,
[category_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category_desc] [varchar] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [po_usrcateg_idx] ON [dbo].[po_usrcateg] ([category_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[po_usrcateg] TO [public]
GO
GRANT SELECT ON  [dbo].[po_usrcateg] TO [public]
GO
GRANT INSERT ON  [dbo].[po_usrcateg] TO [public]
GO
GRANT DELETE ON  [dbo].[po_usrcateg] TO [public]
GO
GRANT UPDATE ON  [dbo].[po_usrcateg] TO [public]
GO
