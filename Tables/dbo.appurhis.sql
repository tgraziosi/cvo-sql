CREATE TABLE [dbo].[appurhis]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[date_purged] [datetime] NOT NULL,
[purge_user_name] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[appurhis] TO [public]
GO
GRANT SELECT ON  [dbo].[appurhis] TO [public]
GO
GRANT INSERT ON  [dbo].[appurhis] TO [public]
GO
GRANT DELETE ON  [dbo].[appurhis] TO [public]
GO
GRANT UPDATE ON  [dbo].[appurhis] TO [public]
GO
