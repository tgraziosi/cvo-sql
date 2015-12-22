SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cvo_asn_sscc_vw] as 
select 
sh.status,
sh.asn,
ch.carton_no,
o.ship_to_name,
o.ship_to_add_1,
o.ship_to_add_2,
o.ship_to_city,
o.ship_to_state,
o.ship_to_zip,
sh.carrier_code,
isnull((select top 1 description from cvo_carriers where carrier = sh.carrier_code),'') carrier_name,
sh.pro_number,
ch.tracking_no,
sd.cust_po_no,
sd.department_no,
sd.purchaser_code,
sd.reference_no, -- store?
ch.epc_tag -- sscc number
from tdc_EDI_shipment_header sh
inner join tdc_EDI_shipment_detail sd on sd.asn = sh.asn
inner join tdc_edi_carton_header ch on ch.asn=sh.asn
--inner join tdc_Edi_carton_detail cd on cd.asn=sh.asn and cd.carton_no = ch.carton_no
--inner join tdc_edi_ord_list ol on ol.asn = cd.asn and ol.order_no = cd.order_no and ol.line_no = cd.line_no and ol.part_no = cd.part_no
inner join tdc_carton_tx ct on ct.carton_no = ch.carton_no
inner join orders o on o.order_no = ct.order_no and o.ext = ct.order_Ext 
where o.order_no = sd.order_no
GO
GRANT REFERENCES ON  [dbo].[cvo_asn_sscc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_asn_sscc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_asn_sscc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_asn_sscc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_asn_sscc_vw] TO [public]
GO
