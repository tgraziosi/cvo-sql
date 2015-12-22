SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adtrx_vw] as

select 
	xfer_no ,
 	from_loc , 
	to_loc , 
	rec_no, 	
	carrier = routing , 	
	freight_type, 
	freight, 
	date_entered ,
 	date_req_ship = req_ship_date ,
 date_sch_ship = sch_ship_date , 
 date_shipped , 
	status , 
	
	status_desc = 
		CASE status
			WHEN 'O' THEN 'Open'
			WHEN 'N' THEN 'New'
			WHEN 'P' THEN 'Open/Picked'
			WHEN 'Q' THEN 'Open/Printed'
			WHEN 'R' THEN 'Shipped'
			WHEN 'S' THEN 'Shipped/Received'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 

 	who_entered ,
	attention,

	x_freight = freight, 
	x_date_entered = ((datediff(day, '01/01/1900', date_entered) + 693596)) + (datepart(hh,date_entered)*.01 + datepart(mi,date_entered)*.0001 + datepart(ss,date_entered)*.000001),
 	x_date_req_ship = ((datediff(day, '01/01/1900', req_ship_date) + 693596)) + (datepart(hh,req_ship_date)*.01 + datepart(mi,req_ship_date)*.0001 + datepart(ss,req_ship_date)*.000001),
 	x_date_sch_ship = ((datediff(day, '01/01/1900', sch_ship_date) + 693596)) + (datepart(hh,sch_ship_date)*.01 + datepart(mi,sch_ship_date)*.0001 + datepart(ss,sch_ship_date)*.000001),
 	x_date_shipped = ((datediff(day, '01/01/1900', date_shipped) + 693596)) + (datepart(hh,date_shipped)*.01 + datepart(mi,date_shipped)*.0001 + datepart(ss,date_shipped)*.000001)

 
from xfers_all

 
GO
GRANT REFERENCES ON  [dbo].[adtrx_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adtrx_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adtrx_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adtrx_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adtrx_vw] TO [public]
GO
