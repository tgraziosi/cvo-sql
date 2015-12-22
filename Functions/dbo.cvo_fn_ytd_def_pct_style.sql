SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[cvo_fn_ytd_def_pct_style] 
(@category varchar(10), @style varchar(10), @type_code varchar(10))  
RETURNS decimal (20,8) AS  
BEGIN 
--i.category, ia.field_2,
-- tag 062612 - updates for excluding credit/rebills from returns percentage

	DECLARE @ytd_rcts decimal (20,8)--, @order_no int, @order_ext int
	DECLARE @ytd_returns decimal (20,8)
	DECLARE @ytd_defect_percent decimal (20,8)
	
	-- set initial list to empty
	SELECT @ytd_rcts = 0
	SELECT @ytd_returns = 0
	SELECT @ytd_defect_percent = 0

--@ytd_rcts

				select @ytd_rcts =	(select sum (ISNULL(a.quantity,0))
						from receipts a (NOLOCK) 
						inner join inv_master i (nolock) on a.part_no = i.part_no
						inner join inv_master_add ia (nolock) on a.part_no = ia.part_no
						where i.category = @category and ia.field_2 = @style and i.type_code = @type_code
						and datepart (year,a.recv_date) = datepart(year,getdate()))

--@ytd_returns
				select @ytd_returns =	(select sum (ISNULL(a.cr_shipped,0))
							from ord_list a (NOLOCK)
								inner join orders_all b (NOLOCK) 
							on 	(a.order_no = b.order_no
									and a.order_ext = b.ext)
							inner join inv_master i (nolock) on a.part_no = i.part_no
							inner join inv_master_add ia (nolock) on a.part_no = ia.part_no
							where i.category = @category and ia.field_2 = @style and i.type_code = @type_code
								AND left(a.RETURN_CODE,2) = '04' -- Only Warranty returns
								and b.type = 'C'
								and b.date_shipped is not null
								and datepart (year,b.date_shipped) = datepart (year,getdate()))

--@ytd_defect_percent

			if @ytd_rcts = 0 return 0

				select @ytd_defect_percent = (@ytd_returns / @ytd_rcts)

	RETURN @ytd_defect_percent
END
-- 
-- select dbo.cvo_fn_ytd_defect_percent ('ETTURGRN5314') 









GO
