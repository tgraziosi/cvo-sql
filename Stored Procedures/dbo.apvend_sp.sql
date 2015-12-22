SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apvend.SPv - e7.2.2 : 1.8
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[apvend_sp]
	@vendor_code	char(12) ,	@trx_type smallint
AS
DECLARE @pay_to_code 	varchar(8),	@attn_name 	varchar(40),
	@attn_phone 	varchar(30), 	@branch_code 	varchar(8),
	@location_code 	varchar(8), 	@tax_code 	varchar(8),
	@class_code 	varchar(8), 	@fob_code 	varchar(8),
	@posting_code 	varchar(8), 	@one_check_flag smallint,
	@terms_code 	varchar(8), 	@p_attn_name 	varchar(40),
	@p_attn_phone 	varchar(30), 	@p_tax_code 	varchar(8),
	@p_fob_code 	varchar(8),	@p_posting_code varchar(8),
	@p_terms_code varchar(8), 	@p_add1 	varchar(40),
	@p_add2 	varchar(40),	@p_add3 	varchar(40),
	@p_add4 	varchar(40), 	@p_add5 	varchar(40),
	@p_add6 	varchar(40), 	@p_location_code varchar(8),
	@comment_code 	varchar(8), 	@usr_trx_type 	varchar(8),
	@payment_code 	varchar(8),	@p_addr_name		varchar(40)

	
	SELECT 	@p_add1 = " ",		@p_add2 = " ",	
		@p_add3 = " ", 		@p_add4 = " ", 		
		@p_add5 = " ", 		@p_add6 = " ",
		@p_fob_code = " ", 	@p_tax_code = " ",
		@terms_code = " ", 	@p_posting_code = " ",
		@p_attn_name = " ", 	@p_attn_phone = " ",
		@p_location_code = " " , @pay_to_code = " ",
		@p_terms_code = " ",	@p_addr_name = ""

	
	SELECT	@attn_name 	= attention_name,
		@attn_phone 	= attention_phone,
		@terms_code 	= terms_code,
		@tax_code 	= tax_code,
		@class_code 	= vend_class_code,
		@fob_code 	= fob_code,
		@posting_code 	= posting_code,
		@pay_to_code 	= pay_to_code,
		@location_code 	= location_code,
		@branch_code 	= branch_code,
		@one_check_flag = one_check_flag,
		@comment_code 	= comment_code,
		@usr_trx_type 	= user_trx_type_code,
		@payment_code	= payment_code
	FROM 	apvendok_vw
	WHERE 	vendor_code 	= @vendor_code 
	
	IF (@trx_type = 4092 or @trx_type = 4161)
		SELECT @payment_code = "DBMEMO"


	
	IF ( ( @pay_to_code != " " OR @pay_to_code IS NOT NULL ) AND
	 EXISTS ( SELECT pay_to_code FROM appayok_vw
		 WHERE vendor_code = @vendor_code
		 AND pay_to_code = @pay_to_code ) )
	BEGIN
	 SELECT	@p_add1 = addr1,
			@p_add2 = addr2,
			@p_add3 = addr3,
			@p_add4 = addr4,
			@p_add5 = addr5,
			@p_add6 = addr6,
			@p_attn_name = attention_name,
			@p_attn_phone = attention_phone,
			@p_terms_code = terms_code,
			@p_tax_code = tax_code,
			@p_fob_code = fob_code,
			@p_posting_code = posting_code,
			@p_location_code = location_code,
			@p_addr_name = pay_to_name
	 FROM 	appayok_vw
	 WHERE 	pay_to_code = @pay_to_code
	 AND 	vendor_code = @vendor_code
	END

	
	IF @p_attn_name != " "
		SELECT @attn_name = @p_attn_name

	IF @p_attn_phone != " "
		SELECT @attn_phone = @p_attn_phone

	IF @p_terms_code != " "
		SELECT @terms_code = @p_terms_code

	IF @p_tax_code != " "
		SELECT @tax_code = @p_tax_code

	IF @p_fob_code != " "
		SELECT @fob_code = @p_fob_code

	IF @p_posting_code != " "
		SELECT @posting_code = @p_posting_code

	IF @p_location_code != " "
		SELECT @location_code = @p_location_code

	
	SELECT 	@pay_to_code,
		@p_add1,
		@p_add2,
		@p_add3,
		@p_add4,
		@p_add5,
		@p_add6,
		@attn_name,
		@attn_phone,
		@location_code,
		@tax_code,
		@class_code,
		@fob_code,
		@posting_code,
		@terms_code,
		@branch_code,
		@one_check_flag,
		@comment_code,
		@usr_trx_type,
		@payment_code,
		@p_addr_name

GO
GRANT EXECUTE ON  [dbo].[apvend_sp] TO [public]
GO
