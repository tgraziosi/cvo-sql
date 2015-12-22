CREATE TABLE [dbo].[cvo_pattern_tracking]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pattern] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[line_no] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cvo_pattern_tracking_ind0] ON [dbo].[cvo_pattern_tracking] ([customer_code], [ship_to], [pattern]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_pattern_tracking_ind1] ON [dbo].[cvo_pattern_tracking] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_pattern_tracking_ind2] ON [dbo].[cvo_pattern_tracking] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_pattern_tracking] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_pattern_tracking] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_pattern_tracking] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_pattern_tracking] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_pattern_tracking] TO [public]
GO
