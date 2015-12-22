SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\appayto.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[appayto_sp]
	@pay_to_code	varchar(8),
	@vendor_code	varchar(12),
	@attn_phone 	varchar(30),
	@attn_name	varchar(40),
	@terms_code	varchar(8),
	@tax_code	varchar(8),
	@fob_code	varchar(8),
	@posting_code	varchar(8),
	@location_code	varchar(8)
AS
DECLARE @p_attn_name varchar(40), @p_attn_phone varchar(30),
	@p_tax_code varchar(8), @p_fob_code varchar(8),
	@p_posting_code varchar(8), @p_terms_code varchar(8),
	@p_add1 varchar(40), @p_add2 varchar(40), @p_add3 varchar(40),
	@p_add4 varchar(40), @p_add5 varchar(40), @p_add6 varchar(40),
	@p_location_code varchar(8), @p_addr_name	varchar(40)

	
	SELECT 	@p_add1 = "", @p_add2 = "", @p_add3 = "",
		@p_add4 = "", @p_add5 = "", @p_add6 = "",
		@p_fob_code = "", @p_tax_code = "",
		@p_terms_code = "", @p_posting_code = "",
		@p_attn_name = "", @p_attn_phone = "",
		@p_location_code = "", @p_addr_name = ""

	
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
	AND	vendor_code = @vendor_code
	
	
	IF @p_attn_name = ""
		SELECT @p_attn_name = @attn_name

	IF @p_attn_phone = ""
		SELECT @p_attn_phone = @attn_phone

	IF @p_terms_code = ""
		SELECT @p_terms_code = @terms_code

	IF @p_tax_code = ""
		SELECT @p_tax_code = @tax_code

	IF @p_fob_code = ""
		SELECT @p_fob_code = @fob_code

	IF @p_posting_code = ""
		SELECT @p_posting_code = @posting_code

	IF @p_location_code = ""
		SELECT @p_location_code = @location_code

	
	SELECT 	@p_add1,
		@p_add2,
		@p_add3,
		@p_add4,
		@p_add5,
		@p_add6,
		@p_attn_phone,
		@p_attn_name,
		@p_terms_code,
		@p_tax_code,
		@p_fob_code,
		@p_posting_code,
		@p_location_code,
		@p_addr_name

GO
GRANT EXECUTE ON  [dbo].[appayto_sp] TO [public]
GO
