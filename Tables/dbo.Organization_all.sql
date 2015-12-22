CREATE TABLE [dbo].[Organization_all]
(
[timestamp] [timestamp] NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[organization_name] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active_flag] [int] NOT NULL,
[outline_num] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[branch_account_number] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_flag] [int] NOT NULL,
[create_date] [datetime] NOT NULL,
[create_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[country] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_id_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[region_flag] [int] NOT NULL,
[inherit_security] [int] NOT NULL,
[inherit_setup] [int] NOT NULL,
[tc_companycode] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [organization_all_ind_1] ON [dbo].[Organization_all] ([organization_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[Organization_all] TO [public]
GO
GRANT SELECT ON  [dbo].[Organization_all] TO [public]
GO
GRANT INSERT ON  [dbo].[Organization_all] TO [public]
GO
GRANT DELETE ON  [dbo].[Organization_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[Organization_all] TO [public]
GO
