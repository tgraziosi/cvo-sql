SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[EAI_ord_line_kit_defaults] @header_location varchar(10) = NULL, @line_location varchar(10) = NULL, @part_no varchar(30) as
begin
  Declare @err int, @err_desc varchar(255
), @ordered decimal(20,8),
  	@lb_track char(1), @price_type char(1), @conv_factor decimal(20,8),
	@status char(1), @cost decimal(20,8), @shipped decimal(20,8),
	@cr_ordered decimal(20,8), @cr_shipped decimal(20,8), 
	@labor decimal(20,8), @direct_dolrs decimal(20,8), @ovhd_dolrs decimal(20,8), 
	@util_dolrs decimal(20,8), @part_type varchar(10), @order decimal(20,8),
	@qc_flag char(1), @qc_no int, @uom varchar(2), @location varchar(10),
	@kit_no varchar(30), @description varchar(255)
	

   select @location = @line_location
   --If location is null, get the system-EAI's location.
   If (@location is null)
		select @location = @header_location

   If (@location is null)
   begin
		select @location = value_str 
		from config (NOLOCK)
		where flag = 'EAI_LOC'

		If (@location is null)
		Begin
			Select 	@err = -120,
					@err_desc = 'ERROR: Cannot find default EAI-location in config table.'

			Select 	error = @err,
					error_desc = @err_desc
	
			Return
		End 
	end

	-- Note: Since there is no part_type for EAI_ord_line_kit, the part have to be exist in inv_list.
 
      /* Get Inventory Information */
	 
      select 	 @kit_no 		   = m.part_no,
                 @uom          	   = m.uom,
                 @lb_track      = m.lb_tracking
      from 	inv_master m(NOLOCK), inv_list l(NOLOCK)
      where  	m.part_no   = @part_no and
		l.location  = @location and
		m.part_no	= l.part_no

	  If (@kit_no is null)
	  Begin
		Select 	@err = -120, 
				@err_desc = 'ERROR: Cannot find the kit for the part ' + @part_no + '.'

		Select 	error = @err,
					error_desc = @err_desc

		Return
	  End 



	  if (@lb_track is null)
		select @lb_track = 'N'

	  select @description = description
	  from   inventory
	  where  part_no = @part_no

  	  Select	@err = 0,
		 		@part_type = 'P',
				@status = 'N',
				@order = 0,
				@shipped = 0,
				@lb_track = @lb_track,
				@qc_flag = 'N',
				@qc_no = 0,
				@conv_factor = 1,
				@cr_ordered = 0,
				@cr_shipped = 0,
				@cost = 0,
				@labor = 0,
				@direct_dolrs = 0,
				@ovhd_dolrs = 0,
				@util_dolrs = 0	

  	  Select	error = @err,
		 		part_type = @part_type,
				status = @status,
				ordered = 1,
				shipped = 0,
				lb_track = @lb_track,
				qc_flag = @qc_flag,
				qc_no = @qc_no,
				conv_factor = 1,
				cr_ordered = 0,
				cr_shipped = 0,
				cost = 0,
				labor = 0,
				direct_dolrs = 0,
				ovhd_dolrs = 0,
				util_dolrs = 0,
				uom	= @uom,
				location = @location,
				description = @description	
end



GO
GRANT EXECUTE ON  [dbo].[EAI_ord_line_kit_defaults] TO [public]
GO
