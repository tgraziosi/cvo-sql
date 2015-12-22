CREATE TABLE [dbo].[tdc_arch_log]
(
[tran_date] [datetime] NOT NULL,
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[data] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_archived] [datetime] NULL,
[who_archived] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_arch_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_arch_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_arch_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_arch_log] TO [public]
GO
