SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create FUNCTION [dbo].[cvo_fn_ytd_RETURNS] (@part_no varchar(30))  
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
								and b.date_shipped is not null
								and datepart (year,b.date_shipped) = datepart (year,getdate()))


	--END --IF
	RETURN @ytd_returns
END
GO
