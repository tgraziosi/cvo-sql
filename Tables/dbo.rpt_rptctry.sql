CREATE TABLE [dbo].[rpt_rptctry]
(
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[country_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[zone_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_reg_flag] [smallint] NOT NULL,
[vat_num_prefix] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_branch_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_flag] [smallint] NOT NULL,
[agent_vat_num_prefix] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_vat_branch_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_name] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[harbour] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[harbour_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bundesland] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bundesland_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[department] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[department_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_rptctry] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_rptctry] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_rptctry] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_rptctry] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_rptctry] TO [public]
GO
