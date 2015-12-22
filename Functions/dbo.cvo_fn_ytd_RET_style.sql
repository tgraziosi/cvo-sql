SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE FUNCTION [dbo].[cvo_fn_ytd_RET_style] 
(@category varchar(10), @style varchar(10), @type_code varchar(10) )  
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
						inner join inv_master i (nolock) on a.part_no = i.part_no
						inner Join inv_master_add ia (nolock) on a.part_no = ia.part_no
						where i.category = @category and ia.field_2 = @style and i.type_code = @type_code
								AND left(a.RETURN_CODE,2)<>'05' -- EXCLUDE CREDIT/REBILLS
								and b.type = 'C'
								and b.date_shipped is not null
								and datepart (year,b.date_shipped) = datepart (year,getdate()))

	--END --IF
	RETURN @ytd_returns
END


GO
