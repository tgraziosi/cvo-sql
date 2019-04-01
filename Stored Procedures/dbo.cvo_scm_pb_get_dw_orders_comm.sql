SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 07/11/2018 - #1502 Additional Salesperson  
-- v1.1 CB 13/03/2019 - Add fields
CREATE PROC [dbo].[cvo_scm_pb_get_dw_orders_comm] @order_no int,   
											 @order_ext int   
AS  
BEGIN  
  
	SELECT	dbo.ord_rep.order_no ,             
			dbo.ord_rep.order_ext ,             
			dbo.ord_rep.salesperson ,             
			dbo.ord_rep.sales_comm ,             
			dbo.ord_rep.note ,            
			dbo.arsalesp.salesperson_name ,             
			dbo.ord_rep.percent_flag ,             
			dbo.ord_rep.exclusive_flag ,             
			dbo.ord_rep.split_flag ,             
			dbo.ord_rep.display_line,
    		dbo.ord_rep.primary_rep,
			dbo.ord_rep.include_rx,
			dbo.ord_rep.brand,
			dbo.ord_rep.brand_split,
			dbo.ord_rep.brand_excl,
			dbo.ord_rep.commission,
			dbo.ord_rep.brand_exclude,
			dbo.ord_rep.promo_id,
			dbo.ord_rep.rx_only, 
			dbo.ord_rep.startdate,
			dbo.ord_rep.enddate
	FROM	dbo.ord_rep (NOLOCK)  
	LEFT OUTER JOIN dbo.arsalesp (NOLOCK)   
	ON		dbo.ord_rep.salesperson = dbo.arsalesp.salesperson_code       
	WHERE	(dbo.ord_rep.order_no = @order_no )  
	AND		(dbo.ord_rep.order_ext = @order_ext)  
END     
GO
GRANT EXECUTE ON  [dbo].[cvo_scm_pb_get_dw_orders_comm] TO [public]
GO
