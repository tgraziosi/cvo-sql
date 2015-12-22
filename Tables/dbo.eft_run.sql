CREATE TABLE [dbo].[eft_run]
(
[timestamp] [timestamp] NOT NULL,
[eft_batch_num] [int] NOT NULL,
[run_sequence] [int] NOT NULL,
[run_date] [datetime] NOT NULL,
[value_of_trans] [float] NOT NULL,
[number_of_trans] [int] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_entry_description] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_descriptive_date] [int] NOT NULL,
[effective_entry_date] [int] NOT NULL,
[addenda_flag] [smallint] NOT NULL,
[orig_account_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_bank_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_aba_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rb_processing_centre] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eft_run_ind_0] ON [dbo].[eft_run] ([eft_batch_num], [payment_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eft_run] TO [public]
GO
GRANT SELECT ON  [dbo].[eft_run] TO [public]
GO
GRANT INSERT ON  [dbo].[eft_run] TO [public]
GO
GRANT DELETE ON  [dbo].[eft_run] TO [public]
GO
GRANT UPDATE ON  [dbo].[eft_run] TO [public]
GO
