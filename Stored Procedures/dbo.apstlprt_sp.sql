SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[apstlprt_sp] @settlement_ctrl_num varchar(16)
AS
BEGIN

DECLARE
	@pay_trx_ctrl_num	varchar(16),
	@vo_trx_ctrl_num	varchar(16),
	@pay_amt_applied	float,
	@vo_amt_applied		float,
	@cross_rate		float,
	@amt_gain		float,
	@vo_amt_paid_date	float,
	@pay_apply_date		int,
	@vo_apply_date		int,
	@pay_rate_home		float,
	@pay_rate_oper		float,
	@vo_rate_home		float,
	@vo_rate_oper		float,
	@payv_rate_home		float,
	@payv_rate_oper		float,
	@vop_rate_home		float,
	@vop_rate_oper		float,
	@pay_cur_code		varchar(8),
	@vo_cur_code		varchar(8),
	@pay_rate_type_home	varchar(8),
	@pay_rate_type_oper	varchar(8),
	@vo_rate_type_home	varchar(8),
	@vo_rate_type_oper	varchar(8),
	@divide_flag_h		smallint,
	@home_currency		varchar(8),
	@oper_currency		varchar(8),
	@amt_gl_home		float,
	@amt_gl_oper		float,
	@voucher_num		varchar(16),
	@amtv_gain_home		float,
	@amtv_gain_oper		float,
	@amt_gain_home		float,
	@amt_gain_oper		float,
	@sequence		int,
	@result			int,
	@debug_level		int,
	@payv_amt_applied	float,
	@wr_ammount		float,
	@pay_count	  	int,
	@count		  	int,
	@percent		float,
	@amount_for_vo		float,
	@new_vo_amt_applied 	float,
	@new_vo_amt_paid_date 	float,
	@new_vo_amt_disc_taken  float,
	@new_pay_amt_disc_taken float,
	@vo_amt_disc_taken	float,
	@pay_amt_disc_taken	float,
	@new_pay_amt_applied    float,  
	@home_precision		int,
	@oper_precision		int,
	@negative_vouchers	smallint
	




select @sequence = 1

select @negative_vouchers = 1	


select @home_currency =  home_currency  , @oper_currency = oper_currency from glco

SELECT @home_precision = curr_precision
FROM glcurr_vw
WHERE currency_code = @home_currency

SELECT @oper_precision = curr_precision
FROM glcurr_vw
WHERE currency_code = @oper_currency












Select @vo_trx_ctrl_num = MIN(apply_to_num) from #apinppdt3450
where trx_ctrl_num = @settlement_ctrl_num
and amt_applied < 0

IF @vo_trx_ctrl_num IS NULL
	Select @vo_trx_ctrl_num = MIN(apply_to_num), 
		@negative_vouchers = 0 
	from #apinppdt3450
	where trx_ctrl_num = @settlement_ctrl_num
	

Select @pay_trx_ctrl_num = MIN(trx_ctrl_num) from #apinppyt3450
where settlement_ctrl_num = @settlement_ctrl_num


select @pay_amt_applied = doc_amount, 
	@pay_apply_date = date_applied, 
	@pay_rate_home = rate_home, 
	@pay_rate_oper = rate_oper, 
	@pay_cur_code = nat_cur_code, 
	@pay_rate_type_home = rate_type_home, 
	@pay_rate_type_oper = rate_type_oper
from #apinppyt3450 
where trx_ctrl_num  = @pay_trx_ctrl_num


select @payv_amt_applied = amt_applied, 
	@vo_amt_applied = vo_amt_applied, 
	@voucher_num = apply_to_num,
	@vo_cur_code = nat_cur_code,
	@cross_rate = cross_rate,
	@vo_amt_disc_taken = vo_amt_disc_taken,
	@pay_amt_disc_taken = amt_disc_taken
from #apinppdt3450  
where apply_to_num  = @vo_trx_ctrl_num 


select @vo_rate_home = rate_home, 
	@vo_rate_oper = rate_oper, 
	@vo_rate_type_home = rate_type_home, 
	@vo_rate_type_oper = rate_type_oper,
	@vo_apply_date = date_doc 
from apvohdr 
where trx_ctrl_num =  @vo_trx_ctrl_num


select @count = 1

select @pay_count = count(*) 
from #apinppdt3450
where trx_ctrl_num = @settlement_ctrl_num




if @pay_count = 0
	return 





CREATE TABLE #apinppdt_disc_taken
(
trx_ctrl_num	varchar(16),
amt_disc_taken	float
)


select @pay_count = count(*) from #apinppyt3450


while (@pay_count >= @count)
BEGIN


if (ABS((@pay_amt_applied)-(0.0)) < 0.0000001)
BEGIN	
	Select @pay_trx_ctrl_num = MIN(trx_ctrl_num) from #apinppyt3450 
	where trx_ctrl_num > @pay_trx_ctrl_num
	and settlement_ctrl_num = @settlement_ctrl_num

	IF @pay_trx_ctrl_num IS NULL
		break

	
	select @pay_amt_applied = doc_amount, 
		@pay_apply_date = date_applied, 
		@pay_rate_home = rate_home, 
		@pay_rate_oper = rate_oper, 
		@pay_cur_code = nat_cur_code, 
		@pay_rate_type_home = rate_type_home, 
		@pay_rate_type_oper = rate_type_oper
	from #apinppyt3450 
	where trx_ctrl_num  = @pay_trx_ctrl_num


	SELECT @count = @count + 1

	SELECT  @sequence = 1				
END		

if (ABS((@vo_amt_applied)-(0.0)) < 0.0000001)
BEGIN	
	
	

 
	IF @negative_vouchers = 1 
		Select @vo_trx_ctrl_num = MIN(apply_to_num)
        	from #apinppdt3450 
		where apply_to_num  > @vo_trx_ctrl_num
		and trx_ctrl_num = @settlement_ctrl_num
		and amt_applied < 0


	


	IF @vo_trx_ctrl_num IS NULL OR @negative_vouchers = 0 
	BEGIN
		IF @negative_vouchers = 1
		BEGIN
			Select @vo_trx_ctrl_num = MIN(apply_to_num) 			
			from #apinppdt3450
			where trx_ctrl_num = @settlement_ctrl_num
			and amt_applied > 0

			SELECT @negative_vouchers = 0 
		END
		ELSE
			Select @vo_trx_ctrl_num = MIN(apply_to_num)
			from #apinppdt3450
			where apply_to_num  > @vo_trx_ctrl_num
			and trx_ctrl_num = @settlement_ctrl_num
			and amt_applied > 0
	END

	IF @vo_trx_ctrl_num IS NULL
		break

	select @payv_amt_applied = amt_applied, 
		@vo_amt_applied = vo_amt_applied, 
		@voucher_num = apply_to_num,
		@vo_cur_code = nat_cur_code,
		@cross_rate = cross_rate,
		@vo_amt_disc_taken = vo_amt_disc_taken,
		@pay_amt_disc_taken = amt_disc_taken
	from #apinppdt3450  
	where apply_to_num  = @vo_trx_ctrl_num 
	and trx_ctrl_num = @settlement_ctrl_num					


	select @vo_rate_home = rate_home, 
		@vo_rate_oper = rate_oper, 
		@vo_rate_type_home = rate_type_home, 
		@vo_rate_type_oper = rate_type_oper,
		@vo_apply_date = date_doc 
	from apvohdr 
	where trx_ctrl_num =  @vo_trx_ctrl_num

END	



if ((@pay_amt_applied) >= (@payv_amt_applied) - 0.0000001)
BEGIN
	select @percent = 1

	select @pay_amt_applied = @pay_amt_applied - @payv_amt_applied 
	
	select @amount_for_vo = @payv_amt_applied,
		@new_vo_amt_applied = @vo_amt_applied, 
		@new_vo_amt_disc_taken = @vo_amt_disc_taken,
		@new_pay_amt_disc_taken = @pay_amt_disc_taken,
		@new_pay_amt_applied = @payv_amt_applied 		 

	SELECT @vo_amt_applied = 0

	
	select @amt_gain = @payv_amt_applied 	

	
END	
ELSE
BEGIN
	
	select @percent = @pay_amt_applied/@payv_amt_applied

	select @amount_for_vo = @pay_amt_applied,
		@new_vo_amt_applied = ROUND(@vo_amt_applied * @percent, 2), 
		@new_vo_amt_disc_taken = ROUND(@vo_amt_disc_taken * @percent, 2),
		@new_pay_amt_disc_taken = ROUND(@pay_amt_disc_taken * @percent, 2),
		@new_pay_amt_applied =@pay_amt_applied  

	select @payv_amt_applied = @payv_amt_applied - @pay_amt_applied, 
		@vo_amt_applied = @vo_amt_applied - @new_vo_amt_applied, 
		@vo_amt_disc_taken = @vo_amt_disc_taken - @new_vo_amt_disc_taken,
		@pay_amt_disc_taken = @pay_amt_disc_taken - @new_pay_amt_disc_taken

	select @amt_gain = @pay_amt_applied


	select @pay_amt_applied = 0

END
	
if @pay_apply_date < @vo_apply_date
BEGIN	

	IF @pay_cur_code = @vo_cur_code
	BEGIN
		SELECT @payv_rate_home = @vo_rate_home,
			@payv_rate_oper = @vo_rate_oper
	END
	ELSE
	BEGIN
		EXEC @result = CVO_Control..mccurate_sp
			@vo_apply_date,
			@pay_cur_code,	
			@home_currency,		
			@pay_rate_type_home,	
			@payv_rate_home		OUTPUT,
			0,
			@divide_flag_h		OUTPUT

		EXEC @result = CVO_Control..mccurate_sp
			@vo_apply_date,
			@pay_cur_code,	
			@oper_currency,		
			@pay_rate_type_oper,	
			@payv_rate_oper		OUTPUT,
			0,
			@divide_flag_h		OUTPUT
	END

	if @pay_rate_home <> @payv_rate_home or @pay_rate_oper <> @payv_rate_oper
	BEGIN
		
		SELECT @amt_gain_home = CASE
					 WHEN @payv_rate_home > 0 THEN @amt_gain * @payv_rate_home
					 ELSE @amt_gain / ABS(@payv_rate_home)
					END

		SELECT @amt_gain_home = ROUND(@amt_gain_home, @home_precision)

		SELECT @amt_gl_home = CASE
					 WHEN @pay_rate_home > 0 THEN  @amt_gain_home - ROUND((@amt_gain * @pay_rate_home), @home_precision)
					 ELSE  @amt_gain_home - ROUND(@amt_gain / ABS(@pay_rate_home), @home_precision)
					END

		SELECT @amt_gain_oper = CASE
					 WHEN @payv_rate_oper > 0 THEN @amt_gain * @payv_rate_oper
					 ELSE @amt_gain / ABS(@payv_rate_oper)
					END

		SELECT @amt_gain_oper = ROUND(@amt_gain_oper, @oper_precision)

		SELECT @amt_gl_oper = CASE
					 WHEN @pay_rate_oper > 0 THEN ROUND((@amt_gain * @pay_rate_oper), @oper_precision) - @amt_gain_oper
					 ELSE @amt_gain_oper - ROUND(@amt_gain / ABS(@pay_rate_oper), @oper_precision)
					END		
		


	END
END
ELSE
BEGIN

	IF @pay_cur_code = @vo_cur_code
	BEGIN
		SELECT @vop_rate_home = @pay_rate_home,
			@vop_rate_oper = @pay_rate_oper
	END
	ELSE
	BEGIN
		EXEC @result = CVO_Control..mccurate_sp
			@pay_apply_date,
			@vo_cur_code,	
			@home_currency,		
			@vo_rate_type_home,	
			@vop_rate_home		OUTPUT,
			0,
			@divide_flag_h		OUTPUT

		EXEC @result = CVO_Control..mccurate_sp
			@pay_apply_date,
			@vo_cur_code,	
			@oper_currency,		
			@vo_rate_type_oper,	
			@vop_rate_oper		OUTPUT,
			0,
			@divide_flag_h		OUTPUT
	END

	if @vo_rate_home <> @vop_rate_home or @vo_rate_oper <> @vop_rate_oper
	BEGIN

		SELECT @amt_gain_home = CASE
					 WHEN @vop_rate_home > 0 THEN @amt_gain * @vop_rate_home
					 ELSE @amt_gain / ABS(@vop_rate_home)
					END

		SELECT @amt_gain_home = ROUND(@amt_gain_home, @home_precision)

		SELECT @amt_gl_home = CASE
					 WHEN @vo_rate_home > 0 THEN  @amt_gain_home - ROUND((@amt_gain * @vo_rate_home), @home_precision)
					 ELSE @amt_gain_home - ROUND(@amt_gain / ABS(@vo_rate_home), @home_precision)
					END

		SELECT @amt_gain_oper = CASE
					 WHEN @vop_rate_oper > 0 THEN @amt_gain * @vop_rate_oper
					 ELSE @amt_gain / ABS(@vop_rate_oper)
					END

		SELECT @amt_gain_oper = ROUND(@amt_gain_oper, @oper_precision)

		SELECT @amt_gl_oper = CASE
					 WHEN @vo_rate_oper > 0 THEN @amt_gain_oper - ROUND((@amt_gain * @vo_rate_oper), @oper_precision)
					 ELSE @amt_gain_oper - ROUND(@amt_gain / ABS(@vo_rate_oper), @oper_precision)
					END		

		
	END

END

	insert into #apinppdt3450 
	select 
	NULL,
	@pay_trx_ctrl_num,
	i.trx_type,
	@sequence,					
	i.apply_to_num,
	i.apply_trx_type,
	@new_pay_amt_applied,                           
	@new_pay_amt_disc_taken,
	i.line_desc,
	i.void_flag,
	i.payment_hold_flag,	
	i.vendor_code,
	@new_vo_amt_applied,
	@new_vo_amt_disc_taken,
	ISNULL(@amt_gl_home,0.0),
	ISNULL(@amt_gl_oper,0.0),
	i.nat_cur_code,
	i.cross_rate,
	i.org_id
	from #apinppdt3450 i, #apinppyt3450 c
	where i.apply_to_num = @vo_trx_ctrl_num
	and   c.trx_ctrl_num = @pay_trx_ctrl_num
	AND   i.trx_ctrl_num = @settlement_ctrl_num				

	
	select @vo_amt_paid_date = @vo_amt_paid_date + @vo_amt_applied

	select @sequence = @sequence + 1
	

END

INSERT INTO #apinppdt_disc_taken
SELECT 		trx_ctrl_num, SUM(amt_disc_taken)
FROM		#apinppdt3450
GROUP BY	trx_ctrl_num


UPDATE 	#apinppyt3450
SET 	amt_disc_taken = b.amt_disc_taken
FROM	#apinppyt3450 a, #apinppdt_disc_taken b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num

DROP TABLE #apinppdt_disc_taken

delete #apinppdt3450 where trx_ctrl_num = @settlement_ctrl_num



END

GO
GRANT EXECUTE ON  [dbo].[apstlprt_sp] TO [public]
GO
