SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_find_cust_sp] @search varchar(10), @mode varchar(30), @secured_mode int, 
  @org_id varchar(30), @level int AS
BEGIN		
  declare @l_ret varchar(10)
  declare @result varchar(12), @soldto_level int

  	set @level = abs(@level)
    select @soldto_level = case when lower(@mode) like 'oe%' then 1 else 0 end

	if @level = 1
 	begin
	if lower(@mode) in ('next','oenext')
        begin
	  SELECT @result = MIN( c.customer_code )
	    FROM adm_cust c (nolock), adm_orglinks_vw l (nolock)
   	WHERE c.customer_code > @search AND c.status_type=1 and c.valid_soldto_flag between @soldto_level and 1 
      and l.customer_code = c.customer_code and l.vendor_org_id = @org_id
	  if @result is NULL set @mode = 'last'
	end

	if lower(@mode) in ('prev','oeprev')
        begin
	  SELECT @result = MAX( c.customer_code )
	    FROM adm_cust c (nolock), adm_orglinks_vw l (nolock)
   	WHERE c.customer_code < @search AND c.status_type=1  and c.valid_soldto_flag between @soldto_level and 1
      and l.customer_code = c.customer_code and l.vendor_org_id = @org_id

	  if @result is NULL set @mode = 'first'
	end

	if lower(@mode) in ( 'get_void','oeget_void')
        begin
	  SELECT @result = MIN( c.customer_code )
	    FROM adm_cust c (nolock), adm_orglinks_vw l (nolock)
   	WHERE c.customer_code = @search  and c.valid_soldto_flag between @soldto_level and 1
      and l.customer_code = c.customer_code and l.vendor_org_id = @org_id
	end

	if lower(@mode) in ( 'get','validate','oeget','oevalidate')
        begin
	  SELECT @result = MIN( c.customer_code )
	    FROM adm_cust c (nolock), adm_orglinks_vw l (nolock)
   	WHERE c.customer_code = @search AND c.status_type=1 and c.valid_soldto_flag between @soldto_level and 1
      and l.customer_code = c.customer_code and l.vendor_org_id = @org_id
	end

	if lower(@mode) in ( 'first', 'oefirst')
        begin
	  SELECT @result = MIN( c.customer_code )
	    FROM adm_cust c (nolock), adm_orglinks_vw l (nolock)
   	WHERE c.customer_code > '' AND c.status_type=1  and c.valid_soldto_flag between @soldto_level and 1
      and l.customer_code = c.customer_code and l.vendor_org_id = @org_id
	end

	if lower(@mode) in ( 'last', 'oelast')
        begin
	  SELECT @result = MAX( c.customer_code )
	    FROM adm_cust c (nolock), adm_orglinks_vw l (nolock)
   	WHERE c.customer_code > '' AND c.status_type=1 and c.valid_soldto_flag between @soldto_level and 1 
      and l.customer_code = c.customer_code and l.vendor_org_id = @org_id
	end
	end
else
begin
	if lower(@mode) in ( 'next', 'oenext')
        begin
	  SELECT @result = MIN( c.customer_code )
	    FROM adm_cust c (nolock)
   	WHERE c.customer_code > @search AND c.status_type=1  and c.valid_soldto_flag between @soldto_level and 1
      and c.related_org_id is NULL
	  if @result is NULL set @mode = 'last'
	end

	if lower(@mode) in ( 'prev', 'oeprev')
        begin
	  SELECT @result = MAX( c.customer_code )
	    FROM adm_cust c (nolock)
   	WHERE c.customer_code < @search AND c.status_type=1 and c.related_org_id is NULL
      and c.valid_soldto_flag between @soldto_level and 1
	  if @result is NULL set @mode = 'first'
	end

	if lower(@mode) in ( 'get_void', 'oeget_void')
        begin
	  SELECT @result = MIN( c.customer_code )
	    FROM adm_cust c (nolock)
   	WHERE c.customer_code = @search and c.related_org_id is NULL
      and c.valid_soldto_flag between @soldto_level and 1
	end

	if lower(@mode) in ( 'get','validate','oeget','oevalidate')
        begin
	  SELECT @result = MIN( c.customer_code )
	    FROM adm_cust c (nolock)
   	WHERE c.customer_code = @search AND c.status_type=1 and c.related_org_id is NULL
      and c.valid_soldto_flag between @soldto_level and 1
	end

	if lower(@mode) in ( 'first', 'oefirst')
        begin
	  SELECT @result = MIN( c.customer_code )
	    FROM adm_cust c (nolock)
   	WHERE c.customer_code > '' AND c.status_type=1 and c.related_org_id is NULL
      and c.valid_soldto_flag between @soldto_level and 1
	end

	if lower(@mode) in ( 'last', 'oelast')
        begin
	  SELECT @result = MAX( c.customer_code )
	    FROM adm_cust c (nolock)
   	WHERE c.customer_code > '' AND c.status_type=1 and c.related_org_id is NULL
      and c.valid_soldto_flag between @soldto_level and 1
	end
end

	SELECT customer_code, address_name customer_name,    addr2,    addr3, 
			 addr4,            addr5,    addr6,
          terms_code,       fob_code, territory_code,
          salesperson_code, tax_code, trade_disc_percent,
			 ship_via_code,    short_name customer_short_name,
			 state,            postal_code, 
			 country_code,     ship_complete_flag,	
			 nat_cur_code,     one_cur_cust,
			 rate_type_home,   rate_type_oper,
			 remit_code,     	forwarder_code,
			 freight_to_code,  dest_zone_code,
			 note,             special_instr,
			 payment_code,     posting_code,
			 price_level,      price_code,
			 contact_name,	contact_phone,
			 city, 
			 so_priority_code,  
			 status_type,		
			 location_code,
		  	 isnull((select r.related_org_id from adm_orgcustrel r (nolock) where 
               r.customer_code = a.customer_code),'') related_org_id
	  FROM armaster_all a (nolock)
	 WHERE address_type = 0 and customer_code = @result 
END
GO
GRANT EXECUTE ON  [dbo].[adm_find_cust_sp] TO [public]
GO
