CREATE TABLE [dbo].[lc_apvoucher]
(
[timestamp] [timestamp] NOT NULL,
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [lc_apvoucher_pk] ON [dbo].[lc_apvoucher] ([voucher_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lc_apvoucher] TO [public]
GO
GRANT SELECT ON  [dbo].[lc_apvoucher] TO [public]
GO
GRANT INSERT ON  [dbo].[lc_apvoucher] TO [public]
GO
GRANT DELETE ON  [dbo].[lc_apvoucher] TO [public]
GO
GRANT UPDATE ON  [dbo].[lc_apvoucher] TO [public]
GO
