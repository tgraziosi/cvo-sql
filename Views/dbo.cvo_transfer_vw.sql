SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_transfer_vw] 
as 
select x.xfer_no, 
x.status, 
s.status_desc,
x.from_loc, 
x.to_loc, 
x.attention,
x.date_shipped, 
x.date_entered, 
x.date_printed, 
x.date_recvd, 
x.who_picked, 
x.who_recvd,
(select sum(ordered) from xfer_list where x.xfer_no = xfer_no) qty_ordered,
(select sum(ordered*(cost+ovhd_dolrs+util_dolrs)) from xfer_list where x.xfer_no = xfer_no) extcost_ordered,
(select sum(shipped) from xfer_list where x.xfer_no = xfer_no) qty_shipped,
(select sum(shipped*(cost+ovhd_dolrs+util_dolrs)) from xfer_list where x.xfer_no = xfer_no) extcost_shipped,
(select sum(qty_rcvd) from xfer_list where x.xfer_no = xfer_no) qty_recv,
(select sum(qty_rcvd*(cost+ovhd_dolrs+util_dolrs)) from xfer_list where x.xfer_no = xfer_no) extcost_recvd
from xfers x (nolock), cc_ord_status s (nolock)
where x.status <> 'v'
and x.status = s.status_code










GO
GRANT CONTROL ON  [dbo].[cvo_transfer_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_transfer_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_transfer_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_transfer_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_transfer_vw] TO [public]
GO
