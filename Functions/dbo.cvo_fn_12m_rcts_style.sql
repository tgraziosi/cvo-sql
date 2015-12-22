SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

------

CREATE FUNCTION [dbo].[cvo_fn_12m_rcts_style]
(@category varchar(10), @style varchar(10), @type_code varchar(10))  
RETURNS decimal (20,8) AS  
BEGIN 


	DECLARE @12m_rcts decimal (20,8)--, @order_no int, @order_ext int

	
	-- set initial list to empty
	SELECT @12m_rcts = 0

	--IF (select count(order_no) from orders_invoice where trx_ctrl_num = @trx_ctrl_num)>0
	--BEGIN

				select @12m_rcts =	(select sum (ISNULL(a.quantity,0))
						from receipts a (NOLOCK) 
						inner join inv_master i (nolock) on a.part_no = i.part_no
						inner join inv_master_add ia (nolock) on a.part_no = ia.part_no
						where i.category = @category and ia.field_2 = @style
						and i.type_code = @type_code
						and a.recv_date between dateadd(m,-12,getdate()) and getdate())

	--END --IF
	RETURN @12m_rcts
END
GO
