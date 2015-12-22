CREATE TABLE [dbo].[EAI_RMAHeader]
(
[FO_RMAID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FO_cust_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by_date] [datetime] NULL,
[modified_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_RMAHeader] ADD CONSTRAINT [EAI_RMAHeader_pk] PRIMARY KEY CLUSTERED  ([FO_RMAID]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_RMAHeader] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_RMAHeader] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_RMAHeader] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_RMAHeader] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_RMAHeader] TO [public]
GO
