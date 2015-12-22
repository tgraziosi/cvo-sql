CREATE TABLE [dbo].[CVO_NAVY_INFO]
(
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[store] [int] NULL,
[storelist] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[locname] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT VIEW DEFINITION ON  [dbo].[CVO_NAVY_INFO] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_NAVY_INFO] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_NAVY_INFO] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_NAVY_INFO] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_NAVY_INFO] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_NAVY_INFO] TO [public]
GO
