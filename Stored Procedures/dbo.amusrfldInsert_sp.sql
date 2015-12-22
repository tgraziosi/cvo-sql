SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amusrfldInsert_sp] 
( 
	@user_field_id 	smSurrogateKey, 
	@user_code_1 	smStdDescription, 
	@user_code_2 	smStdDescription, 
	@user_code_3 	smStdDescription, 
	@user_code_4 	smStdDescription, 
	@user_code_5 	smStdDescription, 
	@user_date_1 	varchar(30), 
	@user_date_2 	varchar(30), 
	@user_date_3 	varchar(30), 
	@user_date_4 	varchar(30), 
	@user_date_5 	varchar(30), 
	@user_amount_1 	smMoneyZero, 
	@user_amount_2 	smMoneyZero, 
	@user_amount_3 	smMoneyZero, 
	@user_amount_4 	smMoneyZero, 
	@user_amount_5 	smMoneyZero 
) as 

declare @error int 

 

SELECT @user_date_1 = RTRIM(@user_date_1) IF @user_date_1 = "" SELECT @user_date_1 = NULL
SELECT @user_date_2 = RTRIM(@user_date_2) IF @user_date_2 = "" SELECT @user_date_2 = NULL
SELECT @user_date_3 = RTRIM(@user_date_3) IF @user_date_3 = "" SELECT @user_date_3 = NULL
SELECT @user_date_4 = RTRIM(@user_date_4) IF @user_date_4 = "" SELECT @user_date_4 = NULL
SELECT @user_date_5 = RTRIM(@user_date_5) IF @user_date_5 = "" SELECT @user_date_5 = NULL

IF @user_amount_1 IS NULL 
	SELECT @user_amount_1 = 0.0
IF @user_amount_2 IS NULL 
	SELECT @user_amount_2 = 0.0
IF @user_amount_3 IS NULL 
	SELECT @user_amount_3 = 0.0
IF @user_amount_4 IS NULL 
	SELECT @user_amount_4 = 0.0
IF @user_amount_5 IS NULL 
	SELECT @user_amount_5 = 0.0

IF @user_code_1 IS NULL 
	SELECT @user_code_1 = ' '
IF @user_code_2 IS NULL 
	SELECT @user_code_2 = ' '
IF @user_code_3 IS NULL 
	SELECT @user_code_3 = ' '
IF @user_code_4 IS NULL 
	SELECT @user_code_4 = ' '
IF @user_code_5 IS NULL 
	SELECT @user_code_5 = ' '




 

insert into amusrfld 
( 
	user_field_id,
	user_code_1,
	user_code_2,
	user_code_3,
	user_code_4,
	user_code_5,
	user_date_1,
	user_date_2,
	user_date_3,
	user_date_4,
	user_date_5,
	user_amount_1,
	user_amount_2,
	user_amount_3,
	user_amount_4,
	user_amount_5 
)
values 
( 
	@user_field_id,
	@user_code_1,
	@user_code_2,
	@user_code_3,
	@user_code_4,
	@user_code_5,
	@user_date_1,
	@user_date_2,
	@user_date_3,
	@user_date_4,
	@user_date_5,
	@user_amount_1,
	@user_amount_2,
	@user_amount_3,
	@user_amount_4,
	@user_amount_5 
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amusrfldInsert_sp] TO [public]
GO
