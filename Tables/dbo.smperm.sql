CREATE TABLE [dbo].[smperm]
(
[timestamp] [timestamp] NOT NULL,
[user_id] [smallint] NOT NULL,
[company_id] [smallint] NOT NULL,
[app_id] [smallint] NOT NULL,
[form_id] [int] NOT NULL,
[object_type] [smallint] NOT NULL,
[read_perm] [smallint] NOT NULL,
[write] [smallint] NOT NULL,
[user_copy] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [smperm_ind_0] ON [dbo].[smperm] ([user_id], [company_id], [app_id], [form_id], [object_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smperm] TO [public]
GO
GRANT SELECT ON  [dbo].[smperm] TO [public]
GO
GRANT INSERT ON  [dbo].[smperm] TO [public]
GO
GRANT DELETE ON  [dbo].[smperm] TO [public]
GO
GRANT UPDATE ON  [dbo].[smperm] TO [public]
GO
