SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_load] @load_no varchar(16) = '', 
@range varchar(8000) = '0=0'
as
begin
create table #rpt_load(
 m_load_no int NULL, m_location varchar(10) NULL, m_truck_no varchar(10) NULL,
m_trailer_no varchar(10) NULL, m_driver_key varchar(10) NULL, m_driver_name varchar(50) NULL,
m_pro_number varchar(15) NULL, m_routing varchar(10) NULL, m_stop_count int NULL, m_total_miles int NULL,
m_sch_ship_date datetime NULL, m_date_shipped datetime NULL, m_status char(1) NULL, m_orig_status char(1) NULL,
m_hold_reason varchar(10) NULL, m_contact_name varchar(40) NULL, m_contact_phone varchar(20) NULL,
m_invoice_type int NULL, m_create_who_nm varchar(20) NULL, m_user_hold_who_nm varchar(20) NULL,
m_credit_hold_who_nm varchar(20) NULL, m_picked_who_nm varchar(20) NULL, m_shipped_who_nm varchar(20) NULL,
m_posted_who_nm varchar(20) NULL, m_create_dt datetime NULL, m_process_ctrl_num varchar(32) NULL,
m_user_hold_dt datetime NULL, m_credit_hold_dt datetime NULL, m_picked_dt datetime NULL,
m_posted_dt datetime NULL,
l_load_no int NULL, l_seq_no int NULL, l_order_no int NULL, l_order_ext int NULL, l_order_list_row_id int NULL,
l_freight decimal(20,8) NULL, l_date_shipped datetime NULL,
o_ship_to_name varchar(40), o_ship_to_add_1 varchar(40),
o_ship_to_add_2 varchar(40), o_ship_to_add_3 varchar(40), o_ship_to_add_4 varchar(40),
o_ship_to_add_5 varchar(40), o_ship_to_city varchar(40), o_ship_to_state varchar(40),
o_ship_to_zip varchar(10), o_ship_to_country varchar(40), o_ship_to_region varchar(10),
o_total_amt_order decimal(20,8) NULL,
o_freight decimal(20,8) NULL,
o_special_instr varchar(255) NULL,
o_phone varchar(40), masked_phone varchar(100) NULL
)

select @range = replace(@range,'"','''')

if @load_no != ''
begin
exec('
insert #rpt_load
SELECT m.load_no, m.location, m.truck_no, m.trailer_no, m.driver_key, m.driver_name,
	m.pro_number, m.routing, m.stop_count, m.total_miles, m.sch_ship_date, m.date_shipped,
	m.status, m.orig_status, m.hold_reason, m.contact_name, m.contact_phone, m.invoice_type,
	m.create_who_nm, m.user_hold_who_nm, m.credit_hold_who_nm, m.picked_who_nm, m.shipped_who_nm,
	m.posted_who_nm, m.create_dt, m.process_ctrl_num, m.user_hold_dt, m.credit_hold_dt,
	m.picked_dt, m.posted_dt,
	l.load_no, l.seq_no, l.order_no, l.order_ext, l.order_list_row_id, l.freight, l.date_shipped,
	o.ship_to_name , o.ship_to_add_1 ,
	o.ship_to_add_2 , o.ship_to_add_3 , o.ship_to_add_4 ,
	o.ship_to_add_5 , o.ship_to_city , o.ship_to_state ,
	o.ship_to_zip , o.ship_to_country , o.ship_to_region ,
	o.total_amt_order , o.freight , o.special_instr , o.phone ,
	''''
    FROM load_master_all m (nolock),   
         load_list l (nolock),   
         orders_all  o (nolock)
   WHERE ( m.load_no = l.load_no ) and  
         ( l.order_no = o.order_no ) and  
         ( l.order_ext = o.ext ) and  m.load_no = ''' + @load_no + '''')
end
else
begin
exec('
insert #rpt_load
SELECT distinct m.load_no, m.location, m.truck_no, m.trailer_no, m.driver_key, m.driver_name,
	m.pro_number, m.routing, m.stop_count, m.total_miles, m.sch_ship_date, m.date_shipped,
	m.status, m.orig_status, m.hold_reason, m.contact_name, m.contact_phone, m.invoice_type,
	m.create_who_nm, m.user_hold_who_nm, m.credit_hold_who_nm, m.picked_who_nm, m.shipped_who_nm,
	m.posted_who_nm, m.create_dt, m.process_ctrl_num, m.user_hold_dt, m.credit_hold_dt,
	m.picked_dt, m.posted_dt,
	ll.load_no, ll.seq_no, ll.order_no, ll.order_ext, ll.order_list_row_id, ll.freight, ll.date_shipped,
	o.ship_to_name , o.ship_to_add_1 ,
	o.ship_to_add_2 , o.ship_to_add_3 , o.ship_to_add_4 ,
	o.ship_to_add_5 , o.ship_to_city , o.ship_to_state ,
	o.ship_to_zip , o.ship_to_country , o.ship_to_region ,
	o.total_amt_order , o.freight , o.special_instr , o.phone ,
	''''
    FROM load_master m (nolock),   
         load_list ll (nolock),   
         orders_all  o (nolock), locations l (nolock), region_vw r (nolock)
   WHERE ( m.load_no = ll.load_no ) and  
      l.location = o.location and 
      l.organization_id = r.org_id and
         ( ll.order_no = o.order_no ) and  
         ( ll.order_ext = o.ext ) and  ' + @range)
end

declare @mask varchar(100), @phone varchar(50), @orig_phone varchar(50)
declare @pos int, @orig_mask varchar(100)

select @phone = isnull((select min(o_phone)
from #rpt_load where isnull(o_phone,'') != ''),NULL)

if @phone is not null
begin
  select @orig_mask = isnull((select mask from masktbl (nolock)
  where lower(mask_name) = 'phone number mask'),'(###) ###-#### Ext. ####')
  select @mask = replace(@mask,'!','#')
  select @mask = replace(@mask,'@','#')
  select @mask = replace(@mask,'?','#')
end

while @phone is not null
begin
  select @orig_phone = @phone,
    @mask = @orig_mask

  while @phone != ''
  begin
    select @pos = charindex('#',@mask)

    if @pos > 0
      select @mask = stuff(@mask,@pos,1,substring(@phone,1,1))
    else
      select @mask = @mask + substring(@phone,1,1)

    select @phone = ltrim(substring(@phone,2,100))
  end

  if @pos > 0
    select @mask = substring(@mask,1,@pos)

  update #rpt_load
  set masked_phone = @mask
  where o_phone = @orig_phone

  select @phone = isnull((select min(o_phone)
  from #rpt_load where isnull(o_phone,'') > @orig_phone),NULL)
end

select * from #rpt_load
order by m_load_no, l_seq_no
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_load] TO [public]
GO
