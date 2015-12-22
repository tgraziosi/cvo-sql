SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_find_vendor_sp] @search varchar(12), @mode varchar(30), @secured_mode int, 
  @org_id varchar(30), @level int AS
BEGIN		

  Declare @l_ret varchar(12)
  declare @result1 varchar(12), @result2 varchar(12), @result varchar(12)
  declare @i_mode varchar(30)
  set @level = abs(@level)

set @result1 = ''
set @result2 = ''
set @i_mode = @mode

if @level = 1 or @level = 3
begin
	if lower(@mode) = 'next'
        begin
	  SELECT @result = MIN ( v.vendor_code )
	    FROM adm_vend v (nolock), adm_orglinks_vw l (nolock)
   	 WHERE v.vendor_code > @search AND v.status_type <> 6 
	    and l.vendor_code = v.vendor_code and l.customer_org_id = @org_id
	  if @result is NULL set @mode = 'last'
	end

	if lower(@mode) = 'prev'
        begin
	  SELECT @result = MAX ( v.vendor_code )
	    FROM adm_vend v (nolock), adm_orglinks_vw l (nolock)
   	WHERE v.vendor_code < @search AND v.status_type <> 6 
	    and l.vendor_code = v.vendor_code  and l.customer_org_id = @org_id

	  if @result is NULL set @mode = 'first'
	end

	if lower(@mode) = 'get_void'
        begin
	  SELECT @result =  MIN( v.vendor_code )
	    FROM adm_vend v (nolock), adm_orglinks_vw l (nolock)
	  	WHERE v.vendor_code = @search  and l.customer_org_id = @org_id
	    and l.vendor_code = v.vendor_code 
	end

	if lower(@mode) in ( 'get','validate')
        begin
	  SELECT @result =  MIN( v.vendor_code )
	    FROM adm_vend v (nolock), adm_orglinks_vw l (nolock)
   	WHERE v.vendor_code = @search and v.status_type <> 6 
	    and l.vendor_code = v.vendor_code  and l.customer_org_id = @org_id
	end

	if lower(@mode) = 'first'
        begin
	  SELECT @result =  MIN( v.vendor_code )
	    FROM adm_vend v (nolock), adm_orglinks_vw l (nolock)
		WHERE v.vendor_code > '' and v.status_type <> 6 
	    and l.vendor_code = v.vendor_code  and l.customer_org_id = @org_id
	end

	if lower(@mode) = 'last'
        begin
	  SELECT @result =  MAX( v.vendor_code )
	    FROM adm_vend v (nolock), adm_orglinks_vw l (nolock)
		WHERE v.vendor_code > '' and v.status_type <> 6 
	    and l.vendor_code = v.vendor_code  and l.customer_org_id = @org_id
	end
	set @result1 = @result
end
if @level <> 1 or @level = 3
begin
	set @mode = @i_mode
	if lower(@mode) = 'next'
        begin
	  SELECT @result = MIN ( v.vendor_code )
	    FROM adm_vend v (nolock)
   	 WHERE v.vendor_code > @search AND v.status_type <> 6 
	  and v.related_org_id is null
	  if @result is NULL set @mode = 'last'
	end

	if lower(@mode) = 'prev'
        begin
	  SELECT @result = MAX ( v.vendor_code )
	    FROM adm_vend v (nolock)
   	WHERE v.vendor_code < @search AND v.status_type <> 6 
	  and v.related_org_id is null
	  if @result is NULL set @mode = 'first'
	end

	if lower(@mode) = 'get_void'
        begin
	  SELECT @result =  MIN( v.vendor_code )
	    FROM adm_vend v (nolock)
   	WHERE v.vendor_code = @search 
	  and v.related_org_id is null
	end

	if lower(@mode) in ( 'get','validate')
        begin
	  SELECT @result =  MIN( v.vendor_code )
	    FROM adm_vend v (nolock)
   	WHERE v.vendor_code = @search and v.status_type <> 6 
	  and v.related_org_id is null	
	end

	if lower(@mode) = 'first'
        begin
	  SELECT @result =  MIN( v.vendor_code )
	    FROM adm_vend v (nolock)
		WHERE v.vendor_code > '' and v.status_type <> 6 
	  and v.related_org_id is null
	end

	if lower(@mode) = 'last'
        begin
	  SELECT @result =  MAX( v.vendor_code )
	    FROM adm_vend v (nolock)
		WHERE v.vendor_code > '' and v.status_type <> 6 
	  and v.related_org_id is null
	end
	set @result2 = @result
end
if @level = 3
begin
	set @mode = @i_mode
	if lower(@mode) = 'next'
        begin
	  if @result1 < @result2 and @result1 > @search
	    select @result = @result1

	  if @result2 = @search and @result1 > @search
	    select @result = @result1
	end

	if lower(@mode) = 'prev'
        begin
	  if @result1 > @result2 and @result1 < @search
	    select @result = @result1

	  if @result2 = @search and @result1 < @search
	    select @result = @result1
	end

	if lower(@mode) = 'get_void'
        begin
	  if @result1 is not null
	    select @result = @result1
	end

	if lower(@mode) in ( 'get','validate')
        begin
	  if @result1 is not null
	    select @result = @result1
	end

	if lower(@mode) = 'first'
        begin
	  if @result1 < @result2
	    select @result = @result1
	end

	if lower(@mode) = 'last'
        begin
	  if @result1 > @result2
	    select @result = @result1
	end
end
  
SELECT a.vendor_code,  a.address_name vendor_name,     a.addr1, 
	       a.addr2,           a.addr3, 
          a.addr4,           a.addr5, a.addr6,   			
          a.tax_code,        a.terms_code, 
			 a.fob_code,        a.one_cur_vendor,
			 a.rate_type_home,  a.rate_type_oper,
			 a.nat_cur_code,    a.freight_code, 
			 a.note,            a.posting_code,
			 a.exp_acct_code,   a.pay_to_code,
			 a.one_check_flag,  a.attention_name,
			 a.status_type,																
			 isnull(a.etransmit_ind,0),		
	isnull((select r.related_org_id from adm_orgvendrel r (nolock) where r.vendor_code = a.vendor_code),'') related_org_id,
		    a.city,
			 a.state,
			 a.postal_code,
			 a.country_code,
			admc.contact_name,
			admc.contact_phone 
	  FROM apmaster_all a (nolock)
left join (select vendor_code, min(adm.contact_no)
	 FROM adm_apcontacts adm (nolock) group by vendor_code) 
as minc(vendor_code, contact_no) on minc.vendor_code = a.vendor_code
left join adm_apcontacts admc (nolock)
on admc.vendor_code = a.vendor_code and admc.contact_no = minc.contact_no
where a.address_type = 0 and a.vendor_code = @result

END
GO
GRANT EXECUTE ON  [dbo].[adm_find_vendor_sp] TO [public]
GO
