CREATE TABLE [dbo].[cvo_inv_val_month]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_stock] [decimal] (20, 8) NULL,
[LBS_qty] [decimal] (20, 8) NOT NULL,
[cvo_in_stock] [decimal] (20, 8) NULL,
[ext_value] [decimal] (20, 8) NULL,
[LBS_ext_value] [decimal] (20, 8) NULL,
[cvo_ext_value] [decimal] (20, 8) NULL,
[std_cost] [decimal] (20, 8) NOT NULL,
[std_ovhd_dolrs] [decimal] (20, 8) NULL,
[std_util_dolrs] [decimal] (20, 8) NULL,
[PNS_qty] [decimal] (20, 8) NULL,
[PNS_value] [decimal] (20, 8) NULL,
[QC_qty] [decimal] (20, 8) NOT NULL,
[QC_Value] [decimal] (20, 8) NULL,
[INT_qty] [decimal] (20, 8) NULL,
[INT_Value] [decimal] (20, 8) NULL,
[obs] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pom_date] [datetime] NULL,
[bkordr_date] [datetime] NULL,
[inv_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_ovhd_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_util_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asofdate] [datetime] NULL,
[Valuation_group] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [invm1] ON [dbo].[cvo_inv_val_month] ([part_no], [location], [asofdate]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_inv_val_month] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_val_month] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_val_month] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_val_month] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_val_month] TO [public]
GO
