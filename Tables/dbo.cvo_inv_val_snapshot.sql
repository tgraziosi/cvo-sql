CREATE TABLE [dbo].[cvo_inv_val_snapshot]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_stock] [decimal] (27, 8) NULL,
[LBS_qty] [decimal] (38, 8) NOT NULL,
[cvo_in_stock] [decimal] (26, 8) NULL,
[ext_value] [decimal] (38, 6) NULL,
[LBS_ext_value] [decimal] (38, 6) NULL,
[cvo_ext_value] [decimal] (38, 6) NULL,
[std_cost] [decimal] (20, 8) NOT NULL,
[std_ovhd_dolrs] [decimal] (20, 8) NULL,
[std_util_dolrs] [decimal] (20, 8) NULL,
[PNS_qty] [decimal] (21, 8) NULL,
[PNS_value] [decimal] (38, 10) NULL,
[QC_qty] [decimal] (20, 8) NOT NULL,
[QC_Value] [decimal] (38, 11) NULL,
[INT_qty] [decimal] (20, 8) NULL,
[INT_Value] [decimal] (38, 11) NULL,
[obs] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pom_date] [datetime] NULL,
[bkordr_date] [datetime] NULL,
[inv_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_ovhd_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_util_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AsOfDate] [datetime] NOT NULL,
[Valuation_group] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_inv_val_snapshot] TO [public]
GO
