CREATE TABLE [dbo].[arcmtype]
(
[timestamp] [timestamp] NOT NULL,
[cm_type] [smallint] NOT NULL,
[cm_descr] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arcmtype_ind_0] ON [dbo].[arcmtype] ([cm_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcmtype] TO [public]
GO
GRANT SELECT ON  [dbo].[arcmtype] TO [public]
GO
GRANT INSERT ON  [dbo].[arcmtype] TO [public]
GO
GRANT DELETE ON  [dbo].[arcmtype] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcmtype] TO [public]
GO
