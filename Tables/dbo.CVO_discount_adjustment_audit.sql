CREATE TABLE [dbo].[CVO_discount_adjustment_audit]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[adjustment_date] [datetime] NOT NULL,
[user_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_from] [datetime] NULL,
[date_to] [datetime] NULL,
[price_class] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[original_price] [decimal] (20, 8) NOT NULL,
[original_discount] [decimal] (20, 8) NOT NULL,
[new_price] [decimal] (20, 8) NOT NULL,
[new_discount] [decimal] (20, 8) NOT NULL,
[action] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_discount_adjustment_audit_inx02] ON [dbo].[CVO_discount_adjustment_audit] ([order_no], [ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_discount_adjustment_audit_inx01] ON [dbo].[CVO_discount_adjustment_audit] ([rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_discount_adjustment_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_discount_adjustment_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_discount_adjustment_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_discount_adjustment_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_discount_adjustment_audit] TO [public]
GO
