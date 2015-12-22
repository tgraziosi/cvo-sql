CREATE TABLE [dbo].[glreftyp]
(
[timestamp] [timestamp] NOT NULL,
[reference_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glreftyp_ind_0] ON [dbo].[glreftyp] ([reference_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glreftyp] TO [public]
GO
GRANT SELECT ON  [dbo].[glreftyp] TO [public]
GO
GRANT INSERT ON  [dbo].[glreftyp] TO [public]
GO
GRANT DELETE ON  [dbo].[glreftyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[glreftyp] TO [public]
GO
