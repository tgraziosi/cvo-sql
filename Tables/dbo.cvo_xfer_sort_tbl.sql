CREATE TABLE [dbo].[cvo_xfer_sort_tbl]
(
[rel_date] [datetime] NULL,
[xfer_no] [int] NULL,
[line_no] [int] NULL,
[from_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upc_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ordered] [decimal] (20, 8) NULL,
[shipped] [decimal] (20, 8) NULL,
[carton_no] [int] NULL,
[pack_qty] [decimal] (24, 8) NULL,
[qty_to_pack] [decimal] (24, 8) NULL,
[sch_ship_date] [datetime] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_scanned] [datetime] NULL,
[qty_scanned] [int] NULL,
[rec_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_xfer_pk] ON [dbo].[cvo_xfer_sort_tbl] ([rec_id]) ON [PRIMARY]
GO
