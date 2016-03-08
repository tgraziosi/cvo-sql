CREATE TABLE [dbo].[cvo_eyerep_inv_tbl]
(
[sku] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[upc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[collection_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[style] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[color] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eye_size] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[temple] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bridge] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[product_rank] [int] NULL,
[collection_rank] [int] NULL,
[product_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avail_status] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avail_date] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[base_price] [decimal] (9, 2) NULL,
[new_release] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_eyerep_inv_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_eyerep_inv_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_eyerep_inv_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_eyerep_inv_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_eyerep_inv_tbl] TO [public]
GO
