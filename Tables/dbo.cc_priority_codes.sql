CREATE TABLE [dbo].[cc_priority_codes]
(
[priority_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[priority_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cc_priority_codes_idx] ON [dbo].[cc_priority_codes] ([priority_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_priority_codes] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_priority_codes] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_priority_codes] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_priority_codes] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_priority_codes] TO [public]
GO
