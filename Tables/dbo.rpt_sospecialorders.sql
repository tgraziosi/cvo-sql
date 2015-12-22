CREATE TABLE [dbo].[rpt_sospecialorders]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[ord_line] [int] NOT NULL,
[ord_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ord_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[complete_perc] [decimal] (20, 8) NOT NULL,
[ord_complete_perc] [decimal] (20, 8) NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[ord_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sch_ship_date] [datetime] NULL,
[date_shipped] [datetime] NULL,
[ord_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_line] [int] NULL,
[release_date] [datetime] NULL,
[rel_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_quantity] [decimal] (20, 8) NULL,
[rel_received] [decimal] (20, 8) NULL,
[rel_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_sospecialorders] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_sospecialorders] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_sospecialorders] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_sospecialorders] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_sospecialorders] TO [public]
GO
