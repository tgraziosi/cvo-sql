CREATE TABLE [dbo].[so_usrcateg]
(
[timestamp] [timestamp] NOT NULL,
[category_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category_desc] [varchar] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[no_stock_flag] [int] NULL,
[no_stock_hold] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notifications] [smallint] NULL,
[no_stock_flag_console] [smallint] NULL,
[notifications_console] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[CVO_OrderType_tr] on [dbo].[so_usrcateg]
   FOR INSERT, UPDATE
AS

DECLARE @i_cat_code varchar(10), @i_void varchar(1)

SELECT @i_cat_code = i.category_code, @i_void = i.void FROM inserted i

IF NOT EXISTS (SELECT order_category FROM cvo_order_types WHERE order_category = @i_cat_code)
	BEGIN
		INSERT INTO cvo_order_types SELECT @i_cat_code, 'Y'
	END

IF @i_void = 'V'
	BEGIN
		DELETE cvo_order_types WHERE order_category = @i_cat_code
	END

GO
CREATE UNIQUE CLUSTERED INDEX [so_usrcateg_idx] ON [dbo].[so_usrcateg] ([category_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[so_usrcateg] TO [public]
GO
GRANT SELECT ON  [dbo].[so_usrcateg] TO [public]
GO
GRANT INSERT ON  [dbo].[so_usrcateg] TO [public]
GO
GRANT DELETE ON  [dbo].[so_usrcateg] TO [public]
GO
GRANT UPDATE ON  [dbo].[so_usrcateg] TO [public]
GO
