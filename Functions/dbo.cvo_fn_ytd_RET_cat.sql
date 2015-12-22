SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [dbo].[cvo_fn_ytd_RET_cat] (@part_no varchar(30), @user_category varchar(2), @year int)  
RETURNS decimal (20,8) AS  
BEGIN 


	DECLARE @ytd_returns decimal (20,8)--, @order_no int, @order_ext int

	
	-- set initial list to empty
	SELECT @ytd_returns = 0

	--IF (select count(order_no) from orders_invoice where trx_ctrl_num = @trx_ctrl_num)>0
	--BEGIN


			select @ytd_returns =	(select sum (ISNULL(a.cr_shipped,0))
							from ord_list a (NOLOCK)
								inner join orders_all b (NOLOCK) 
							on 	(a.order_no = b.order_no
									and a.order_ext = b.ext)
							where a.part_no = @part_no
								and b.type = 'C'
								AND left(a.RETURN_CODE,2)<>'05' -- EXCLUDE CREDIT/REBILLS
								and left(b.user_category,2) = @user_category
								and right(b.user_category,2) <>'RB'
								and b.date_shipped is not null
								and datepart (year,b.date_shipped) = @year )


	--END --IF
	RETURN @ytd_returns
END

GO
