CREATE TABLE [dbo].[apbranch]
(
[timestamp] [timestamp] NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tlx_twx] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_id_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apbranch_ind_1] ON [dbo].[apbranch] ([addr_sort1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apbranch_ind_2] ON [dbo].[apbranch] ([addr_sort2]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apbranch_ind_3] ON [dbo].[apbranch] ([addr_sort3]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apbranch_ind_0] ON [dbo].[apbranch] ([branch_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apbranch] TO [public]
GO
GRANT SELECT ON  [dbo].[apbranch] TO [public]
GO
GRANT INSERT ON  [dbo].[apbranch] TO [public]
GO
GRANT DELETE ON  [dbo].[apbranch] TO [public]
GO
GRANT UPDATE ON  [dbo].[apbranch] TO [public]
GO
