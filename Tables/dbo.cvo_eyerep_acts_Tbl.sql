CREATE TABLE [dbo].[cvo_eyerep_acts_Tbl]
(
[acct_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[billing_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[billing_addr1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[billing_addr2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[billing_city] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[billing_state] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[billing_postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[billing_phone] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[billing_email] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_balance] [decimal] (9, 2) NULL,
[detail_note] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_status] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_sort] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prospect] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[billing_fax] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_eyerep_acts_Tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_eyerep_acts_Tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_eyerep_acts_Tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_eyerep_acts_Tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_eyerep_acts_Tbl] TO [public]
GO
