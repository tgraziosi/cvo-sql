SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/** 4/9/2012 - added salesperson, territory and amount **/
/* 4/19/2012 - tag - added open picks with no carton data */

CREATE view [dbo].[cvo_carton_recon_vw] as
select
c.order_no,
c.order_ext,
o.user_category as type,
o.status as order_status,
c.carton_no,
c.status as carton_status,
case when m.pack_no is null then 'NO' else 'YES' end as is_Mast_pack,
isnull(m.pack_no,0) as pack_no,
c.station_id,
c.order_type,
c.carrier_code,
o.sch_ship_date,
c.date_shipped,
c.cs_tracking_no,
c.cust_po,
c.cust_code,
c.ship_to_no,
c.name,
c.address1,
c.address2,
c.address3,
c.city,
c.state,
c.zip,
c.void,
c.last_modified_date,
c.modified_by, 
o.salesperson,
o.ship_to_region AS Territory,
o.total_amt_order - o.tot_ord_disc as total_amt_order

from tdc_carton_tx c (nolock)
left outer join tdc_master_pack_ctn_tbl m (nolock) on m.carton_no = c.carton_no
--where status in ('F','C') 
--and (date_shipped < convert(varchar(10),getdate(),101) or date_shipped is null)
join orders_all o (nolock) on o.order_no = c.order_no and o.ext = c.order_ext
--where o.status < 'r'

union all

select
o.order_no,
o.ext,
o.user_category as type,
o.status as order_status,
'' as carton_no,
'O' as carton_status,
'NO' as is_Mast_pack,
0  as pack_no,
'' as station_id,
'S' as order_type,
o.routing as carrier_code,
o.sch_ship_date,
o.date_shipped,
'' as cs_tracking_no,
o.cust_po,
o.cust_code,
o.ship_to as ship_to_no,
o.ship_to_name as name,
o.ship_to_add_1 as address1,
o.ship_to_add_2 as address2,
o.ship_to_add_3 as address3,
o.ship_to_city as city,
o.ship_to_state as state,
o.ship_to_zip as zip,
'' as void,
o.date_printed as last_modified_date,
'' as modified_by, 
o.salesperson,
o.ship_to_region AS Territory,
o.total_amt_order - o.tot_ord_disc as total_amt_order

from orders_all o (nolock)
where not exists (select * from tdc_carton_tx c (nolock) 
	where c.order_no = o.order_no and c.order_ext = o.ext)
and o.status = 'P'
GO
GRANT REFERENCES ON  [dbo].[cvo_carton_recon_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_carton_recon_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_carton_recon_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_carton_recon_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_carton_recon_vw] TO [public]
GO
