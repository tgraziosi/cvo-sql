CREATE TABLE [dbo].[smcustomergrphdr]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [int] NOT NULL,
[id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__smcustomergr__id__576F30A7] DEFAULT (newid()),
[group_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[global_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [smcustomergrphdr_ind_3] ON [dbo].[smcustomergrphdr] ([global_flag]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smcustomergrphdr_ind_0] ON [dbo].[smcustomergrphdr] ([group_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [smcustomergrphdr_ind_1] ON [dbo].[smcustomergrphdr] ([group_id], [global_flag]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smcustomergrphdr_ind_2] ON [dbo].[smcustomergrphdr] ([group_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smcustomergrphdr] TO [public]
GO
GRANT SELECT ON  [dbo].[smcustomergrphdr] TO [public]
GO
GRANT INSERT ON  [dbo].[smcustomergrphdr] TO [public]
GO
GRANT DELETE ON  [dbo].[smcustomergrphdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[smcustomergrphdr] TO [public]
GO
