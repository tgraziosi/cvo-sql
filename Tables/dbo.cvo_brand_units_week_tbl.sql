CREATE TABLE [dbo].[cvo_brand_units_week_tbl]
(
[brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MODEL] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_date] [datetime] NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_date_wk] [int] NULL,
[first_wk] [int] NULL,
[wkno] [bigint] NULL,
[num_cust] [int] NULL,
[sales_qty] [real] NULL,
[st_qty] [real] NULL,
[rx_qty] [real] NULL,
[ret_qty] [real] NULL,
[cl_qty] [real] NULL,
[rec_type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asofdate] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_brand_units_week] ON [dbo].[cvo_brand_units_week_tbl] ([brand], [MODEL], [wkno]) ON [PRIMARY]
GO
