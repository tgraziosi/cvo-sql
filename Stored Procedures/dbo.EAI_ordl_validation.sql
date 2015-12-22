SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[EAI_ordl_validation] @partType varchar(1), @location varchar(10), @partNo varchar(30),
@uom varchar(2), @uomConv decimal(20,8), @orderQty decimal(20,8), 
@discountPct decimal(20,8),@taxCode varchar(10), @glRevAcct varchar(32), @backOrderFlg varchar(1),
@status varchar(1), @unitPrice decimal(20,8), @itemCost decimal(20,8),
@taxable varchar(1), @locationHeader varchar(10), @custCode varchar(10)
as
Begin

 	declare @err int, @err_msg varchar(255)
	declare @tempChar varchar(10), @stdUOM varchar(2)
	declare @default_loc varchar(10), @alt_loc varchar(10), @eai_loc varchar(10) -- rev 3

	select @err = 0

	--Validate Part Type
    	If (@partType > '')
	begin
	  	--Check if PartType is (C)ustom Kit, (E)stimate, (J)ob, (M)iscellaneous Item, 
	  	--(P)roduction item, (X)Configurable Item, or (v)Non-Quantity Bearing Item
	  	if @partType not in ('C', 'E', 'J', 'M', 'P', 'X', 'V', 'S')
      		begin
        		select 	@err = -100, 
    	   			@err_msg = 'ERROR: Part Type must be C, E, J, M, P, X, V, or S.'

			select 	error = @err,
				error_desc = @err_msg
        		return
      		end
	end

	--validate location
/* rev 2:  Add logic to validate the location.  
	1.  First check if the location specified by Front Office is valid for this part.
	2.  If not, or if they don't specify a location, then check to see the default location from the arcust table
	3.  If that is not valid for this part, check the alternate location from the arcust table
	4.  If that is not valid for this part, check the EAI_LOC in the config table
	5.  If that is not valid for this part, use the first location that is valid for this part
	6.  If for some reason, there are no longer any valid locations for this part, send an error!
*/

	Select @location = LTrim(RTrim(@location))
	If (Len(@location) > 0) BEGIN	-- Front Office has sent a location
		if not exists( select min(location) from locations (NOLOCK) where location = @location) Begin
			-- location is not valid
			select @location = ''
		End
		else Begin
			-- part is not valid at this location
			if not exists ( select 'X' from inv_list where part_no = @partNo and location = @location) begin
				select @location = ''
			end
		End
	END	-- FO supplied location

	Select @location = LTrim(RTrim(@location))
	IF (@location is null) BEGIN	-- either FO didn't send a location, or it was invalid
		select 	@default_loc = location_code, 
			@alt_loc = alt_location_code
		from	arcust
		where 	customer_code = @custCode

		If (Len(@default_loc) > 0) Begin	-- 2. check if in default loc
		   if exists ( select 'X' from inv_list where part_no = @partNo and location = @default_loc) begin
			select @location = @default_loc
		   end 
		end

		If (@location is null) begin
		   if (Len(@alt_loc) > 0) begin	-- 3. check if in alternate loc
			if exists ( select 'X' from inv_list where part_no = @partNo and location = @alt_loc) begin
			   select @location = @alt_loc
			end
		   end
		end

		If (@location is null) begin
		-- 4. check if in EAI_loc
		   select @eai_loc = value_str from config (NOLOCK) where flag = 'EAI_LOC'
		   if (Len(@eai_loc) > 0) begin
			if exists ( select 'X' from inv_list where part_no = @partNo and location = @eai_loc) begin
				select @location = @eai_loc
			end
		   end
		end
		
		If (@location is null) begin
		-- 5. get the first valid location
			select @location = min(location) from inv_list where part_no = @partNo
		end
	END
	
	if (@location is null) begin
		select	@err = -110, 
			@err_msg = 'ERROR: There is not a valid location for part ' + @partNo + '.'
		select 	error = @err,
			error_desc = @err_msg
		return
	end

	If not(@partNo > '')
	begin
		select 	@err = -130, 
        	      	@err_msg = 'ERROR: Part number cannot be null.'

		select 	error = @err,
			error_desc = @err_msg
	      	return
	end
	else
	begin
		if (@partType = 'J')
		begin
			if not exists(SELECT MIN( prod_no ) 
                		From 	produce(NOLOCK)
                		WHERE 	prod_no = @partNo and
                				prod_ext = 0 )
			begin
              			select 	@err = -140, 
	              			@err_msg = 'ERROR: ' + @partNo + ' is not a valid Job Part.'

				select 	error = @err,
					error_desc = @err_msg
        		      	return
			end
		end
		else if (@partType = 'E')
		begin
			if not exists(SELECT MIN( est_no ) 
                		From 	estimates(NOLOCK)
                		WHERE 	est_no = @partNo )
			begin
	       			select 	@err = -150, 
        	    			@err_msg = 'ERROR: ' + @partNo + ' is not a valid Estimate part.'

				select 	error = @err,
					error_desc = @err_msg
	       			return
			end	
        	end
		else if (@partType = 'M')
		begin
			select @uom = 'EA'
		end
		else if (@partType in ('C', 'P', 'V'))
		begin
			SELECT @tempChar = MIN( value_str )
                	From config(NOLOCK)
                	WHERE flag = 'OE_MULTI_LOCS'

			if upper(@tempChar) in ('YES', 'Y')
              			select @location = '%'
			
			SELECT @stdUOM = MIN( m.uom )
			FROM inv_list l(NOLOCK), inv_master m(NOLOCK)
			WHERE 	m.part_no = @partNo and
					m.part_no = l.part_no and
					l.location like @location
	
        	if not(@stdUOM > '')
		begin
	            	select 	@err = -160, 
            			@err_msg = 'ERROR : Cannot get standard UOM for part no ' + @partNo + '.'

			select 	error = @err,
				error_desc = @err_msg
	            	return
		end	
    
		if not exists( SELECT MIN( conv_factor )
                  			From uom_table (NOLOCK)
                  			WHERE 	item in (@partNo, 'STD') AND 
            	      				std_uom = @stdUOM and
            	      				alt_uom = @uom)
		begin
            		select 	@err = -170, 
            			@err_msg = 'ERROR: Cannot UOM conversion for part no ' + @partNo + '.'

			select 	error = @err,
				error_desc = @err_msg
	            	return

			end
		end
	end


	if @uomConv < 0 
	begin
	        select 	@err = -170, 
        		@err_msg = 'ERROR: Uom conversion cannot be negative.'

		select 	error = @err,
			error_desc = @err_msg
	        return
	end

	if (@orderQty < 0)
	begin
	       	select 	@err = -180, 
	        	@err_msg = 'ERROR: Order Quantity cannot be negative.'

		select 	error = @err,
			error_desc = @err_msg
		return
	end

	if (@discountPct < 0) or (@discountPct > 100)
	begin
	       	select 	@err = -190, 
	        	@err_msg = 'ERROR: Discount Percentage must be between 0 and 100.'

		select 	error = @err,
			error_desc = @err_msg
		return
	end

	if (@taxCode > '')
	begin
		if not exists( SELECT MIN( tax_code )
              			From artax (NOLOCK)
              			WHERE tax_code = @taxCode AND
    				      module_flag in (0,1))
		begin
        		select 	@err = -200, 
       				@err_msg = 'ERROR: ' + @taxCode+ ' is not a valid Tax Code.'

			select 	error = @err,
				error_desc = @err_msg
			return
		end
	end		

	if (@glRevAcct > '') 
	begin
		if not exists( 	SELECT account_code 
				FROM glchart( NOLOCK ) 
				WHERE  	account_code = @glRevAcct AND
 					inactive_flag = 0 )
		begin
	        	select 	@err = -210, 
       				@err_msg = 'ERROR: ' + @glRevAcct + ' is not a valid GL Account.'

			select 	error = @err,
				error_desc = @err_msg
			return
		end		
	end

	if (@backOrderFlg > '') and @backOrderFlg not in ('1', '0')
	begin
	        select 	@err = -220, 
	        	@err_msg = 'ERROR: Back Order Flag must be 1 or 0.'

		select 	error = @err,
			error_desc = @err_msg
		return
	end		

	--Validate Status
    	If (@status > '') 
	begin
	  --Check if status is (A)User Hold, (B)Price Hold, (C)Credit Hold, (E)EDI Order,
	  --(H)Price Hold, (M)Blanket, (N)New, (P)Open/Picked, (Q)Open/Print, (R)Ready/Posting,
	  --(S)Shipped/Posted, (T)Shipped/Transferred, (V)Void, or (W)Canceled Quote.
	  if @status not in ('A','B', 'C', 'E', 'H', 'M', 'N', 'P', 'Q', 'R',
		'S', 'T', 'V', 'W')
          begin
              	select 	@err = -230, 
       			@err_msg = 'ERROR: Status must be (A)User Hold, (B)Credit & Price Hold,' +
				' (C)Credit Hold, (E)EDI Order, (H)Price Hold, ' +
				' (M)Blanket, (N)New, (P)Open/Picked, (Q)Open/Print,' +
				' (R)Ready/Posting, (S)Shipped/Posted, (T)Shipped/Transferred,' +
				' (V)Void, or (W)Canceled Quote.'

			select 	error = @err,
				error_desc = @err_msg
              	return
      	  end
	end


	if (@unitPrice < 0)
	begin
	        select 	@err = -240, 
	        	@err_msg = 'ERROR: Order Quantity cannot be negative.'

		select 	error = @err,
			error_desc = @err_msg
		return
	end


	if (@itemCost < 0)
	begin
	        select 	@err = -250, 
	        	@err_msg = 'ERROR: Order Quantity cannot be negative.'

		select 	error = @err,
			error_desc = @err_msg
		return
	end
    
	if (@taxable > '') and @taxable not in(1, 0)
	begin
        	select 	@err = -260, 
	        	@err_msg = 'ERROR: Order Quantity cannot be negative.'

		select 	error = @err,
			error_desc = @err_msg
		return
	end
	select error = @err
	return 
End 

GO
GRANT EXECUTE ON  [dbo].[EAI_ordl_validation] TO [public]
GO
