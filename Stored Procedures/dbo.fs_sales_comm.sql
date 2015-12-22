SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sales_comm] @bdate datetime, @edate datetime  AS 
BEGIN

  begin tran
  delete sales_comm where status='N'
  commit tran
  begin tran
  
  insert sales_comm (salesperson, invoice_no, line_no, order_no, order_ext,                      
			cust_code, part_no, shipped, price_type, price,                          
			comm_type, sales_comm, rep_percnt, date_shipped,                   
			invoice_date, status, who_entered, date_entered,                   
			part_type)       
  select r.salesperson,o.invoice_no,x.line_no,o.order_no,o.ext,
	o.cust_code,x.part_no,(x.shipped - x.cr_shipped),
	x.price_type,x.price,i.comm_type,x.sales_comm,
	r.sales_comm,o.date_shipped,o.invoice_date,'N','SYSTEM',getdate(), x.part_type
	from orders_all o
	join ord_rep r (nolock) on r.order_no = o.order_no and r.order_ext = o.ext
	join ord_list x (nolock) on x.order_no = o.order_no and x.order_ext = o.ext and x.part_type='P'
	left outer join inv_master i (nolock) on x.part_no  =i.part_no
	where o.status>='S' and o.status<'V' and o.invoice_date>=@bdate and o.invoice_date<=@edate 
  update sales_comm set sales_comm=c.rate
	from comm_type c
	where sales_comm.comm_type=c.kys and status='N' and price_type<>'Q' and 
              sales_comm.sales_comm=0
  
  insert sales_comm (salesperson, invoice_no, line_no, order_no, order_ext,                      
			cust_code, part_no, shipped, price_type, price,                          
			comm_type, sales_comm, rep_percnt, date_shipped,                   
			invoice_date, status, who_entered, date_entered,                   
			part_type)       
  select r.salesperson,o.invoice_no,x.line_no,o.order_no,o.ext,
	o.cust_code,x.part_no,(x.shipped - x.cr_shipped),
	x.price_type,x.price,null,x.sales_comm,
	r.sales_comm,o.date_shipped,o.invoice_date,'N','SYSTEM',getdate(), x.part_type
	from orders_all o, ord_rep r, ord_list x
	where (o.order_no=x.order_no and o.order_no=r.order_no) and
	(o.ext=x.order_ext and o.ext=r.order_ext) and
	o.status>='S' and o.status<'V' and
	o.invoice_date>=@bdate and o.invoice_date<=@edate and x.part_type<>'P'
  commit tran
END

GO
GRANT EXECUTE ON  [dbo].[fs_sales_comm] TO [public]
GO
