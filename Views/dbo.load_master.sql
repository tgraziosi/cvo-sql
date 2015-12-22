SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[load_master]
AS
select 
m.load_no,
m.location,
m.truck_no,
m.trailer_no,
m.driver_key,
m.driver_name,
m.pro_number,
m.routing,
m.stop_count,
m.total_miles,
m.sch_ship_date,
m.date_shipped,
m.status,
m.orig_status,
m.hold_reason,
m.contact_name,
m.contact_phone,
m.invoice_type,
m.create_who_nm,
m.user_hold_who_nm,
m.credit_hold_who_nm,
m.picked_who_nm,
m.shipped_who_nm,
m.posted_who_nm,
m.create_dt,
m.process_ctrl_num,
m.user_hold_dt,
m.credit_hold_dt,
m.picked_dt,
m.posted_dt,
m.organization_id
from load_master_all m
GO
GRANT SELECT ON  [dbo].[load_master] TO [public]
GO
GRANT INSERT ON  [dbo].[load_master] TO [public]
GO
GRANT DELETE ON  [dbo].[load_master] TO [public]
GO
GRANT UPDATE ON  [dbo].[load_master] TO [public]
GO
