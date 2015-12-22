SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


create procedure [dbo].[icv_loadcc_sp] @payment_code char(8), @customer_code char(8), @option int as
	DECLARE @creditcard_prefix	int,
		@creditcard_length	int,
		@use_mod10_validation	int,

		@prompt1_encoded	varchar(255),
		@prompt2_encoded	varchar(255),
		@prompt3_encoded	varchar(255),
		@prompt4_encoded	varchar(255),
		@preload		int,
	
		@rowcount		int

	


	SELECT 	@creditcard_prefix = creditcard_prefix,
		@creditcard_length = creditcard_length,

		@use_mod10_validation = use_mod10_validation
	  FROM	icv_cctype
	 WHERE	payment_code = @payment_code

	SELECT @rowcount = @@rowcount

	IF @rowcount < 1
	BEGIN
		SELECT 	"ErrorCode"=1001, 
			"Prompt1"="", 
			"Prompt2"="", 
			"Prompt3"="", 
			"Prompt4"="", 
			"Preload"=0,
			"CreditCardPrefix"=0,
			"CreditCardLength"=0,
			"UseMod10Validation"=0
		RETURN 1001
	END

	SELECT	@prompt1_encoded = prompt1,
		@prompt2_encoded = prompt2,
		@prompt3_encoded = prompt3,
		@prompt4_encoded = prompt4,
		@preload = preload
	  FROM	icv_ccinfo
	 WHERE	payment_code = @payment_code
	   AND	customer_code = @customer_code

	IF @prompt1_encoded = NULL OR
	   @prompt2_encoded = NULL OR
	   @prompt3_encoded = NULL OR
	   @prompt4_encoded = NULL
		SELECT @preload = 0

	SELECT 	"ErrorCode"=0, 
		"Prompt1"=ISNULL(@prompt1_encoded,""),
		"Prompt2"=ISNULL(@prompt2_encoded,""),
		"Prompt3"=ISNULL(@prompt3_encoded,""),
		"Prompt4"=ISNULL(@prompt4_encoded,""),
		"CreditCardPrefix"=@creditcard_prefix,
		"Preload"=ISNULL(@preload,0),
		"CreditCardLength"=@creditcard_length,
		"UseMod10Val"=@use_mod10_validation
	return 0


GO
GRANT EXECUTE ON  [dbo].[icv_loadcc_sp] TO [public]
GO
