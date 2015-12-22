CREATE TABLE [dbo].[arfrcode]
(
[timestamp] [timestamp] NOT NULL,
[freight_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[freight_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_via_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arfrcode_ind_0] ON [dbo].[arfrcode] ([freight_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arfrcode] TO [public]
GO
GRANT SELECT ON  [dbo].[arfrcode] TO [public]
GO
GRANT INSERT ON  [dbo].[arfrcode] TO [public]
GO
GRANT DELETE ON  [dbo].[arfrcode] TO [public]
GO
GRANT UPDATE ON  [dbo].[arfrcode] TO [public]
GO
