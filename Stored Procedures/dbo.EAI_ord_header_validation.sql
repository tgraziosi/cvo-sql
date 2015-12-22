SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[EAI_ord_header_validation] @cust_code varchar(10), @billTo varchar(10), 
@remitTo varchar(10), @currencyCode varchar(10), @discountPct decimal(20,8),
@fobCode varchar(10), @forwarderKey varchar(10), @freightAmt decimal(20,8),
@freightType varchar(10), @holdCode varchar(10), @location varchar(10),
@territoryCode varchar(10), @postingCode varchar(10), @taxCode varchar(10),
@taxPct decimal(20,8), @paymentTerms varchar(10), @shipVia varchar(20),
@orderType varchar(1), @backOrderFlg varchar(1), @blanketOrder varchar(1),
@status varchar(1), @ship_to varchar(10) 
as
Begin

	declare @err int, @err_desc varchar(255)
	--Validate cust_code

	select @err = 0

	if ltrim(@cust_code) = ''
    	begin
        	select 	@err = -100, 
           		@err_desc = 'ERROR: customer code cannot be null.'
		

     		select 	error = @err,
    			error_desc = @err_desc

        	return
    	end
	else
	begin
	  	if not exists( select c.customer_code
	  			from arcust c (NOLOCK)
	  			where c.customer_code = @cust_code) 
          	begin
              		select 	@err = -110, 
              			@err_desc = 'ERROR: ' + @cust_code + 'is not a valid customer code.'


			select 	error = @err,
				error_desc = @err_desc
	
        	      	return
      	  	end
	end

	--Validate BillTo	
	if ltrim(@billTo) > ''
	begin
	  	if not exists( select c.customer_code
  				 from arcust c (NOLOCK)
  				 where c.customer_code = @billTo) 
      		begin
        		select 	@err = -120, 
           			@err_desc = 'ERROR' + @billTo + ' is not a valid BillTo.'

     			select 	error = @err,
    				error_desc = @err_desc

        		return
      		end
	end

    	--Validate Remit To
	/* rev 3--ignore the FO remit code because that isn't what we use 
	if ltrim(@remitTo)  > ''
	begin
	  	if ( select min(kys)
  				 from arremit(NOLOCK) 
  				 where kys = @remitTo) is null
      		begin
       			select 	@err = -130, 
           			@err_desc = 'ERROR: ' + @remitTo + ' is not a valid RemitTo.'

     			select 	error = @err,
	    			error_desc = @err_desc

		       	return
      		end
	end
	*/

    	--Validate Currency Code
	if ltrim(@currencyCode)  > ''
	begin
	  	if ( select min(currency_code) 	
				from glcurr_vw(NOLOCK) 
  				where currency_code = @currencyCode) is null
      		begin
       			select 	@err = -140, 
       				@err_desc = 'ERROR: ' + @currencyCode + ' is not a valid Currency Code.'

	  		select 	error = @err,
	   			error_desc = @err_desc

		       	return
      		end
	end
        

    	--Validate Discount Percentage
    	If (@discountPct) is not null
	begin
	  	if (@discountPct < 0) or (@discountPct > 100)
	  	begin
       			select 	@err = -150, 
         			@err_desc = 'ERROR: Discount Percentage must be greater than or equal to zero' +
						' and less than or equal to one hundred.'

		   	select 	error = @err,
	   			error_desc = @err_desc

		       	return
      		end
	end
        
    	--Validate FOB Code
	if ltrim(@fobCode)  > ''
	begin
	  	if ( select min(fob_code)
	  			from arfob(NOLOCK) 
  				where fob_code = @fobCode) is null
      		begin
       			select 	@err = -160, 
       				@err_desc = 'ERROR: ' + @fobCode + ' is not a valid FOB Code.'

		  	select 	error = @err,
	   			error_desc = @err_desc

		       	return
      		end
	end
        
    	--Validate ForwarderKey
	if ltrim(@forwarderKey)  > ''
	begin
	  	if ( select min(kys)
	  			 from arfwdr(NOLOCK) 
	  			 where kys = @forwarderKey) is null
      		begin
      			select 	@err = -170, 
       				@err_desc = 'ERROR: ' + @forwarderKey + ' is not a valid Forwarder Key'

		  	select 	error = @err,
	  			error_desc = @err_desc

		       	return
      		end
	end
        
    	--Validate Freight Amount
	/*CGonzalez - SCR 31300
    	If (@freightAmt) is not null
	begin
		if (@freightAmt < 0) 
	  	begin
       			select 	@err = -180, 
           			@err_desc = 'ERROR: Freight Amount must be greater than or equal to zero.'

     			select 	error = @err,
    				error_desc = @err_desc

       			return
      		end
	end
        */
    	--Validate Freight Type
	if ltrim(@freightType)  > ''
	begin
	  	if ( select min(kys)
	  			from freight_type(NOLOCK) 
	  			where kys = @freightType) is null
      		begin
        		select 	@err = -190, 
           			@err_desc = 'ERROR: ' + @freightType + ' is not a valid Freight Type.'

     			select 	error = @err,
    				error_desc = @err_desc

		        return
      		end
	end

    	--Validate Hold Reason
	if ltrim(@holdCode)  > ''
	begin
	  	if ( select min(hold_code)
	  			from adm_oehold(NOLOCK) 
	  			where hold_code = @holdCode) is null
      		begin
        		select 	@err = -200, 
           			@err_desc = 'ERROR: ' + @holdCode + ' is not a valid Hold Code.'

		     	select 	error = @err,
    				error_desc = @err_desc

		        return
      		end
	end

	--validate location
	if ltrim(@location)  > ''
	begin
	  	if ( select min(location)
	  			from locations(NOLOCK) 
	  			where location = @location) is null
      		begin
       			select 	@err = -210, 
           			@err_desc = 'ERROR: ' + @location + ' is not a valid Location.'

		     	select 	error = @err,
    				error_desc = @err_desc

		       	return
      		end
	end

	--validate territory code
	if ltrim(@territoryCode)  > ''
	begin
	  	if ( select min(territory_code)
	  			from arterr(NOLOCK) 
	  			where territory_code = @territoryCode
				and ddid is not null) is null
      		begin
        		select 	@err = -220, 
           			@err_desc = 'ERROR: ' + @territoryCode + ' is not a valid Territory Code.'

     			select 	error = @err,
    				error_desc = @err_desc

        		return
      		end
	end

    	--Validate Posting Code
	if ltrim(@postingCode)  > ''
	begin
	  	if ( select min(posting_code)
	  		from araccts(NOLOCK) 
	  		where posting_code = @postingCode) is null
      		begin
       			select 	@err = -230, 
           			@err_desc = 'ERROR: ' + @postingCode + ' is not a valid Posting Code.'

     			select 	error = @err,
    				error_desc = @err_desc

       			return
      		end
	end

	--Validate Tax Code

	/* rev 3--ignore the FO tax code and take the tax code from BO 
	if ltrim(@taxCode)  > ''
	begin
	  	if ( select min(tax_code)
	  			from artax(NOLOCK) 
	  			where tax_code = @taxCode) is null
      		begin
        		select 	@err = -240, 
        			@err_desc = 'ERROR: ' + @taxCode + ' is not a valid Tax Code.'

     			select 	error = @err,
    				error_desc = @err_desc

        		return
      		end
	end
	*/
	
    	--Validate tax percentage
    	If (@taxPct) is not null
	begin
	  	if (@taxPct < 0) 
	  	begin
        		select 	@err = -250, 
              			@err_desc = 'Tax Percentage must be greater than or equal to zero.'

     			select 	error = @err,
    				error_desc = @err_desc

        		return
      		end
	end

	--Validate Payment Terms@paymentTerms
	if ltrim(@paymentTerms)  > ''
	begin
	  	if ( select min(terms_code)
  				from arterms(NOLOCK) 
  				where terms_code = @paymentTerms) is null
      		begin
        		select 	@err = -260, 
           			@err_desc = 'ERROR: ' + @paymentTerms + ' is not a valid Payment Terms.'

     			select 	error = @err,
    				error_desc = @err_desc

        		return
      		end
	end

	--Validate Ship Via
	if ltrim(@shipVia)  > ''
	begin
	  	if ( select min(ship_via_code)
	  			from arshipv(NOLOCK) 
	  			where ship_via_code = @shipVia) is null
      		begin
        		select 	@err = -270, 
           			@err_desc = 'ERROR: ' + @shipVia + ' is not a valid Ship Via.'

		     	select 	error = @err,
    				error_desc = @err_desc

		        return
      		end
	end

/* rev 4
	--Validate Order Type
	if ltrim(@orderType)  > ''
	begin
	  	--Check if orderType is (C)redit-return or (I)nvoice
	  	if @orderType not in ('C','I')
      		begin
        		select 	@err = -117, 
           			@err_desc = 'ERROR: Order Type must be (C)redit-return or (I)nvoice.'

     			select 	error = @err,
    				error_desc = @err_desc

        		return
      		end
	end
*/

	--Validate BackOrder Flag
	if ltrim(@backOrderFlg)  > ''
	begin
	  	--Check if backOrderFlg is (0)allow back order or (1) not allow back order
	  	if @backOrderFlg not in ('0','1')
      		begin
	        	select 	@err = -280, 
        	   		@err_desc = 'ERROR: Back Order Flag must be (0)allow back order or' +
									' (1)not allow back order.'

     			select 	error = @err,
    				error_desc = @err_desc

		        return
      		end
	end

	--Validate BlanketOrder
	if ltrim(@blanketOrder)  > ''
	begin
		--Check if blanketOrder is (Y)regular order or (N)blanket order
	  	if @blanketOrder not in ('N','Y')
      		begin
        		select 	@err = -290, 
           			@err_desc = 'ERROR: Blanket Order must be (Y)regular order or' +
							' (N)blanket order.'

		     	select 	error = @err,
    				error_desc = @err_desc

		        return
   	  	end
	end


	--Validate Status
	if ltrim(@status)  > ''
	begin
	  	--Check if status is (A)User Hold, (B)Price Hold, (C)Credit Hold, (E)EDI Order,
	  	--(H)Price Hold, (M)Blanket, (N)New, (P)Open/Picked, (Q)Open/Print, (R)Ready/Posting,
	  	--(S)Shipped/Posted, (T)Shipped/Transferred, (V)Void, or (W)Canceled Quote.
	  	if @status not in ('A','B', 'C', 'E', 'H', 'M', 'N', 'P', 'Q', 'R',
	  	'S', 'T', 'V', 'W')
      		begin
       			select 	@err = -300, 
           			@err_desc = 'ERROR: Status must be (A)User Hold, (B)Price Hold,' +
					' (C)Credit Hold, (E)EDI Order, (H)Price Hold, ' +
					' (M)Blanket, (N)New, (P)Open/Picked, (Q)Open/Print,' +
					' (R)Ready/Posting, (S)Shipped/Posted, (T)Shipped/Transferred,' +
					' (V)Void, or (W)Canceled Quote.'

		     	select 	error = @err,
    				error_desc = @err_desc

		       	return
      		end
	end

	--Validate Ship_to
	if ltrim(@ship_to)  > ''
	begin
		if (SELECT MIN( ship_to_code ) 
            		From arshipto(NOLOCK)
            		WHERE 	customer_code = @cust_code AND
        			ship_to_code = @ship_to AND
        			status_type = 1) is null
		begin
       			select 	@err = -310, 
           			@err_desc = 'ERROR: ' + @ship_to + ' is not a valid ship-to code.'

		     	select 	error = @err,
    				error_desc = @err_desc

		       	return
      		end
	end

	select error = @err    
End 
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_header_validation] TO [public]
GO
