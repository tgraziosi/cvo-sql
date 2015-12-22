CREATE TABLE [dbo].[arfrate]
(
[timestamp] [timestamp] NOT NULL,
[freight_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[orig_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[thru_dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[max_weight] [float] NOT NULL,
[freight_amt] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arfrate_ind_1] ON [dbo].[arfrate] ([freight_code], [orig_zone_code], [from_dest_zone_code], [thru_dest_zone_code], [max_weight]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [arfrate_ind_0] ON [dbo].[arfrate] ([freight_code], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arfrate] TO [public]
GO
GRANT SELECT ON  [dbo].[arfrate] TO [public]
GO
GRANT INSERT ON  [dbo].[arfrate] TO [public]
GO
GRANT DELETE ON  [dbo].[arfrate] TO [public]
GO
GRANT UPDATE ON  [dbo].[arfrate] TO [public]
GO
