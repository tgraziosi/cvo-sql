CREATE TABLE [dbo].[cvo_sm_inv_snapshot_tbl]
(
[usage_type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[upc_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[date_tran] [datetime] NOT NULL,
[date_expires] [datetime] NOT NULL,
[std_cost] [decimal] (20, 8) NOT NULL,
[std_ovhd_dolrs] [decimal] (20, 8) NULL,
[std_util_dolrs] [decimal] (20, 8) NULL,
[ext_cost] [decimal] (38, 11) NULL,
[Is_Assigned] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[primary_bin] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[maximum_level] [int] NULL,
[last_modified_date] [datetime] NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asofdate] [datetime] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_sm_inv_snapshot_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sm_inv_snapshot_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sm_inv_snapshot_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_sm_inv_snapshot_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sm_inv_snapshot_tbl] TO [public]
GO
