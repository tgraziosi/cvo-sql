SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[EAI_ord_header_defaults] @cust_code varchar( 10 ), @order_curr varchar (10) as		--SCR 28258
Begin
	--These are output variables (if this store proc fail, it return just @err and @err_desc
	Declare @err int, @err_desc varchar(255), @remit_key varchar(10), @back_order_flag varchar(1),
		@blanket varchar(1), @type_code varchar(1), @curr_key varchar(10), 
		@req_ship_date datetime, @sch_ship_date datetime,
		@discount decimal(20,8), @fob varchar(10), @forwarder_key varchar(10),
		@location varchar(10), @posting_code varchar(10), @phone varchar(20),
		@status varchar(1), @tax_id varchar(10), @tax_perc decimal(20,8),
		@terms varchar(10), @routing varchar(20), @rate_type_home varchar(8),
		@rate_type_oper varchar(8), @curr_factor decimal(20,8), @oper_factor decimal(20,8),
		@date_entered datetime, @dflt_ship_to varchar(10), @salesperson varchar(8)

	declare @retval int, @date_applied int, @nat_cur_code varchar(10), 
		@oper_curr varchar(10), @divop int

	-- Rev 5
	DECLARE @consolidate_flag	INT
	DECLARE @addr1			VARCHAR(40)
	DECLARE @addr2			VARCHAR(40)
	DECLARE @addr3			VARCHAR(40)
	DECLARE @addr4			VARCHAR(40)
	DECLARE @addr5			VARCHAR(40)
	DECLARE @addr6			VARCHAR(40)
	DECLARE @user_stat_code		VARCHAR(8)
	DECLARE @amt_blanket		FLOAT
	DECLARE @date_blnk_from		DATETIME
	DECLARE @date_blnk_to		DATETIME
	DECLARE	@user_priority		VARCHAR(8)
	DECLARE @user_category		VARCHAR(10)
	DECLARE @autoship_flag		SMALLINT
	DECLARE @proc_inv_no		VARCHAR(32)
	DECLARE @user_def_fld1		VARCHAR(255)		
	DECLARE @user_def_fld2		VARCHAR(255)		
	DECLARE @user_def_fld3		VARCHAR(255)		
	DECLARE @user_def_fld4		VARCHAR(255)		
	DECLARE @user_def_fld5		FLOAT
	DECLARE @user_def_fld6		FLOAT
	DECLARE @user_def_fld7		FLOAT
	DECLARE @user_def_fld8		FLOAT
	DECLARE @user_def_fld9		INT
	DECLARE @user_def_fld10		INT
	DECLARE @user_def_fld11		INT
	DECLARE @user_def_fld12		INT
	DECLARE @multiple_flag		INT
	DECLARE @total_amt_order	FLOAT
	DECLARE @total_invoice		FLOAT
	DECLARE @Adm_Installed		VARCHAR(3)
	-- END Rev 5
	DECLARE @org_id                 VARCHAR(30) 

	Select @err = 0
	Select @Adm_Installed = config_value from EAI_config where config_item = 'Adm_Installed'

	
	if @Adm_Installed = 'Yes'
	begin
		if not exists (select * from config where flag = 'EAI' and value_str = 'Y')
		begin
			--return error since it cannot find any shipto info
		        select @err = -100,
        		   @err_desc = 'ERROR: BackOffice does not set up to run EAI.'


	        	select 	error = @err,
        		error_desc = @err_desc
			return
		end
        end

    select @curr_key = home_currency, @oper_curr = oper_currency from glco (nolock)

    select @nat_cur_code = @order_curr								--SCR 28258

  	if (@location is null)	--If the location is null, get the default location for EAI
	begin
		if @Adm_Installed = 'Yes'
		begin
			select @location = value_str 
			from config (NOLOCK)
			where flag = 'EAI_LOC'
		end
		Else
		begin
			select @location = ''
		end
	end

   	--Get Currency code
   	select 	@req_ship_date = getdate(),
		@sch_ship_date = getdate(),
		@date_entered = getdate(),
		@status = 'A', --'A'(user hold)
		@blanket = 'N', --NO
		@type_code = 'I', --Invoice
		@tax_perc	  = 0.0
		
   	select 	@remit_key = remit_code,
		@back_order_flag = cast(ship_complete_flag as char(1)) , 
       		@curr_key = isnull(@curr_key, nat_cur_code), 
		@discount = trade_disc_percent, 
       		@fob          = fob_code,
		@forwarder_key = forwarder_code,
           	@posting_code = posting_code,
		@phone = contact_phone,
           	@tax_id       = tax_code,
		@terms        = terms_code,
           	@routing      = ship_via_code,
		@rate_type_home = rate_type_home, 
		@rate_type_oper = rate_type_oper,
		@nat_cur_code = isnull(@nat_cur_code, nat_cur_code),				--SCR 28258
		@consolidate_flag = ISNULL(consolidated_invoices,0),	-- Rev 5
		@addr1 = ISNULL(addr1,''),				-- Rev 5
		@addr2 = ISNULL(addr2,''),				-- Rev 5
		@addr3 = ISNULL(addr3,''),				-- Rev 5
		@addr4 = ISNULL(addr4,''),				-- Rev 5
		@addr5 = ISNULL(addr5,''),				-- Rev 5
		@addr6 = ISNULL(addr6,'')				-- Rev 5
   	from 	arcust (NOLOCK)
   	where 	customer_code = @cust_code 

	-- Rev 5
	SELECT @user_stat_code = ' '

	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'so_usrstat' AND type = 'U')
	BEGIN
		SELECT @user_stat_code = user_stat_code
 		  FROM so_usrstat
		 WHERE status_code = @status
		   AND default_flag = 1
	END
	ELSE
	BEGIN
		SELECT @user_stat_code = ''

	END

	SELECT 	@amt_blanket = 0,
		@date_blnk_from = 0,
		@date_blnk_to = 0,
		@user_priority = '',
		@user_category = '',
		@autoship_flag = 0,
		@proc_inv_no = '',
		@user_def_fld1 = '',
		@user_def_fld2 = '',
		@user_def_fld3 = '',
		@user_def_fld4 = '',
		@user_def_fld5 = 0.0,
		@user_def_fld6 = 0.0,
		@user_def_fld7 = 0.0,
		@user_def_fld8 = 0.0,
		@user_def_fld9 = 0,
		@user_def_fld10 = 0,
		@user_def_fld11 = 0,
		@user_def_fld12 = 0,
		@multiple_flag = 0,
		@total_amt_order = 0.0,
		@total_invoice = 0.0
	-- END Rev 5

	-- rev 3: select salesperson
	select @salesperson = ''
	select @salesperson = arsalesp.salesperson_code
	from arcust (NOLOCK), arsalesp (NOLOCK)
	where customer_code = @cust_code 
		and arsalesp.salesperson_code = arcust.salesperson_code
		and arsalesp.ddid is not null

	-- rev 2: Choose a default ship-to in case it is a multi-ship to customer and FO didn't specify
	select	@dflt_ship_to = IsNull(MIN( ship_to_code ), null) 
	from	arshipto (NOLOCK)
	WHERE 	customer_code = @cust_code AND status_type = 1

	If @dflt_ship_to is NULL
	BEGIN
		SELECT @dflt_ship_to = ''
	END


	--Check if back_order_flag is null, default to 0
	If (@back_order_flag is null)
	begin 
		select @back_order_flag = '0'
	end

    select @date_applied = datediff(day,'01/01/1900',getdate())+693596

    --Get today Currency factor between natural currency and order currency.
    exec @retval = CVO_Control..mccurate_sp
            	@date_applied, @nat_cur_code, @curr_key, @rate_type_home,
            	@curr_factor OUTPUT,0,@divop OUTPUT

	--Error Checking
    if @retval <> 0 
    BEGIN
     	select 	@err = -110,
    			@err_desc = 'Error: cannot call mccurate_sp for home_rate.'

     	select 	error = @err,
    			error_desc = @err_desc
      	return
    END

    --Get today Currency factor between Opperational currency and order currency.
    exec @retval = CVO_Control..mccurate_sp
            @date_applied, @nat_cur_code, @oper_curr, @rate_type_oper,
            @oper_factor OUTPUT,0,@divop OUTPUT

    if @retval <> 0 
    BEGIN
    	select 	@err = -120,
         		@err_desc = 'Error: cannot call mccurate_sp for oper_rate.'

     	select 	error = @err,
    			error_desc = @err_desc

		return
    END

  --736
    SELECT @org_id = organization_id FROM Organization WHERE outline_num = '1'

 

    select 	error = @err,
		error_desc = @err_desc,
		remit_key = @remit_key,
		back_ord_flag  = @back_order_flag ,
		blanket = @blanket, 
       		curr_key = @curr_key ,
		req_ship_date = @req_ship_date ,
		sch_ship_date = @sch_ship_date ,
		discount  = @discount ,
       		fob = @fob    ,
		forwarder_key = @forwarder_key ,
		location  = @location ,
           	posting_code = @posting_code ,
		phone = @phone ,
		type_code = @type_code, 
		status = @status ,
           	tax_id = @tax_id  ,
		tax_perc = @tax_perc,
		terms = @terms   ,
           	routing = @routing  ,
		rate_type_home = @rate_type_home ,
		rate_type_oper = @rate_type_oper ,
		curr_factor = @curr_factor,
		oper_factor = @oper_factor ,
		today_date = GetDate(),
		dflt_ship_to = @dflt_ship_to,		-- rev 2
		salesperson = @salesperson,		-- rev 3
		consolidate_flag = @consolidate_flag,	-- Rev 5
		addr1 = @addr1,				-- Rev 5
		addr2 = @addr2,				-- Rev 5
		addr3 = @addr3,				-- Rev 5
		addr4 = @addr4,				-- Rev 5
		addr5 = @addr5,				-- Rev 5
		addr6 = @addr6,				-- Rev 5
		user_stat_code = @user_stat_code,	-- Rev 5
		amt_blanket = @amt_blanket,		-- Rev 5
		date_blnk_from = @date_blnk_from,	-- Rev 5
		date_blnk_to = @date_blnk_to,		-- Rev 5
		user_priority = @user_priority,		-- Rev 5
		user_category = @user_category,		-- Rev 5
		autoship_flag = @autoship_flag,		-- Rev 5
		proc_inv_no = @proc_inv_no,		-- Rev 5
		user_def_fld1 = @user_def_fld1,		-- Rev 5
		user_def_fld2 = @user_def_fld2,		-- Rev 5
		user_def_fld3 = @user_def_fld3,		-- Rev 5
		user_def_fld4 = @user_def_fld4,		-- Rev 5
		user_def_fld5 = @user_def_fld5,		-- Rev 5
		user_def_fld6 = @user_def_fld6,		-- Rev 5
		user_def_fld7 = @user_def_fld7,		-- Rev 5
		user_def_fld8 = @user_def_fld8,		-- Rev 5
		user_def_fld9 = @user_def_fld9,		-- Rev 5
		user_def_fld10 = @user_def_fld10,	-- Rev 5
		user_def_fld11 = @user_def_fld11,	-- Rev 5
		user_def_fld12 = @user_def_fld12,	-- Rev 5
		multiple_flag = @multiple_flag,		-- Rev 5
		total_amt_order = @total_amt_order,	-- Rev 5
		total_invoice = @total_invoice,		-- Rev 5
		org_id        = @org_id                 -- 736  
END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_header_defaults] TO [public]
GO
