CREATE TABLE [dbo].[tdc_wow_ship_to]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_ship_to] [int] NULL CONSTRAINT [DF__tdc_wow_s__all_s__21564474] DEFAULT ((0)),
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_ship_to_idx1] ON [dbo].[tdc_wow_ship_to] ([userid], [customer_code], [ship_to_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_ship_to] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_ship_to] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_ship_to] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_ship_to] TO [public]
GO
