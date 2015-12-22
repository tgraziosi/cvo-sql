CREATE TABLE [dbo].[ccwrkhdr]
(
[workload_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[workload_desc] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[update_date] [smalldatetime] NOT NULL,
[sort_order] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ccwrkhdr_idx] ON [dbo].[ccwrkhdr] ([workload_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ccwrkhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[ccwrkhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[ccwrkhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[ccwrkhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccwrkhdr] TO [public]
GO
