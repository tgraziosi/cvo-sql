SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[icv_log_events_sp] 
	@cca_trx_ctrl_num 	varchar(16),
	@customer_code		varchar(18),
	@payment_code		varchar(8),
	@cc_number		varchar (20),
	@trx_requested		varchar(3),
	@amount_org		float,
	@amount_trx		float,
	@currency_code		varchar(8),
	@auth_code		varchar(6),	
	@pttd_code		varchar(16),
	@user_id		smallint,
	@response_code		smallint,
	@orig_no			int=0,
	@reference		varchar(16)='',
	@provider		smallint
AS
BEGIN

	DECLARE	@sys_date	int
	EXEC appdate_sp @sys_date OUTPUT

	INSERT INTO icv_events (cca_trx_ctrl_num, customer_code, payment_code, 
					cc_number,date_requested,
					trx_requested, 	amount, currency_code, 	auth_code, pttd_code,
					user_id,	response_code, orig_no,  reference, julian_date,
					provider)	 
				VALUES (@cca_trx_ctrl_num,@customer_code,@payment_code,
					substring(@cc_number,1,4)+'********'+substring(@cc_number,13,4),GETDATE(),
					@trx_requested,@amount_trx, @currency_code,@auth_code,@pttd_code,
					1, @response_code,  @orig_no,isnull(@reference,''),@sys_date,
					@provider)
	IF @provider=1 
	BEGIN
		IF @trx_requested='D' AND @amount_org-@amount_trx>0 AND LEN(@auth_code)>0
		BEGIN
		  INSERT INTO icv_events (cca_trx_ctrl_num, customer_code, payment_code, 
					cc_number,date_requested,
					trx_requested, 	amount, currency_code, 	auth_code, pttd_code,
					user_id,	response_code, orig_no,  reference, julian_date,
					provider)	 
				VALUES (@cca_trx_ctrl_num,@customer_code,@payment_code,
					substring(@cc_number,1,4)+'********'+substring(@cc_number,13,4),GETDATE(),
					'C',@amount_org-@amount_trx, @currency_code,@auth_code,'',
					1, @response_code,  @orig_no,isnull(@reference,''),@sys_date,
					@provider)
		END 
		IF @trx_requested='S' AND LEN(@auth_code)>0
			BEGIN
			  INSERT INTO icv_events (cca_trx_ctrl_num, customer_code, payment_code, 
						cc_number,date_requested,
						trx_requested, 	amount, currency_code, 	auth_code, pttd_code,
						user_id,	response_code, orig_no,  reference, julian_date,
						provider)	 
					VALUES (@cca_trx_ctrl_num,@customer_code,@payment_code,
						substring(@cc_number,1,4)+'********'+substring(@cc_number,13,4),GETDATE(),
						'D',@amount_trx, @currency_code,@auth_code,'',
						1, 2050, @orig_no,isnull(@reference,''),@sys_date,
						@provider)
			END 
	END
	
	END
GO
GRANT EXECUTE ON  [dbo].[icv_log_events_sp] TO [public]
GO
