SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[cvo_fn_ytd_defect_pct_cat] (@part_no varchar(30), @user_category varchar(2), @year int)  
RETURNS decimal (20,8) AS  
BEGIN 

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
						where a.part_no = @part_no
						and datepart (year,a.recv_date) = @year )

--@ytd_returns
				select @ytd_returns =	(select sum (ISNULL(a.cr_shipped,0))
							from ord_list a (NOLOCK)
								inner join orders_all b (NOLOCK) 
							on 	(a.order_no = b.order_no
									and a.order_ext = b.ext)
							where a.part_no = @part_no
								AND left(a.RETURN_CODE,2) = '04' -- Only Warranty returns
								and b.type = 'C'
								and b.date_shipped is not null
								and left(b.user_category,2) = @user_category
								and right(b.user_category,2) <>'RB'
								and datepart (year,b.date_shipped) = @year )

--@ytd_defect_percent

			if @ytd_rcts = 0 return 0

				select @ytd_defect_percent = (@ytd_returns / @ytd_rcts)


	RETURN @ytd_defect_percent
END

-- 

-- select dbo.cvo_fn_ytd_defect_percent ('ETTURGRN5314') 








GO
