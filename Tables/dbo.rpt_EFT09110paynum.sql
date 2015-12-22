CREATE TABLE [dbo].[rpt_EFT09110paynum]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_EFT09110paynum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_EFT09110paynum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_EFT09110paynum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_EFT09110paynum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_EFT09110paynum] TO [public]
GO
