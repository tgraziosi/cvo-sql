CREATE TABLE [dbo].[tdc_cdock_mgt]
(
[tran_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[from_tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_tran_ext] [int] NULL,
[from_tran_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[release_date] [datetime] NOT NULL,
[qty] [decimal] (24, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_cdock_mgt_IDX3] ON [dbo].[tdc_cdock_mgt] ([location], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_cdock_mgt_IDX1] ON [dbo].[tdc_cdock_mgt] ([qty]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_cdock_mgt_IDX2] ON [dbo].[tdc_cdock_mgt] ([tran_type], [tran_no], [tran_ext], [location], [part_no], [line_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_cdock_mgt] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_cdock_mgt] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_cdock_mgt] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_cdock_mgt] TO [public]
GO
