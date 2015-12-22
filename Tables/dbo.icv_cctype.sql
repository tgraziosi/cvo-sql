CREATE TABLE [dbo].[icv_cctype]
(
[timestamp] [timestamp] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[creditcard_prefix] [int] NOT NULL,
[creditcard_length] [int] NOT NULL,
[use_mod10_validation] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_cctype] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_cctype] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_cctype] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_cctype] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_cctype] TO [public]
GO
