SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[cvo_fn_ytd_sales_cat_style] 
(@category varchar(10), @style varchar(10), @type_code varchar(10), @user_category varchar(2))  
RETURNS decimal (20,8) AS  
BEGIN 

-- 062612 - tag - add user category to split out stock and rx orders

	DECLARE @ytd_sales decimal (20,8)--, @order_no int, @order_ext int

	
	-- set initial list to empty
	SELECT @ytd_sales = 0

	--IF (select count(order_no) from orders_invoice where trx_ctrl_num = @trx_ctrl_num)>0
	--BEGIN


						select @ytd_sales =	(select sum (ISNULL(a.shipped,0))
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
										and datepart (year,b.date_shipped) = datepart (year,getdate()))


	--END --IF
	RETURN @ytd_sales
END

-- 

-- select dbo.cvo_fn_ytd_sales ('BCUGOBR05317') 
-- (select sum (ISNULL(a.shipped,0)) from ord_list a (NOLOCK) where a.part_no = 'BCUGOBR05317')
-- (select sum (ISNULL(a.shipped,0)) from ord_list a (NOLOCK) where a.part_no = 'BCUGOBR05317' and datepart (year,b.date_shipped) = datepart (year,getdate()))
/*

 select shipped, date_shipped, * from ord_list a (NOLOCK), orders b (NOLOCK)
where a.order_no = b.order_no
and a.order_ext = b.ext
and b.type = 'I'
and a.part_no = 'BCUGOBR05317'
and shipped>0

 select sum(shipped) from ord_list a (NOLOCK), orders b (NOLOCK)
where a.order_no = b.order_no
and a.order_ext = b.ext
and b.type = 'I'
and a.part_no = 'BCUGOBR05317'
and b.date_shipped is not null
		and (datepart (year,b.date_shipped)) <> (select datepart (year,getdate()))

*/

GO
