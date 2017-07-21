CREATE TABLE [dbo].[cvo_cycle_count_log]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[adm_actual_qty] [decimal] (20, 8) NOT NULL,
[count_qty] [decimal] (20, 8) NOT NULL,
[count_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
