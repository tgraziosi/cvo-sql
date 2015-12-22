CREATE TABLE [dbo].[freight_type]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [frgttyp1] ON [dbo].[freight_type] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[freight_type] TO [public]
GO
GRANT SELECT ON  [dbo].[freight_type] TO [public]
GO
GRANT INSERT ON  [dbo].[freight_type] TO [public]
GO
GRANT DELETE ON  [dbo].[freight_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[freight_type] TO [public]
GO
