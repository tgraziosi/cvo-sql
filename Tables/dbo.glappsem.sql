CREATE TABLE [dbo].[glappsem]
(
[app_id] [int] NOT NULL,
[gl_coa_changed] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glappsem_ind_0] ON [dbo].[glappsem] ([app_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glappsem] TO [public]
GO
GRANT SELECT ON  [dbo].[glappsem] TO [public]
GO
GRANT INSERT ON  [dbo].[glappsem] TO [public]
GO
GRANT DELETE ON  [dbo].[glappsem] TO [public]
GO
GRANT UPDATE ON  [dbo].[glappsem] TO [public]
GO
