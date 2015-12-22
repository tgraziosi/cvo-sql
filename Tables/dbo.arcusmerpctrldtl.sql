CREATE TABLE [dbo].[arcusmerpctrldtl]
(
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[merged_customer] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[on_order] [float] NOT NULL,
[unposted] [float] NOT NULL,
[posted_count] [int] NOT NULL,
[paid_count] [int] NOT NULL,
[overdue_count] [int] NOT NULL,
[bucket1] [float] NOT NULL,
[bucket2] [float] NOT NULL,
[bucket3] [float] NOT NULL,
[bucket4] [float] NOT NULL,
[bucket5] [float] NOT NULL,
[bucket6] [float] NOT NULL,
[on_account] [float] NOT NULL,
[balance] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arcusmerpctrldtl_0] ON [dbo].[arcusmerpctrldtl] ([process_ctrl_num], [merged_customer]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[arcusmerpctrldtl] TO [public]
GO
GRANT INSERT ON  [dbo].[arcusmerpctrldtl] TO [public]
GO
GRANT DELETE ON  [dbo].[arcusmerpctrldtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcusmerpctrldtl] TO [public]
GO
