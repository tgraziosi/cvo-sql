CREATE TABLE [dbo].[rpt_eft09130]
(
[current_eft] [int] NOT NULL,
[run_sequence] [int] NOT NULL,
[file_name1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_bank_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_account_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_aba_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_description] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_decriptive_date] [int] NOT NULL,
[effective_entry_date] [int] NOT NULL,
[addenda_flag] [int] NOT NULL,
[number_of_trans] [int] NOT NULL,
[value_of_trans] [float] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_eft09130] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_eft09130] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_eft09130] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_eft09130] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_eft09130] TO [public]
GO
