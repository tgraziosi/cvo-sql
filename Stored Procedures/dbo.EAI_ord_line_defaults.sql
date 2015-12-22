SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[EAI_ord_line_defaults] @part_no varchar(30), @uom char(2) = NULL, @part_type varchar(10) = NULL, 
@location varchar(10) = NULL, @ordered decimal(20,8) = 0, @posting_code varchar(10) = NULL, @cust_code varchar(10),
@tax_code varchar(8) as
begin

  Declare @err int, @err_desc varchar(255), @prod_no int,  @description varchar(255),
  	@est_no int, @curr_price decimal(20,8),  @gl_rev_acct varchar(32), 
  	@lb_tracking char(1), @taxable int, @price_type char(1), @conv_factor decimal(20,8),
	@cubic_feet decimal(20,8), @weight_ea decimal(20,8), @std_uom char(2), 
	@inv_tax_id varchar(10), @inv_stat char(1), @status char(1), 
	@acct_code varchar(8), @rev_flag int, @back_ord_flag char(1), @discount decimal(20,8),
	@cost decimal(20,8), @time_entered datetime, @shipped decimal(20,8),
	@sales_comm decimal(20,8), @cr_ordered decimal(20,8), @cr_shipped decimal(20,8), 
	@labor decimal(20,8), @direct_dolrs decimal(20,8), @ovhd_dolrs decimal(20,8), @util_dolrs decimal(20,8), 
	@total_tax decimal(20,8), @std_cost decimal(20,8), @valid_loc varchar(10), @service_agreement_flag char(1)

  /* rev 4 */
  Declare @default_loc varchar(8), @alt_loc varchar(8), @eai_loc varchar(8)


  DECLARE @create_po_flag		INT		-- Rev 13
  DECLARE @load_group_no		INT		-- Rev 13
  DECLARE @return_code			VARCHAR(10)	-- Rev 13
  DECLARE @user_count			INT		-- Rev 13

  select @err = 0

  select @curr_price = 0

  If @part_type = 'J' --Case part type is a Job.
  Begin
	SELECT 	@prod_no = prod_no,
			@location = location, 
			@description = description,
	         	@ordered = qty_scheduled, 
			@est_no = est_no, 
			@posting_code = posting_code
	FROM 	produce(NOLOCK)
  	WHERE 	prod_no = @part_no AND prod_ext = 0 

	If @prod_no is null 
	begin
		Select 	@err = -100,
				@err_desc = 'ERROR: The item on a job cannot be null.'

		Select 	error = @err,
				error_desc = @err_desc
	
		Return
	End
		
	If (@est_no > 0) 
		SELECT @curr_price = quoted_price
		FROM   estimates (NOLOCK)
		WHERE  est_no = @est_no and quoted_qty = @ordered 

	If (@curr_price is null) 
		Select @curr_price = 0

	If (@posting_code > '') 
		SELECT @gl_rev_acct = sales_acct_code
		FROM  in_account (NOLOCK)
		WHERE acct_code = @posting_code 
	
	Select 	@uom = 'EA',
		@lb_tracking = 'N',
		@taxable = 0,
		@price_type = 'Q',
		@conv_factor = 1,
		@cubic_feet = 0,
		@weight_ea = 0
  End 
  Else If (@part_type = 'E') --Case part type is Estimate
  Begin	
	if (@ordered is null)
		Select @ordered = 0

	SELECT 	@est_no = est_no,
		@description = description, 
		@location = location
	From	estimate(NOLOCK)
	WHERE   est_no = @part_no and 
		quoted_qty = @ordered

	If (@est_no is null) 
	begin
		Select 	@err = -110,
				@err_desc = 'ERROR: The item on an estimate cannot be null.'

		Select 	error = @err,
				error_desc = @err_desc
	
		Return
	End 
		
	If (@posting_code > '')
		SELECT @gl_rev_acct = sales_acct_code
		FROM  in_account (NOLOCK)
		WHERE acct_code = @posting_code 
	
	Select 	@uom = 'EA',
		@lb_tracking = 'N',
		@taxable = 0,
		@conv_factor = 1,
		@price_type = 'Q',
		@ordered = 1,
		@cubic_feet = 0,
		@weight_ea = 0
  End
  Else
  Begin


    /* rev 7 */
    /* check service agreement */
    if exists(select 'X' from service_agreement where item_id = @part_no) begin
	select @service_agreement_flag = 'Y'
	select @location = ''
	select @inv_tax_id = ''
	if (@uom is null or @uom = '') begin
		select @uom = 'CL'	--default to call-based if needed
		select @conv_factor = 1
	end
    end
    else begin
	select @service_agreement_flag = 'N'

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
	IF (@location is null) BEGIN	-- either FO didn't send a location, or it was invalid
		select 	@default_loc = location_code, 
			@alt_loc = alt_location_code
		from	arcust
		where 	customer_code = @cust_code

		If (@default_loc is not null) Begin	-- 2. check if in default loc
		   if exists ( select 'X' from inv_list where part_no = @part_no and location = @default_loc) begin
			select @location = @default_loc
		   end 
		end

		If (@location is null) begin
		   if (Len(@alt_loc) > 0) begin	-- 3. check if in alternate loc
			if exists ( select 'X' from inv_list where part_no = @part_no and location = @alt_loc) begin
			   select @location = @alt_loc
			end
		   end
		end

		If (@location is null) begin
		-- 4. check if in EAI_loc
		   select @eai_loc = value_str from config (NOLOCK) where flag = 'EAI_LOC'
		   if (Len(@eai_loc) > 0) begin
			if exists ( select 'X' from inv_list where part_no = @part_no and location = @eai_loc) begin
				select @location = @eai_loc
			end
		   end
		end
		
		If (@location is null) begin
		-- 5. get the first valid location
			select @location = min(location) from inv_list where part_no = @part_no
		end
	END
	
	if (@location is null) begin
		select	@err = -110, 
			@err_desc = 'ERROR: There is not a valid location for part ' + @part_no + '.'
		select 	error = @err,
			error_desc = @err_desc
		return
	end


	  If (@part_type is null) 
		Select @part_type = 'P'  --Part Type

      /* Get Inventory Information */
	  Select	@conv_factor = 1,	
		 	@status = 'N',
		 	@lb_tracking = 'N',
		 	@price_type = '1'
	 
	select 	 @description      = m.description,
                 @std_uom          = m.uom,
                 @lb_tracking      = m.lb_tracking,
                 @weight_ea        = m.weight_ea,
		 @cubic_feet	   = m.cubic_feet,
		 @taxable	   = m.taxable,
                 @inv_tax_id       = m.tax_code,
		 @inv_stat         = l.status,
                 @acct_code        = l.acct_code
	from 	inv_master m(NOLOCK), inv_list l(NOLOCK)
	where  	m.part_no = l.part_no and m.part_no = @part_no and l.location  = @location 

        end	-- end not service agreement


	Select @part_type = Case 	
			when @inv_stat is null then 'M'
			when @inv_stat = 'V' then 'V'
			when @inv_stat = 'C' then 'C'
			else 'P' end
		
	If (@uom is null) begin
			select 	@uom = @std_uom,
			@conv_factor = 1
	end
	Else Begin
			--Get uom conversion
			SELECT 	@conv_factor = conv_factor
 			FROM 	uom_table (NOLOCK)
 			WHERE 	( item = @part_no or item = 'STD') and 
				( std_uom = @std_uom ) and (alt_uom = @uom)

			If (@conv_factor is null) select @uom = @std_uom,
							 @conv_factor = 1
	End
    end


    /* Check revenue Flag to determine where to pull the account from */
    select @rev_flag = min(default_rev_flag) from arco

    if (@rev_flag is null) select @rev_flag = 1

    --Get gl account
    IF (@rev_flag = 0) begin

	/* rev 11 */	
	if (@posting_code is null) begin
		select	@posting_code = posting_code
		from	arcust 
		where	customer_code = @cust_code
	end
	/* end rev 11 */

	select @gl_rev_acct = rev_acct_code 
	from araccts (NOLOCK)
	where posting_code = @posting_code
    end 
    ELSE begin 
         SELECT @gl_rev_acct = sales_acct_code
         FROM in_account(NOLOCK)
         WHERE acct_code = @acct_code
    End

    if (@gl_rev_acct is null) begin	-- check to see if it is a service agreement
	if (@service_agreement_flag = 'Y') begin

/* 01/31/01 MRD #6.1.2.12 - start */
   		select @gl_rev_acct = gl_rev_acct from service_agreement where item_id = @part_no

/*		select @gl_rev_acct = value_str from config 
		where flag = 'SA_REVENUE_ACCT'
*/
/* 01/31/01 MRD #6.1.2.12 - end */

	end
    end

    if (@gl_rev_acct is null) begin
	Select 	@err = -130,
		@err_desc = 'ERROR: Needs G/L revenue account. The part may not be valid at this location.'

	Select 	error = @err,
		error_desc = @err_desc
	Return
    end 

    if (@ordered is null ) select @ordered = 0

    -- check tax code
    -- rev 9
    if IsNull((select min(tax_code) from artax (NOLOCK) where tax_code = @tax_code),'') = '' begin
	select @tax_code = ''
    end

    Select	@err = 0,
		@back_ord_flag = '0',
		@status = 'N',
		@discount = 0,
		@cost = 0,
		@time_entered = getdate(),
		@shipped = 0, 	--From here on these fields are required 
				--and not listed in Business doc.
		@sales_comm = 0,  
		@cr_ordered = 0,
		@cr_shipped = 0,
		@labor = 0,
		@direct_dolrs = 0,
		@ovhd_dolrs = 0,
		@util_dolrs = 0,
		@total_tax = 0,
		@std_cost = 0,
	 	@price_type = '1',			
		@create_po_flag = 0,			-- Rev 13
		@load_group_no = 0,			-- Rev 13
		@return_code = '',			-- Rev 13
		@user_count = 0				-- Rev 13

	--		shipped, sales_comm, price, oper_price, cr_order, cr_shipped, 		
	--		cubit_feet, labor, direct_dolrs, ovhd_dolrs, util_dolrs, total_tax,
	--		curr_price, oper_price, display_line 
	--		are required and need to default to 0.
   Select 	error = @err,
		error_desc = @err_desc,
		description = @description,
		part_type = @part_type,
		ordered = @ordered,
		uom = @uom,
		conv_factor = @conv_factor,
		weight_ea = @weight_ea,
		cubic_feet =@cubic_feet,
		back_ord_flag = @back_ord_flag,
		status = @status,
		price_type = @price_type,
		discount = @discount,
		cost = @cost,
		inv_tax_id = @inv_tax_id,
		taxable = @taxable,
		location = @location,
		gl_rev_acct = @gl_rev_acct,
		time_entered = @time_entered,
		shipped = @shipped,
		sales_comm = @sales_comm,
		cr_ordered = @cr_ordered,
		cr_shipped = @cr_shipped,
		labor = @labor,
		direct_dolrs = @direct_dolrs,
		ovhd_dolrs = @ovhd_dolrs,
		util_dolrs = @util_dolrs,
		total_tax = @total_tax,
		std_cost = @std_cost,
		curr_price = @curr_price,
		service_agreement_flag = @service_agreement_flag,
		tax_code_in = @tax_code,				
		create_po_flag = @create_po_flag,			-- Rev 13
		load_group_no = @load_group_no,				-- Rev 13
		return_code = @return_code,				-- Rev 13
		user_count = @user_count				-- Rev 13
end
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_line_defaults] TO [public]
GO
