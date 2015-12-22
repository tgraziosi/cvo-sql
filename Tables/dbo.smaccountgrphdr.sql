CREATE TABLE [dbo].[smaccountgrphdr]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [smallint] NOT NULL,
[id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__smaccountgrp__id__539E9FC3] DEFAULT (newid()),
[group_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[global_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [smaccountgrphdr_ind_3] ON [dbo].[smaccountgrphdr] ([global_flag]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smaccountgrphdr_ind_0] ON [dbo].[smaccountgrphdr] ([group_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [smaccountgrphdr_ind_1] ON [dbo].[smaccountgrphdr] ([group_id], [global_flag]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smaccountgrphdr_ind_2] ON [dbo].[smaccountgrphdr] ([group_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smaccountgrphdr] TO [public]
GO
GRANT SELECT ON  [dbo].[smaccountgrphdr] TO [public]
GO
GRANT INSERT ON  [dbo].[smaccountgrphdr] TO [public]
GO
GRANT DELETE ON  [dbo].[smaccountgrphdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[smaccountgrphdr] TO [public]
GO
