SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CT 08/11/12 - Add auopack and autoship columns

CREATE view [dbo].[xfers] as
select
x.timestamp,
x.xfer_no,
x.from_loc,
x.to_loc,
x.req_ship_date,
x.sch_ship_date,
x.date_shipped,
x.date_entered,
x.req_no,
x.who_entered,
x.status,
x.attention,
x.phone,
x.routing,
x.special_instr,
x.fob,
x.freight,
x.printed,
x.label_no,
x.no_cartons,
x.who_shipped,
x.date_printed,
x.who_picked,
x.to_loc_name,
x.to_loc_addr1,
x.to_loc_addr2,
x.to_loc_addr3,
x.to_loc_addr4,
x.to_loc_addr5,
x.no_pallets,
x.shipper_no,
x.shipper_name,
x.shipper_addr1,
x.shipper_addr2,
x.shipper_city,
x.shipper_state,
x.shipper_zip,
x.cust_code,
x.freight_type,
x.note,
x.rec_no,
x.who_recvd,
x.date_recvd,
x.pick_ctrl_num,
x.from_organization_id,
x.to_organization_id,
x.proc_po_no,
x.back_ord_flag back_ord_flag,
orig_xfer_no,
orig_xfer_ext,
x.autopack, -- v1.1
x.autoship	-- v1.1
from xfers_all x (nolock),
locations f (nolock), locations t (nolock)
where x.from_loc = f.location and x.to_loc = t.location
GO
GRANT REFERENCES ON  [dbo].[xfers] TO [public]
GO
GRANT SELECT ON  [dbo].[xfers] TO [public]
GO
GRANT INSERT ON  [dbo].[xfers] TO [public]
GO
GRANT DELETE ON  [dbo].[xfers] TO [public]
GO
GRANT UPDATE ON  [dbo].[xfers] TO [public]
GO
