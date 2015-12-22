SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 16/10/2012 - Return credit returns on user hold 

/* - this was copied from fs_csv_hold - below are version comments for that code
-- vx.0 CB 29/09/2011 - Prior hold functionality
-- vx.1 CB 29/06/2012 - Exclude promo holds - Remove
*/

CREATE PROCEDURE [dbo].[cvo_fs_csv_hold] @cust varchar(10), @stat char(1), @reason varchar(10)='%' AS

set nocount on										-- mls 9/25/03 SCR 31931
create table #thold ( order_no int, order_ext int, cust_code varchar(10),
		      customer_name varchar(40) NULL, total_order_amt decimal(20,8),
		      total_order_cost decimal(20,8), ship_to_no varchar(10) NULL,
		      ship_to_name varchar(40) NULL, salesperson varchar(10) NULL,
		      who_entered varchar(20) NULL, date_entered datetime NULL,
		      curr_factor decimal(20,8), printed char(1),
		      status char(1), reason varchar(10) null, blanket char(1),		-- mls 5/18/00 SCR 22908
		      multiple char(1) --) 						-- skk 5/19/00 mshipto						
			  ,user_hold varchar(10), user_hold_desc varchar(40)) -- vx.0

create index #t1 on #thold (cust_code, ship_to_name, order_no, order_ext)		-- mls 9/25/03 SCR 31931

-- Credit returns are only user hold (stat = A) , so hard code it
SET @stat = 'A'

if @stat = 'A' begin 
	INSERT  #thold
	SELECT  order_no, ext, cust_code, null, 0, 0,
		ship_to, ship_to_name, salesperson, who_entered, 
		date_entered, curr_factor, printed, o.status, hold_reason, blanket,
		multiple_flag								-- skk 05/19/00 mshipto
		,'','' -- vx.0
	FROM    orders_entry_vw o (nolock), adm_cust c (nolock)
	WHERE   o.status = 'A' and cust_code like @cust and
                o.cust_code = c.customer_code and
		(@reason = '%' or hold_reason like @reason)
			AND o.[type] = 'C' 
end

/*
if @stat = 'C' begin 
	INSERT  #thold
	SELECT  order_no, ext, cust_code, null, 0, 0,
		ship_to, ship_to_name, salesperson, who_entered, 
		date_entered, curr_factor, printed, o.status, '', blanket, 
		multiple_flag								-- skk 05/19/00 mshipto
		, hold_reason, '' -- vx.0
	FROM    orders_entry_vw o (nolock), adm_cust c (nolock)
	WHERE   (o.status between 'B' and 'C') and 
                o.cust_code = c.customer_code and
		cust_code like @cust			-- mls 9/25/03 SCR 31931
end

if @stat = 'P' begin 
	INSERT  #thold
	SELECT  order_no, ext, cust_code, null, 0, 0,
		ship_to, ship_to_name, salesperson, who_entered, 
		date_entered, curr_factor, printed, o.status, '', blanket, 
		multiple_flag								-- skk 05/19/00 mshipto
		,'','' -- vx.0
	FROM    orders_entry_vw o (nolock), adm_cust c (nolock)
	WHERE   (o.status between 'B' and 'H') and 
                o.cust_code = c.customer_code and
		cust_code like @cust			-- mls 9/25/03 SCR 31931
          	and o.status in ('B','H')							-- mls 9/25/03 SCR 31931
end
*/

UPDATE #thold set customer_name=adm_cust.customer_name
FROM   adm_cust (NOLOCK)
WHERE  adm_cust.customer_code = #thold.cust_code

UPDATE #thold 
SET    total_order_amt=isnull( (select sum( cr_ordered * price ) from ord_list (NOLOCK)
				where ord_list.order_no=#thold.order_no and ord_list.order_ext=#thold.order_ext), 0 )

UPDATE #thold 
SET    total_order_cost=isnull( (select sum( cr_ordered * ((std_cost+std_direct_dolrs+std_ovhd_dolrs+std_util_dolrs)* ord_list.conv_factor) ) 
				from ord_list (NOLOCK)
				where ord_list.order_no=#thold.order_no and ord_list.order_ext=#thold.order_ext and
				(ord_list.part_type='M' or ord_list.part_type='J') ), 0 )

UPDATE #thold 
SET    total_order_cost=isnull( (select sum( cr_ordered * ((i.std_cost+i.std_direct_dolrs+i.std_ovhd_dolrs+i.std_util_dolrs) * ord_list.conv_factor) ) 
				from ord_list (NOLOCK), inv_list i (NOLOCK)		-- mls 9/25/03 SCR 31931
				where ord_list.order_no=#thold.order_no and ord_list.order_ext=#thold.order_ext and
				ord_list.part_no=i.part_no and ord_list.location=i.location and
				ord_list.part_type<>'M' and ord_list.part_type<>'J'), 0 )


-- vx.0
UPDATE	#thold
SET		user_hold_desc = b.hold_reason
FROM	#thold a
JOIN	cvo_crhold b (NOLOCK)
on		a.user_hold = b.hold_code


select  order_no, order_ext, cust_code,
	customer_name, total_order_amt,
	total_order_cost, ship_to_no,
	ship_to_name, salesperson,
	who_entered, date_entered,
	curr_factor, printed,
	status, reason, blanket, multiple,						-- skk 05/19/00 mshipto
	@cust, @stat, @reason, user_hold_desc
from #thold
order by cust_code, ship_to_name, order_no, order_ext
GO
GRANT EXECUTE ON  [dbo].[cvo_fs_csv_hold] TO [public]
GO
