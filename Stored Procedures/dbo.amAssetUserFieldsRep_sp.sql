SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amAssetUserFieldsRep_sp] 
( 
	@company_id			smCompanyID,			
	


	


	
	  
   	@debug_level		smDebugLevel	= 0	
) 
AS 

DECLARE 
	@result 				smErrorCode,
	@co_asset_id 			smSurrogateKey, 
	@is_imported			smLogical,
	@user_field_subid		tinyint,
	@count 					smCounter,
	@code_1					varchar(40),
	@code_2					varchar(40),
	@code_3					varchar(40),
	@code_4					varchar(40),
	@code_5					varchar(40),
	@date_1					varchar(40),
	@date_2					varchar(40),
	@date_3					varchar(40),
	@date_4					varchar(40),
	@date_5					varchar(40),
	@amount_1				varchar(40),
	@amount_2				varchar(40),
	@amount_3				varchar(40),
	@amount_4				varchar(40),
	@amount_5				varchar(40),
	@head					varchar(40)


	 
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amusrfldrep.cpp" + ", line " + STR( 89, 5 ) + " -- ENTRY: "























 







 









	




	















		




		



















	


	




		
















		

























IF @debug_level >= 5
	SELECT	co_asset_id
	FROM	#counter












SELECT	@count = 1	




SELECT	@user_field_subid	= MIN(user_field_subid)
FROM	amusrhdr
WHERE	company_id			= @company_id
AND		user_field_id		= 1000
AND		user_field_type	IN (11,12)

WHILE @user_field_subid IS NOT NULL
BEGIN
	
	SELECT 	@head 	= user_field_title
	FROM	amusrhdr
	WHERE	company_id			= @company_id
	AND		user_field_id		= 1000
	AND		user_field_subid	= @user_field_subid

   		
	IF @count = 1
		SELECT @code_1	= @head
	ELSE IF @count = 2
		SELECT @code_2	= @head
	ELSE IF @count = 3
		SELECT @code_3	= @head
	ELSE IF @count = 4
		SELECT @code_4	= @head
	ELSE IF @count = 5
		SELECT @code_5	= @head	
			
	


		
	SELECT @count = @count + 1
		
		 

	SELECT	@user_field_subid	= MIN(user_field_subid)
	FROM	amusrhdr
	WHERE	company_id			= @company_id
	AND		user_field_id		= 1000
	AND		user_field_type		IN (11,12)
	AND		user_field_subid	> @user_field_subid 

END  	 






SELECT	@count = 1	




SELECT	@user_field_subid	= MIN(user_field_subid)
FROM	amusrhdr
WHERE	company_id			= @company_id
AND		user_field_id		= 1000
AND		user_field_type		IN (21 ,22, 23, 24,25)

WHILE @user_field_subid IS NOT NULL
BEGIN
	
	SELECT 	@head 				= user_field_title
	FROM	amusrhdr
	WHERE	company_id			= @company_id
	AND		user_field_id		= 1000
	AND		user_field_subid	= @user_field_subid

		
	IF @count = 1
		SELECT @date_1	= @head
	ELSE IF @count = 2
		SELECT @date_2	= @head
	ELSE IF @count = 3
		SELECT @date_3	= @head
	ELSE IF @count = 4
		SELECT @date_4	= @head
	ELSE IF @count = 5
		SELECT @date_5	= @head	
			
	


		
	SELECT @count = @count + 1
    

	SELECT	@user_field_subid	= MIN(user_field_subid)
	FROM	amusrhdr
	WHERE	company_id			= @company_id
	AND		user_field_id		= 1000
	AND		user_field_type		IN (21 ,22, 23, 24,25)
	AND		user_field_subid	> @user_field_subid 

END 
	 
 




SELECT	@count = 1	




SELECT	@user_field_subid	= MIN(user_field_subid)
FROM	amusrhdr
WHERE	company_id			= @company_id
AND		user_field_id		= 1000
AND		user_field_type		IN (31,32,33,34,35)

WHILE @user_field_subid IS NOT NULL
BEGIN
	
	SELECT 	@head 	= user_field_title
	FROM	amusrhdr
	WHERE	company_id			= @company_id
	AND		user_field_id		= 1000
	AND		user_field_subid	= @user_field_subid

			
	IF @count = 1
		SELECT @amount_1	= @head
	ELSE IF @count = 2
		SELECT @amount_2	= @head
	ELSE IF @count = 3
		SELECT @amount_3	= @head
	ELSE IF @count = 4
		SELECT @amount_4	= @head
	ELSE IF @count = 5
		SELECT @amount_5	= @head	
			
	


		
	SELECT @count = @count + 1    

	SELECT	@user_field_subid	= MIN(user_field_subid)
	FROM	amusrhdr
	WHERE	company_id			= @company_id
	AND		user_field_id		= 1000
	AND		user_field_type		IN (31,32,33,34,35)
    AND		user_field_subid	> @user_field_subid 

END 







INSERT INTO #amuserfieldstemp 
		
SELECT distinct	a.asset_ctrl_num,
		a.asset_description,
		user_code_1_title=@code_1,
		b.user_code_1,
		user_code_2_title=@code_2,
		b.user_code_2,
		user_code_3_title=@code_3,
		b.user_code_3,
		user_code_4_title=@code_4,
		b.user_code_4,
		user_code_5_title=@code_5,
		b.user_code_5,
		user_date_1_title=@date_1,
		b.user_date_1,
		user_date_2_title=@date_2,
		b.user_date_2,
		user_date_3_title=@date_3,
		b.user_date_3,
		user_date_4_title=@date_4,
		b.user_date_4,
		user_date_5_title=@date_5,
		b.user_date_5,
		user_amount_1_title=@amount_1,
		b.user_amount_1,
		user_amount_2_title=@amount_2,
		b.user_amount_2,
		user_amount_3_title=@amount_3,
		b.user_amount_3,
		user_amount_4_title=@amount_4,
		b.user_amount_4,
		user_amount_5_title=@amount_5,
		b.user_amount_5,
		a.org_id,
		dbo.IBGetParent_fn (a.org_id)
		
FROM	amasset a, amusrfld b, #counter c, region_vw r, amOrganization_vw o
WHERE	a.co_asset_id 		= c.co_asset_id
AND a.org_id = o.org_id
AND a.org_id = r.org_id
AND		a.user_field_id 	= b.user_field_id
	

RETURN 0
  
GO
GRANT EXECUTE ON  [dbo].[amAssetUserFieldsRep_sp] TO [public]
GO
