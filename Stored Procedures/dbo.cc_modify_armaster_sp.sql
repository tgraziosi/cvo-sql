SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_modify_armaster_sp]	@customer_code		varchar(16),
																				@attention_name		varchar(40),
																				@attention_phone	varchar(30),
																				@contact_name		varchar(40),
																				@contact_phone		varchar(30),
																				@credit_limit		float,
																				@check_limit		tinyint	= 0,
																				@status_type		smallint = 0,
																				@db_num				varchar(20) = ''	,
																						
																				@db_date varchar(20) = '',
																				@db_credit_rating varchar(20) = '',
																				@tlx_twx			varchar(30) = '',

																				@url					varchar(255) = '',
																				@user_name		varchar(30) = '',
																			
																				@terms varchar(8),
																				@territory varchar(8),
																				@salesperson varchar(8),
																				@city varchar(40),
																				@postal varchar(15),
																				@addr1 varchar(40),
																				@addr2 varchar(40),
																				@addr3 varchar(40),
																				@addr4 varchar(40),
																				@addr5 varchar(40),
																				@addr6 varchar(40),
																				@state varchar(40),
																				@country varchar(40),
																				@phone1 varchar(30),
																				@phone2 varchar(30)




AS
	IF @user_name = ''
		SELECT @user_name = [user_name] FROM cvo_control..smusers WHERE [user_name] = SUSER_SNAME()

	IF @status_type = 0
		UPDATE	armaster
		SET 		attention_name = @attention_name,
					attention_phone = @attention_phone,
					contact_name = @contact_name,
					contact_phone = @contact_phone,
					credit_limit = @credit_limit,
					check_credit_limit = @check_limit,
					db_num = @db_num,
			
					db_date = CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(@db_date))),0) > 0 THEN DATEDIFF(dd, '1/1/1753', @db_date) + 639906 ELSE 0 END,
					db_credit_rating = @db_credit_rating,
					tlx_twx = @tlx_twx,
					url = @url,

					modified_by_user_name = @user_name,
					modified_by_date = GETDATE(),
					terms_code = @terms,
					territory_code = @territory,
					salesperson_code = @salesperson ,
					city = @city,
					state = @state,
					addr1 = @addr1,
					addr2 = @addr2,
					addr3 = @addr3,
					addr4 = @addr4,
					addr5 = @addr5,
					addr6 = @addr6,
					postal_code = @postal,
					country = @country,
					phone_1 = @phone1,
					phone_2 = @phone2
		WHERE 	customer_code = @customer_code

		AND		address_type = 0
	ELSE
		UPDATE	armaster
		SET		attention_name = @attention_name,
					attention_phone = @attention_phone,
					contact_name = @contact_name,
					contact_phone = @contact_phone,
					credit_limit = @credit_limit,
					check_credit_limit = @check_limit,
					status_type = @status_type,
					db_num = @db_num,
			
					db_date = CASE WHEN ISNULL(DATALENGTH(RTRIM(LTRIM(@db_date))),0) > 0 THEN DATEDIFF(dd, '1/1/1753', @db_date) + 639906 ELSE 0 END,
					db_credit_rating = @db_credit_rating,
					tlx_twx = @tlx_twx,
					url = @url,

					modified_by_user_name = @user_name,
					modified_by_date = GETDATE(),
					terms_code = @terms,
					territory_code = @territory,
					salesperson_code = @salesperson ,
					city = @city,
					state = @state,
					addr1 = @addr1,
					addr2 = @addr2,
					addr3 = @addr3,
					addr4 = @addr4,
					addr5 = @addr5,
					addr6 = @addr6,
					country = @country,
					postal_code = @postal,
					phone_1 = @phone1,
					phone_2 = @phone2
		WHERE 	customer_code = @customer_code
		AND		address_type = 0



GO
GRANT EXECUTE ON  [dbo].[cc_modify_armaster_sp] TO [public]
GO
