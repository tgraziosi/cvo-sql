SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [dbo].[cvo_fn_ytd_rcts_style]
(@category varchar(10), @style varchar(10), @type_code varchar(10))  
RETURNS decimal (20,8) AS  
BEGIN 


	DECLARE @ytd_rcts decimal (20,8)--, @order_no int, @order_ext int

	
	-- set initial list to empty
	SELECT @ytd_rcts = 0

	--IF (select count(order_no) from orders_invoice where trx_ctrl_num = @trx_ctrl_num)>0
	--BEGIN

				select @ytd_rcts =	(select sum (ISNULL(a.quantity,0))
						from receipts a (NOLOCK) 
						inner join inv_master i (nolock) on a.part_no = i.part_no
						inner join inv_master_add ia (nolock) on a.part_no = ia.part_no
						where i.category = @category and ia.field_2 = @style
						and i.type_code = @type_code
						and datepart (year,a.recv_date) = datepart(year,getdate()))

	--END --IF
	RETURN @ytd_rcts
END

-- 

-- select dbo.cvo_fn_ytd_rcts ('ETTURGRN5314') 

--select sum (ISNULL(a.quantity,0))
--								from receipts a (NOLOCK) 
--								where a.part_no like 'ETTURGRN5314'
--								and datepart (year,a.recv_date) = datepart (year,getdate())
--
--
--select * From receipts where part_no = 'ETTURGRN5314'




GO
