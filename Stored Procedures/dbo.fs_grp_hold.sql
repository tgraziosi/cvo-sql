SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_grp_hold] @stat char(1), @reason varchar(10)='%' AS

create table #thold ( load_no int,
 hold_who_nm varchar(20), hold_dt datetime, orig_stat char(1),
order_no int, order_ext int, cust_code varchar(10),
		      customer_name varchar(40) NULL, total_order_amt decimal(20,8),
		      total_order_cost decimal(20,8), ship_to_no varchar(10) NULL,
		      ship_to_name varchar(40) NULL, salesperson varchar(10) NULL,
		      who_entered varchar(20) NULL, date_entered datetime NULL,
		      curr_factor decimal(20,8), printed char(1),
		      status char(1), reason varchar(10) null, blanket char(1),		-- mls 5/18/00 SCR 22908
		      multiple char(1), rcd_type int , curr_key varchar(10),
			  tax_valid_ind int) 						-- skk 5/19/00 mshipto						

if @stat = 'H' begin 
	INSERT  #thold
select l.load_no, l.user_hold_who_nm, l.user_hold_dt, l.orig_status,
o.order_no, o.ext, o.cust_code, null, 0, 0,
		o.ship_to, o.ship_to_name, o.salesperson, o.who_entered, 
		o.date_entered, o.curr_factor, o.printed, o.status, l.hold_reason, o.blanket,
		o.multiple_flag	,1, o.curr_key,isnull(o.tax_valid_ind,1)		-- skk 05/19/00 mshipto
	FROM    orders_all o, load_master l
	WHERE   o.load_no = l.load_no and l.status = 'H' and
		(@reason = '%' or l.hold_reason like @reason)
end

if @stat = 'C' begin 
	INSERT  #thold
select l.load_no, l.credit_hold_who_nm, l.credit_hold_dt, l.orig_status,
  o.order_no, o.ext, o.cust_code, null, 0, 0,
		o.ship_to, o.ship_to_name, o.salesperson, o.who_entered, 
		o.date_entered, o.curr_factor, o.printed, o.status, '', o.blanket, 
		o.multiple_flag	, 1, o.curr_key,						-- skk 05/19/00 mshipto
		isnull(o.tax_valid_ind,1) tax_valid_ind
	FROM    orders_all o, load_master l
	WHERE   o.load_no = l.load_no and l.status = 'C'
end

UPDATE #thold set customer_name=adm_cust_all.customer_name
FROM   adm_cust_all (NOLOCK)
WHERE  adm_cust_all.customer_code = #thold.cust_code

UPDATE #thold 
SET    total_order_amt=isnull( (select sum( ordered * price ) from ord_list (NOLOCK)
				where ord_list.order_no=#thold.order_no and ord_list.order_ext=#thold.order_ext), 0 )

UPDATE #thold 
SET    total_order_cost=isnull( (select sum( ordered * ((std_cost+std_direct_dolrs+std_ovhd_dolrs+std_util_dolrs)* ord_list.conv_factor) ) 
				from ord_list (NOLOCK)
				where ord_list.order_no=#thold.order_no and ord_list.order_ext=#thold.order_ext and
				(ord_list.part_type='M' or ord_list.part_type='J') ), 0 )

UPDATE #thold 
SET    total_order_cost=isnull( (select sum( ordered * ((i.std_cost+i.std_direct_dolrs+i.std_ovhd_dolrs+i.std_util_dolrs) * ord_list.conv_factor) ) 
				from ord_list (NOLOCK), inventory i (NOLOCK)
				where ord_list.order_no=#thold.order_no and ord_list.order_ext=#thold.order_ext and
				ord_list.part_no=i.part_no and ord_list.location=i.location and
				ord_list.part_type<>'M' and ord_list.part_type<>'J'), 0 )


INSERT  #thold
select distinct load_no, hold_who_nm, hold_dt, '',
0, 0, '', null, 0, 0,
		'', '', '', '', 
		NULL, 0, '', orig_stat, reason, '',
		''	,0, '', min(tax_valid_ind)							-- skk 05/19/00 mshipto
FROM    #thold
group by load_no, hold_who_nm, hold_dt, orig_stat, reason

select  load_no, hold_who_nm, hold_dt,
	order_no, order_ext, cust_code,
	customer_name, total_order_amt,
	total_order_cost, ship_to_no,
	ship_to_name, salesperson,
	who_entered, date_entered,
	curr_factor, 'H',
	status, reason, blanket, multiple,						-- skk 05/19/00 mshipto
	@stat, @reason, rcd_type, curr_key, space(100), space(1), 0, 0, 0, 0, tax_valid_ind
from #thold
order by load_no, rcd_type, order_no, order_ext


GO
GRANT EXECUTE ON  [dbo].[fs_grp_hold] TO [public]
GO
