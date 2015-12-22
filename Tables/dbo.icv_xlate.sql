CREATE TABLE [dbo].[icv_xlate]
(
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_xlate] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_xlate] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_xlate] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_xlate] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_xlate] TO [public]
GO
