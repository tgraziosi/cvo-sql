SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_scm_pb_get_dw_orders_comm]	@order_no int, 
												@order_ext int 
AS
BEGIN

	SELECT  dbo.ord_rep.order_no ,           
			dbo.ord_rep.order_ext ,           
			dbo.ord_rep.salesperson ,           
			dbo.ord_rep.sales_comm ,           
			dbo.ord_rep.note ,          
			dbo.arsalesp.salesperson_name ,           
			dbo.ord_rep.percent_flag ,           
			dbo.ord_rep.exclusive_flag ,           
			dbo.ord_rep.split_flag ,           
			dbo.ord_rep.display_line  
	FROM	dbo.ord_rep (NOLOCK)
	LEFT OUTER JOIN dbo.arsalesp (NOLOCK) 
	ON		dbo.ord_rep.salesperson = dbo.arsalesp.salesperson_code     
	WHERE	(dbo.ord_rep.order_no = @order_no )
	AND		(dbo.ord_rep.order_ext = @order_ext)
END   

GO
GRANT EXECUTE ON  [dbo].[cvo_scm_pb_get_dw_orders_comm] TO [public]
GO
