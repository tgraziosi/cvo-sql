SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[cvo_fn_12m_sales_cat_style] 
(@category varchar(10), @style varchar(10), @type_code varchar(10), @user_category varchar(2))  
RETURNS decimal (20,8) AS  
BEGIN 

-- 062612 - tag - add user category to split out stock and rx orders

	DECLARE @12m_sales decimal (20,8)--, @order_no int, @order_ext int
	-- set initial list to empty
	SELECT @12m_sales = 0
	select @12m_sales =	
		(select sum (ISNULL(a.shipped,0))
			from ord_list a (NOLOCK)
			inner join orders_all b (NOLOCK) 
			on 	(a.order_no = b.order_no
				and a.order_ext = b.ext)
			inner join inv_master i (nolock) on a.part_no = i.part_no
			inner Join inv_master_add ia (nolock) on a.part_no = ia.part_no
			where i.category = @category and ia.field_2 = @style and i.type_code = @type_code
					and a.part_type = 'P'
					and left(b.user_category,2) = @user_category
					and right(b.user_category,2) <>'RB'
					and b.type = 'I'
					and b.status = 'T'
					and b.date_shipped is not null
					and b.date_shipped between dateadd(m,-12,getdate()) and getdate())
-- History
	select @12m_sales =	 @12m_sales + 
		(select sum (ISNULL(a.shipped,0))
			from cvo_ord_list_hist a (NOLOCK)
			inner join cvo_orders_all_hist b (NOLOCK) 
			on 	(a.order_no = b.order_no
				and a.order_ext = b.ext)
			inner join inv_master i (nolock) on a.part_no = i.part_no
			inner Join inv_master_add ia (nolock) on a.part_no = ia.part_no
			where i.category = @category and ia.field_2 = @style and i.type_code = @type_code
					and a.part_type = 'P'
					and left(b.user_category,2) = @user_category
					and right(b.user_category,2) <>'RB'
					and b.type = 'I'
					and b.status = 'T'
					and b.date_shipped is not null
					and b.date_shipped between dateadd(m,-12,getdate()) and getdate())

	RETURN @12m_sales
END

GO
