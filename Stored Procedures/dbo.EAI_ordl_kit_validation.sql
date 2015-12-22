SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[EAI_ordl_kit_validation] @location varchar(10), @partNo varchar(30), @perQty decimal(20,8)
as
Begin

 	declare @err int, @err_msg varchar(255)
	declare @tempChar varchar(10)

	select @err = 0

	--validate Part.  Assume Part Type is 'P'
	If not(@partNo > '')
	begin
		select 	@err = -100, 
        	      	@err_msg = 'ERROR: Part number cannot be null.'

		select 	error = @err,
			error_desc = @err_msg
	      	return
	end
	else
	begin
		SELECT @tempChar = MIN( value_str )
               	From config(NOLOCK)
               	WHERE flag = 'OE_MULTI_LOCS'

		if upper(@tempChar) in ('YES', 'Y')
      			select @location = '%'
			
		if not exists( SELECT distinct 'X'
		FROM inv_list l(NOLOCK)
		WHERE 	l.part_no = @partNo and
			l.location like @location)
		begin
	            	select 	@err = -110, 
            			@err_msg = 'ERROR : Invalide part no.' + @partNo

			select 	error = @err,
				error_desc = @err_msg
	            	return
		end	    
	end


	if @perQty < 0 
	begin
	        select 	@err = -120, 
        		@err_msg = 'ERROR: Kit Quantity cannot be negative.'

		select 	error = @err,
			error_desc = @err_msg
	        return
	end

	select error = @err
	return 
End 

GO
GRANT EXECUTE ON  [dbo].[EAI_ordl_kit_validation] TO [public]
GO
