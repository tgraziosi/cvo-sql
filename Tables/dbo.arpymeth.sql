CREATE TABLE [dbo].[arpymeth]
(
[timestamp] [timestamp] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asset_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[on_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt1_mask_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2_mask_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3_mask_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4_mask_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[over_tendered_flag] [smallint] NOT NULL,
[mgr_auth_flag] [smallint] NOT NULL,
[mgr_auth_amt] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arpymeth_ind_0] ON [dbo].[arpymeth] ([payment_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arpymeth] TO [public]
GO
GRANT SELECT ON  [dbo].[arpymeth] TO [public]
GO
GRANT INSERT ON  [dbo].[arpymeth] TO [public]
GO
GRANT DELETE ON  [dbo].[arpymeth] TO [public]
GO
GRANT UPDATE ON  [dbo].[arpymeth] TO [public]
GO
