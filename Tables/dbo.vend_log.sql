CREATE TABLE [dbo].[vend_log]
(
[timestamp] [timestamp] NOT NULL,
[vendor_key] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [vendlog1] ON [dbo].[vend_log] ([vendor_key], [date_entered]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[vend_log] TO [public]
GO
GRANT SELECT ON  [dbo].[vend_log] TO [public]
GO
GRANT INSERT ON  [dbo].[vend_log] TO [public]
GO
GRANT DELETE ON  [dbo].[vend_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[vend_log] TO [public]
GO
