SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[cvo_fn_ytd_rcts] (@part_no varchar(30), @yyear int)
RETURNS decimal (20,8) AS  
BEGIN 


	DECLARE @ytd_rcts decimal (20,8)--, @order_no int, @order_ext int

	
	-- set initial list to empty
	SELECT @ytd_rcts = 0

	select @ytd_rcts =	(select sum (ISNULL(a.quantity,0))
			from receipts a (NOLOCK) 
			where a.part_no = @part_no
			and datepart (year,a.recv_date) = @yyear )
			
	RETURN @ytd_rcts
END

GO
