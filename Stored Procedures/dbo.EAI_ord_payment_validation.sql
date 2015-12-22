SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[EAI_ord_payment_validation]
@cust_code varchar(10), 
@payment_code		varchar(8),	
@card_name		varchar(30), 
@card_num 		varchar(30), 
@card_exp		varchar(30)
as
Begin

	declare @err int, @err_desc varchar(255)

	--Validate card_name
	select @err = 0
	if ltrim(@card_name) = ''
    	begin
        	select 	@err = -100, 
           		@err_desc = 'ERROR: Card Holder cannot be null.'
     		select 	error = @err,
    			error_desc = @err_desc
        	return
    	end

	--Validate card_num
	select @err = 0
	if ltrim(@card_num) = ''
    	begin
        	select 	@err = -110, 
           		@err_desc = 'ERROR: Card Number cannot be null.'
     		select 	error = @err,
    			error_desc = @err_desc
        	return
    	end
	--Validate card_exp
	select @err = 0
	if ltrim(@card_exp) = ''
    	begin
        	select 	@err = -120, 
           		@err_desc = 'ERROR: Card Expiration cannot be null.'
     		select 	error = @err,
    			error_desc = @err_desc
        	return
    	end

	--Validate cust_code
	select @err = 0
	if ltrim(@cust_code) = ''
    	begin
        	select 	@err = -130, 
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
              		select 	@err = -140, 
              			@err_desc = 'ERROR: ' + @cust_code + 'is not a valid customer code.'
			select 	error = @err,
				error_desc = @err_desc
        	      	return
      	  	end
	end

	--Validate payment_code
	if ltrim(@payment_code) > ''
	begin
	  	if not exists( 	SELECT payment_code  
				FROM arpymeth   (NOLOCK) 
				WHERE payment_code = @payment_code )
      		begin
        		select 	@err = -150, 
           			@err_desc = 'ERROR' + @payment_code + ' is not a valid Payment Code.'
     			select 	error = @err,
    				error_desc = @err_desc
        		return
      		end
	end

	select error = @err    
End
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_payment_validation] TO [public]
GO
