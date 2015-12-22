CREATE TABLE [dbo].[cvo_update_salesperson_ship]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [int] NULL,
[order_ext] [int] NULL,
[order_no_text] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_territory_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_salesperson_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ignore] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_update_salesperson_ship_ind0] ON [dbo].[cvo_update_salesperson_ship] ([row_id], [order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_update_salesperson_ship] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_update_salesperson_ship] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_update_salesperson_ship] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_update_salesperson_ship] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_update_salesperson_ship] TO [public]
GO
