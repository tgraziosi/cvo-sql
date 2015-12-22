CREATE TABLE [dbo].[epmchopt]
(
[company_id] [int] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_flag] [smallint] NOT NULL,
[tolerance_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receipt_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[match_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_receipt] [int] NOT NULL,
[next_match] [int] NOT NULL,
[enable_load_rec] [int] NOT NULL,
[default_to_qty] [int] NOT NULL,
[default_matching_organization] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epmchopt] TO [public]
GO
GRANT SELECT ON  [dbo].[epmchopt] TO [public]
GO
GRANT INSERT ON  [dbo].[epmchopt] TO [public]
GO
GRANT DELETE ON  [dbo].[epmchopt] TO [public]
GO
GRANT UPDATE ON  [dbo].[epmchopt] TO [public]
GO
