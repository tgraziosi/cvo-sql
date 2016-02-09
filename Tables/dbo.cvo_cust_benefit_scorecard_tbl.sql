CREATE TABLE [dbo].[cvo_cust_benefit_scorecard_tbl]
(
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq] [int] NOT NULL,
[ben_type] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ben_title] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[val_1_lbl] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[val_1_int] [int] NULL,
[val_2_lbl] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[val_2_int] [int] NULL,
[val_3_lbl] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[val_3_dec] [decimal] (20, 8) NULL,
[val_4_lbl] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[val_4_dec] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [pk_cust_beni_idx] ON [dbo].[cvo_cust_benefit_scorecard_tbl] ([cust_code], [ship_to], [seq]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_cust_benefit_scorecard_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cust_benefit_scorecard_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cust_benefit_scorecard_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cust_benefit_scorecard_tbl] TO [public]
GO
