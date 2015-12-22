SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[cvo_fn_ytd_sales] (@part_no varchar(30))  
RETURNS decimal (20,8) AS  
BEGIN 


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
								where a.part_no = @part_no
										and b.type = 'I'
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
