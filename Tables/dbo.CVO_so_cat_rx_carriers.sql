CREATE TABLE [dbo].[CVO_so_cat_rx_carriers]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_category] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rx_carrier] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_so_cat_rx_carriers] ON [dbo].[CVO_so_cat_rx_carriers] ([customer_code], [ship_to_code], [user_category]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_so_cat_rx_carriers] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_so_cat_rx_carriers] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_so_cat_rx_carriers] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_so_cat_rx_carriers] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_so_cat_rx_carriers] TO [public]
GO
