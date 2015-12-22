SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[EAI_ord_shipto_defaults] @cust_code varchar(10),  @ship_to varchar(10) = NULL as
begin
  declare @row_id int, @err int, @err_msg varchar(255), @processing int, @loop_line_no int, 
    @loop_order_no varchar(100), @adm_order_no int, @deflocation varchar(10), @inv_stat char(1)

  declare @ship_to_name varchar(40), @ship_to_add_1 varchar(40),
    @ship_to_add_2 varchar(40), @ship_to_add_3 varchar(40), @ship_to_add_4 varchar(40),
    @ship_to_add_5 varchar(40), @ship_to_city varchar(40), @ship_to_state char(2),
    @ship_to_zip varchar(10), @ship_to_country varchar(40), @ship_to_region varchar(10),
    @salesperson varchar(8), @tax_code varchar(8)

  if @ship_to is null
  begin
    --Case ship_to is null get ship_to info. from customer.
    if exists (select * from arcust a
                        where a.customer_code = @cust_code)
    begin
      select	@ship_to_name    = customer_name,
                @ship_to_add_1   = addr1,
                @ship_to_add_2   = addr2,
                @ship_to_add_3   = addr3,
                @ship_to_add_4   = addr4,
                @ship_to_add_5   = addr5,
                @ship_to_city    = city,
                @ship_to_state   = state,
                @ship_to_zip     = postal_code,
                @ship_to_country = country_code,
                @ship_to_region  = territory_code,
		@salesperson	 = salesperson_code
      from  	arcust (NOLOCK) 
      where     customer_code  = @cust_code
    end
    else
      begin
        select 	@err = -100, 
        	 	@err_msg = 'ERROR: ' + @cust_code + ' is not a valid Customer.'

        select error = @err, 
        	   error_desc = @err_msg 
        return
      end
    end
    else
    begin
	--Case ship_to is valid get all the ship_to info from ship_to.
      if exists (select * from arshipto a(NOLOCK)
			where  a.customer_code = @cust_code and 
                         a.ship_to_code  = @ship_to )      
       begin
         select @ship_to_name    = ship_to_name,
                @ship_to_add_1   = addr1,
               	@ship_to_add_2   = addr2,
                @ship_to_add_3   = addr3,
                @ship_to_add_4   = addr4,
                @ship_to_add_5   = addr5,
               	@ship_to_city    = city,
               	@ship_to_state   = state,
                @ship_to_zip     = postal_code,
                @ship_to_country = country_code,
                @ship_to_region  = territory_code,
		@salesperson	 = salesperson_code,
		@tax_code	 = tax_code
         from 	arshipto (NOLOCK)
         where 	customer_code  = @cust_code and
               	ship_to_code   = @ship_to   
       end
       else
       begin
	   --return error since it cannot find any shipto info
         select @err = -110, 
         		@err_msg = 'ERROR: ' + @ship_to + ' is not a valid Shipto.'

         select error = @err, 
         	    error_desc = @err_msg 
	   return
       end
     end  --ship_to


     -- rev 2: validate the region for integration
	if not exists( select min(territory_code)
			from arterr(NOLOCK) 
			where territory_code = @ship_to_region
			and ddid is not null) 
	begin
		select 	@err = -120, 
           	@err_msg = 'ERROR: ' + @ship_to_region + ' is not a valid Territory Code for integration.'

		select 	error = @err,
    			error_desc = @err_msg

		return
      	end	

     Select @err = 0

     select error = @err,
	    error_desc = @err_msg,	
	    ship_to_name = @ship_to_name    ,
            ship_to_add_1 = @ship_to_add_1   ,
	    ship_to_add_2 = @ship_to_add_2   ,
            ship_to_add_3 = @ship_to_add_3   ,
            ship_to_add_4 = @ship_to_add_4   ,
            ship_to_add_5 = @ship_to_add_5   ,
            ship_to_city = @ship_to_city    ,
            ship_to_state = @ship_to_state   ,
            ship_to_zip = @ship_to_zip     ,
            ship_to_region = @ship_to_region  , 
            ship_to_country = @ship_to_country ,
	    salesperson = @salesperson,
	    tax_id	= @tax_code
end
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_shipto_defaults] TO [public]
GO
