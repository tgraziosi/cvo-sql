CREATE TABLE [dbo].[rpt_iborg]
(
[timestamp] [timestamp] NOT NULL,
[outline_screen] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[organization_id] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[organization_name] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[region_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[active_flag] [int] NOT NULL,
[outline_num] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[branch_account_number] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_flag] [int] NOT NULL,
[create_date] [datetime] NOT NULL,
[create_username] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_id_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[numlevel] [int] NOT NULL,
[region_flag] [int] NOT NULL,
[inherit_security] [int] NOT NULL,
[inherit_setup] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_iborg] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_iborg] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_iborg] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_iborg] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_iborg] TO [public]
GO
