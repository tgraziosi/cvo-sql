CREATE TABLE [dbo].[securitytokendetail]
(
[timestamp] [timestamp] NOT NULL,
[security_token] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[group_id] [smallint] NOT NULL,
[id] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [smallint] NOT NULL,
[create_date] [datetime] NOT NULL,
[create_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [smtokendet_ind_1] ON [dbo].[securitytokendetail] ([security_token]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [smtokendet_ind_3] ON [dbo].[securitytokendetail] ([security_token], [group_id], [type]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [smtokendet_ind_0] ON [dbo].[securitytokendetail] ([type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[securitytokendetail] TO [public]
GO
GRANT SELECT ON  [dbo].[securitytokendetail] TO [public]
GO
GRANT INSERT ON  [dbo].[securitytokendetail] TO [public]
GO
GRANT DELETE ON  [dbo].[securitytokendetail] TO [public]
GO
GRANT UPDATE ON  [dbo].[securitytokendetail] TO [public]
GO
