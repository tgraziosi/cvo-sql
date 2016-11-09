CREATE TABLE [dbo].[cvo_promo_tracker_subscription_list]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[promo_id] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [datetime] NULL,
[end_date] [datetime] NULL,
[Group_Name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Seq_id] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_promo_tracker_subscription_list] ADD CONSTRAINT [PK__cvo_promo_tracke__4A545D25] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_promo_tracker_subscription_list] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_promo_tracker_subscription_list] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_promo_tracker_subscription_list] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_promo_tracker_subscription_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_promo_tracker_subscription_list] TO [public]
GO
