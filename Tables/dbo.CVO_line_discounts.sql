CREATE TABLE [dbo].[CVO_line_discounts]
(
[promo_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [int] NOT NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[discount_per] [decimal] (6, 2) NULL,
[list] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_line_d__list__309193BF] DEFAULT ('N'),
[cust] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_line_d__cust__3185B7F8] DEFAULT ('N'),
[price_override] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_line_discounts] ON [dbo].[CVO_line_discounts] ([promo_ID], [line_no], [promo_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_line_discounts] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_line_discounts] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_line_discounts] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_line_discounts] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_line_discounts] TO [public]
GO
