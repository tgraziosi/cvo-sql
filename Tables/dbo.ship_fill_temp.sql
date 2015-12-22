CREATE TABLE [dbo].[ship_fill_temp]
(
[timestamp] [timestamp] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[percent_filled] [decimal] (20, 8) NOT NULL,
[quantity] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [shipftm1] ON [dbo].[ship_fill_temp] ([location], [percent_filled]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ship_fill_temp] TO [public]
GO
GRANT SELECT ON  [dbo].[ship_fill_temp] TO [public]
GO
GRANT INSERT ON  [dbo].[ship_fill_temp] TO [public]
GO
GRANT DELETE ON  [dbo].[ship_fill_temp] TO [public]
GO
GRANT UPDATE ON  [dbo].[ship_fill_temp] TO [public]
GO
