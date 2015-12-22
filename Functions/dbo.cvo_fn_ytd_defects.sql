SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE FUNCTION [dbo].[cvo_fn_ytd_defects] (@part_no varchar(30))  
RETURNS decimal (20,8) AS  
BEGIN 

-- tag 062612 - updates for excluding credit/rebills from returns percentage

	DECLARE @ytd_defects decimal (20,8)
	
	-- set initial list to empty
	SELECT @ytd_defects = 0

--@ytd_returns
				select @ytd_defects =	(select sum (ISNULL(a.cr_shipped,0))
						from ord_list a (NOLOCK)
								inner join orders_all b (NOLOCK) 
						on 	(a.order_no = b.order_no
									and a.order_ext = b.ext)
						where a.part_no = @part_no
								AND left(a.RETURN_CODE,2) = '04' -- Only Warranty returns
								and b.type = 'C'
								and datepart (year,b.date_shipped) = datepart (year,getdate()))

	RETURN @ytd_defects
END

-- 

-- select dbo.cvo_fn_ytd_defects ('ETTURGRN5314') 






GO
