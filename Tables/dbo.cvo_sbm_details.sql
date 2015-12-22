CREATE TABLE [dbo].[cvo_sbm_details]
(
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[return_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[c_month] [int] NULL,
[c_year] [int] NULL,
[X_MONTH] [int] NULL,
[month] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[year] [int] NULL,
[asales] [float] NULL,
[areturns] [float] NULL,
[anet] [float] NULL,
[qsales] [float] NULL,
[qreturns] [float] NULL,
[qnet] [float] NULL,
[csales] [float] NULL,
[lsales] [float] NULL,
[yyyymmdd] [datetime] NULL,
[DateOrdered] [datetime] NULL,
[orig_return_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id] [int] NOT NULL IDENTITY(1, 1),
[isCL] [int] NULL,
[isBO] [int] NULL,
[slp] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_sbm_details_amts] ON [dbo].[cvo_sbm_details] ([asales], [areturns], [qsales], [qreturns], [lsales]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_sbm_cust_part] ON [dbo].[cvo_sbm_details] ([customer], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_sbm_cust] ON [dbo].[cvo_sbm_details] ([customer], [ship_to], [yyyymmdd], [DateOrdered]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_sbm_det_for_drp] ON [dbo].[cvo_sbm_details] ([part_no], [location], [qsales], [qreturns]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_sbm_prod] ON [dbo].[cvo_sbm_details] ([part_no], [yyyymmdd]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_sbm_yyyymmdd] ON [dbo].[cvo_sbm_details] ([yyyymmdd]) INCLUDE ([anet], [ship_to], [customer], [user_category], [part_no], [c_month], [c_year]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_sbm_yyyymmdd_cir] ON [dbo].[cvo_sbm_details] ([yyyymmdd]) INCLUDE ([return_code], [DateOrdered], [ship_to], [part_no], [customer], [isCL], [qreturns], [qsales], [user_category]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_sbm_details] TO [public]
GO
