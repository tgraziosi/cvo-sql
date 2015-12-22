SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[scm_pb_dw_find_so_adv_search_sp] @order_no_start int, @order_no_end int,
@cust_code varchar(20), @ship_to varchar(20), @address varchar(255), @attention varchar(255),
@phone varchar(255), @cust_po varchar(255), @status varchar(3), @load_no int, @user_code varchar(255),
@back_ord_flag varchar(3), @location varchar(10), @req_ship_date_start datetime, @req_ship_date_end datetime,
@sch_ship_date_start datetime, @cancel_date_start datetime, @invoice_date_start datetime,
@sch_ship_date_end datetime, @cancel_date_end datetime, @invoice_date_end datetime,
@invoice_no int, @so_priority_code varchar(255), @user_category varchar(255), @price varchar(255),
@username varchar(255), @req_ship_date_all char(1), @sch_ship_date_all char(1), @cancel_date_all char(1),
@invoice_date_all char(1), @hold_flag char(1), @open_flag char(1), @shipped_flag char(1), @void_flag char(1),
@date_shipped_all char(1), @date_shipped_start datetime, @date_shipped_end datetime, @entered_date_all char(1),
@entered_date_start datetime, @entered_date_end datetime, @routing varchar(255), @fob varchar(255),
@forwarder_key varchar(255), @freight_to varchar(255), @freight_allow_type varchar(255), 
@salesperson varchar(255), @ship_to_region varchar(255), @posting_code varchar(255), @remit_key varchar(255),
@tax_id varchar(255), @terms_code varchar(255), @dest_zone_code varchar(255), @user_def_fld1 varchar(255),
 @user_def_fld2 varchar(255), @user_def_fld3 varchar(255), @user_def_fld4 varchar(255),
 @user_def_fld5 float, @user_def_fld6 float, @user_def_fld7 float, @user_def_fld8 float, 
 @user_def_fld9 int, @user_def_fld10 int, @user_def_fld11 int, @user_def_fld12 int
as 
begin

SELECT orders.order_no ,           
orders.ext, orders.cust_code, adm_cust.customer_name, orders.ship_to_name, orders.cust_po, orders.req_ship_date, 
orders.invoice_no, orders.status
FROM orders 
left outer join adm_cust (nolock) on ( orders.cust_code = adm_cust.customer_code) 
left outer join glcurr_vw (nolock) on ( orders.curr_key = glcurr_vw.currency_code) 
left outer join adm_shipto (nolock) on ( orders.cust_code = adm_shipto.customer_code) and
(orders.ship_to = adm_shipto.ship_to_code) 
left outer join load_master (nolock) on ( orders.load_no  = load_master.load_no) 
WHERE (@order_no_start = 0 or orders.order_no between @order_no_start and @order_no_end)
and (orders.type = 'I')
and (@cust_code = 'ALL' or orders.cust_code like @cust_code + '%')
and (@ship_to = 'ALL' or orders.ship_to like @ship_to + '%')
and (@address = 'ALL' or (orders.ship_to_add_1 like '%' + @address + '%' or
				orders.ship_to_add_2 like '%' + @address + '%' or
				orders.ship_to_add_3 like '%' + @address + '%' or
				orders.ship_to_add_4 like '%' + @address + '%' or
				orders.ship_to_add_5 like '%' + @address + '%'))
and (@attention = 'ALL' or orders.attention like @attention + '%')
and (@phone = 'ALL' or orders.phone like @phone + '%')
and (@cust_po = 'ALL' or orders.cust_po like @cust_po + '%')
and (@status = 'ALL' or (@hold_flag = 'Y' AND orders.status = 'H')
		     or (@open_flag = 'Y' AND orders.status in ('N', 'P', 'Q'))
			or (@shipped_flag = 'Y' AND orders.status in ('R', 'S', 'T'))
			or (@void_flag = 'Y' AND orders.status = 'V'))
and (@so_priority_code = 'ALL' or orders.so_priority_code like @so_priority_code + '%' )
and (@user_category = 'ALL' or orders.user_category like @user_category + '%' )
and (@price  = 'ALL' or adm_cust.price_level like @price  + '%' )
and (@username = 'ALL' or orders.who_entered like @username + '%' )
and (@routing = 'ALL' or orders.routing like @routing + '%' )
and (@fob = 'ALL' or orders.fob like @fob + '%' )
and (@forwarder_key = 'ALL' or orders.forwarder_key like @forwarder_key + '%' )
and (@freight_to = 'ALL' or orders.freight_to like @freight_to + '%' )
and (@freight_allow_type = 'ALL' or orders.freight_allow_type like @freight_allow_type + '%' )
and (@salesperson = 'ALL' or orders.salesperson like @salesperson + '%' )
and (@ship_to_region = 'ALL' or orders.ship_to_region like @ship_to_region + '%' )
and (@posting_code = 'ALL' or orders.posting_code like @posting_code + '%' )
and (@remit_key = 'ALL' or orders.remit_key like @remit_key + '%' )
and (@tax_id = 'ALL' or orders.tax_id like @tax_id + '%' )
and (@terms_code = 'ALL' or adm_cust.terms_code like @terms_code + '%' )
and (@dest_zone_code = 'ALL' or orders.dest_zone_code like @dest_zone_code + '%' )
and (@user_def_fld1 = 'ALL' or orders.user_def_fld1 like @user_def_fld1 + '%' )
and (@user_def_fld2 = 'ALL' or orders.user_def_fld2 like @user_def_fld2 + '%' )
and (@user_def_fld3 = 'ALL' or orders.user_def_fld3 like @user_def_fld3 + '%' )
and (@user_def_fld4 = 'ALL' or orders.user_def_fld4 like @user_def_fld4 + '%' )
and (@user_code = 'ALL' or orders.user_code like @user_code + '%' )
and (@back_ord_flag = 'ALL' or orders.back_ord_flag like @back_ord_flag + '%' )
and (@location = 'ALL' or orders.location like @location + '%' )
and (@load_no = 0 or orders.load_no = @load_no)
and (@invoice_no = 0 or orders.invoice_no = @invoice_no)
and (@req_ship_date_all = 'Y' or orders.req_ship_date between @req_ship_date_start and @req_ship_date_end)
and (@sch_ship_date_all = 'Y' or orders.sch_ship_date between @sch_ship_date_start and @sch_ship_date_end)
and (@cancel_date_all = 'Y' or orders.cancel_date between @cancel_date_start and @cancel_date_end)
and (@invoice_date_all = 'Y' or orders.invoice_date between @invoice_date_start and @invoice_date_end)
and (@date_shipped_all = 'Y' or orders.date_shipped between @date_shipped_start and @date_shipped_end)
and (@entered_date_all = 'Y' or orders.date_entered between @entered_date_start and @entered_date_end)
and (@user_def_fld5 = 0 or orders.user_def_fld5 = @user_def_fld5)
and (@user_def_fld6 = 0 or orders.user_def_fld6 = @user_def_fld6)
and (@user_def_fld7 = 0 or orders.user_def_fld7 = @user_def_fld7)
and (@user_def_fld8 = 0 or orders.user_def_fld8 = @user_def_fld8)
and (@user_def_fld9 = 0 or orders.user_def_fld9 = @user_def_fld9)
and (@user_def_fld10 = 0 or orders.user_def_fld10 = @user_def_fld10)
and (@user_def_fld11 = 0 or orders.user_def_fld11 = @user_def_fld11)
and (@user_def_fld12 = 0 or orders.user_def_fld12 = @user_def_fld12)

end 
GO
GRANT EXECUTE ON  [dbo].[scm_pb_dw_find_so_adv_search_sp] TO [public]
GO
