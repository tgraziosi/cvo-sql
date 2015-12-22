CREATE TABLE [dbo].[apvchtyp]
(
[timestamp] [timestamp] NOT NULL,
[voucher_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recurring_flag] [smallint] NOT NULL,
[accrual_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apvchtyp_ind_0] ON [dbo].[apvchtyp] ([voucher_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apvchtyp] TO [public]
GO
GRANT SELECT ON  [dbo].[apvchtyp] TO [public]
GO
GRANT INSERT ON  [dbo].[apvchtyp] TO [public]
GO
GRANT DELETE ON  [dbo].[apvchtyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvchtyp] TO [public]
GO
