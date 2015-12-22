CREATE TABLE [dbo].[estimates]
(
[timestamp] [timestamp] NOT NULL,
[est_no] [int] NOT NULL,
[revision] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[material_multi] [decimal] (20, 8) NOT NULL,
[direct_multi] [decimal] (20, 8) NOT NULL,
[ovhd_multi] [decimal] (20, 8) NOT NULL,
[util_multi] [decimal] (20, 8) NOT NULL,
[tot_matl_dolrs] [decimal] (20, 8) NOT NULL,
[tot_direct_dolrs] [decimal] (20, 8) NOT NULL,
[tot_ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[tot_util_dolrs] [decimal] (20, 8) NOT NULL,
[quoted_price] [decimal] (20, 8) NOT NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cancel_date] [datetime] NULL,
[address_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quoted_qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [est1] ON [dbo].[estimates] ([est_no], [quoted_qty]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[estimates] TO [public]
GO
GRANT SELECT ON  [dbo].[estimates] TO [public]
GO
GRANT INSERT ON  [dbo].[estimates] TO [public]
GO
GRANT DELETE ON  [dbo].[estimates] TO [public]
GO
GRANT UPDATE ON  [dbo].[estimates] TO [public]
GO
