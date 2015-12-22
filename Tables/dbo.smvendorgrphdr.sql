CREATE TABLE [dbo].[smvendorgrphdr]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [int] NOT NULL,
[id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__smvendorgrph__id__5A4B9D52] DEFAULT (newid()),
[group_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[global_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [smvendorgrphdr_ind_3] ON [dbo].[smvendorgrphdr] ([global_flag]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smvendorgrphdr_ind_0] ON [dbo].[smvendorgrphdr] ([group_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [smvendorgrphdr_ind_1] ON [dbo].[smvendorgrphdr] ([group_id], [global_flag]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smvendorgrphdr_ind_2] ON [dbo].[smvendorgrphdr] ([group_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smvendorgrphdr] TO [public]
GO
GRANT SELECT ON  [dbo].[smvendorgrphdr] TO [public]
GO
GRANT INSERT ON  [dbo].[smvendorgrphdr] TO [public]
GO
GRANT DELETE ON  [dbo].[smvendorgrphdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[smvendorgrphdr] TO [public]
GO
