CREATE TABLE [dbo].[cycle_types]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cycle_days] [int] NOT NULL,
[cycle_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[num_items] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cycle1] ON [dbo].[cycle_types] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cycle_types] TO [public]
GO
GRANT SELECT ON  [dbo].[cycle_types] TO [public]
GO
GRANT INSERT ON  [dbo].[cycle_types] TO [public]
GO
GRANT DELETE ON  [dbo].[cycle_types] TO [public]
GO
GRANT UPDATE ON  [dbo].[cycle_types] TO [public]
GO
