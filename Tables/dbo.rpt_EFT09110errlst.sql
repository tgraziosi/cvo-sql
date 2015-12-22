CREATE TABLE [dbo].[rpt_EFT09110errlst]
(
[char_parm_1] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[char_parm_2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_EFT09110errlst] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_EFT09110errlst] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_EFT09110errlst] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_EFT09110errlst] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_EFT09110errlst] TO [public]
GO
