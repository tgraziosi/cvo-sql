CREATE TABLE [dbo].[tdc_adhoc_receipts]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[adhoc_rec_no] [int] NOT NULL,
[rec_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_ref_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_adhoc__rec_d__322BCABB] DEFAULT (getdate()),
[tran_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[error_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[modified_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_adhoc__modif__331FEEF4] DEFAULT (getdate())
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_adhoc_receipts] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_adhoc_receipts] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_adhoc_receipts] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_adhoc_receipts] TO [public]
GO
