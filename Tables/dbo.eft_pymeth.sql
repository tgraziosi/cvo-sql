CREATE TABLE [dbo].[eft_pymeth]
(
[timestamp] [timestamp] NOT NULL,
[file_fmt_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_identification] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[originator_status_code] [smallint] NOT NULL,
[next_eft_batch_number] [int] NOT NULL,
[transaction_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eft_pymeth_ind_0] ON [dbo].[eft_pymeth] ([payment_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eft_pymeth] TO [public]
GO
GRANT SELECT ON  [dbo].[eft_pymeth] TO [public]
GO
GRANT INSERT ON  [dbo].[eft_pymeth] TO [public]
GO
GRANT DELETE ON  [dbo].[eft_pymeth] TO [public]
GO
GRANT UPDATE ON  [dbo].[eft_pymeth] TO [public]
GO
