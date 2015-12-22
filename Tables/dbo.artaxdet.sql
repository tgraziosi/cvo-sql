CREATE TABLE [dbo].[artaxdet]
(
[timestamp] [timestamp] NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[base_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [artaxdet_ind_0] ON [dbo].[artaxdet] ([tax_code], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artaxdet] TO [public]
GO
GRANT SELECT ON  [dbo].[artaxdet] TO [public]
GO
GRANT INSERT ON  [dbo].[artaxdet] TO [public]
GO
GRANT DELETE ON  [dbo].[artaxdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[artaxdet] TO [public]
GO
