CREATE TABLE [dbo].[CVO_bogo_qualified]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[spid] [int] NOT NULL,
[line_no] [int] NOT NULL,
[buy_qty] [int] NOT NULL,
[get_qty] [int] NOT NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gender_check] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attribute_check] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adt_brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adt_gender_check] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adt_attribute_check] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adt_discount] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_bogo_qualified_ind01] ON [dbo].[CVO_bogo_qualified] ([spid], [rec_id]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[CVO_bogo_qualified] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_bogo_qualified] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_bogo_qualified] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_bogo_qualified] TO [public]
GO
