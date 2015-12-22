CREATE TABLE [dbo].[apcash]
(
[timestamp] [timestamp] NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bank_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tlx_twx] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transit_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_check_num] [int] NOT NULL,
[check_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[check_start_col] [smallint] NOT NULL,
[check_length] [smallint] NOT NULL,
[amt_serv_chrg] [float] NOT NULL,
[serv_chrg_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bank_account_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[aba_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[canadian_printing_flag] [smallint] NULL,
[bank_account_encrypted] [varbinary] (max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apcash_ind_0] ON [dbo].[apcash] ([cash_acct_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apcash] TO [public]
GO
GRANT SELECT ON  [dbo].[apcash] TO [public]
GO
GRANT INSERT ON  [dbo].[apcash] TO [public]
GO
GRANT DELETE ON  [dbo].[apcash] TO [public]
GO
GRANT UPDATE ON  [dbo].[apcash] TO [public]
GO
