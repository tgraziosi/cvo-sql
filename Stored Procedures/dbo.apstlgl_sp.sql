SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[apstlgl_sp] @settlement_ctrl_num varchar(16)
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
	@amti_gain_home		float,
	@amti_gain_oper		float,
	@amt_gain_home		float,
	@amt_gain_oper		float,
	@sequence		int,
	@result			int,
	@debug_level		int,
	@vop_amt_applied	float,
	@rec_count	  	int,
	@count		  	int,
	@percent		float,
	@amount_for_voucher	float,
	@new_vop_amt_applied   float,
	@new_vo_amt_applied 	float,
	@new_vo_amt_paid_date 	float,
	@new_vo_amt_disc_taken float,
	@new_pay_amt_disc_taken float,
	@new_pay_amt_max_wr_off float,
	@new_vo_amt_max_wr_off float,
	@vo_amt_disc_taken	float,
	@pay_amt_disc_taken	float,
	@home_precision		int,		
	@oper_precision		int,
	@negative_vouchers	smallint

select @sequence = 1

select @negative_vouchers = 1	

/*HOME AND OPER CURRENCY*/
select @home_currency =  home_currency  , @oper_currency = oper_currency from glco

SELECT @home_precision = curr_precision
FROM glcurr_vw
WHERE currency_code = @home_currency

SELECT @oper_precision = curr_precision
FROM glcurr_vw
WHERE currency_code = @oper_currency

/*
** USED TABLES, ALREADY CREATED
** #apinppyt3450, #apinppdt3450
*/

Select @vo_trx_ctrl_num = MIN(apply_to_num) from #apinppdt3450
where trx_ctrl_num = @settlement_ctrl_num
and amt_applied < 0

IF @vo_trx_ctrl_num IS NULL
	Select @vo_trx_ctrl_num = MIN(apply_to_num), 
		@negative_vouchers = 0 
	from #apinppdt3450
	where trx_ctrl_num = @settlement_ctrl_num


Select @pay_trx_ctrl_num = MIN(trx_ctrl_num) from #apinppytgl
where settlement_ctrl_num = @settlement_ctrl_num

/*PAYMENT INFO*/
select @pay_amt_applied = amt_payment, 
	@pay_apply_date = date_applied, 
	@pay_rate_home = rate_home, 
	@pay_rate_oper = rate_oper, 
	@pay_cur_code = nat_cur_code, 
	@pay_rate_type_home = rate_type_home, 
	@pay_rate_type_oper = rate_type_oper
from #apinppytgl 
where trx_ctrl_num  = @pay_trx_ctrl_num


select @vop_amt_applied = t.amt_applied, 
	@vo_amt_applied = t.vo_amt_applied, 
	@vo_apply_date = f.date_doc, 
	@vo_cur_code = t.nat_cur_code, 
	@voucher_num = t.apply_to_num, 
	@cross_rate = t.cross_rate,
	@vo_amt_paid_date = f.amt_paid_to_date,
	@vo_amt_disc_taken = t.vo_amt_disc_taken,
	@pay_amt_disc_taken = t.amt_disc_taken
from aptrxapl_vw f, #apinppdt3450 t  
where t.apply_to_num  = @vo_trx_ctrl_num 
AND   f.apply_to_num = t.apply_to_num

select @vo_rate_home = rate_home, 
	@vo_rate_oper = rate_oper, 
	@vo_rate_type_home = rate_type_home, 
	@vo_rate_type_oper = rate_type_oper
from apvohdr 
where trx_ctrl_num =  @vo_trx_ctrl_num


select @count = 1

select @rec_count = count(*) 
from #apinppdt3450
where trx_ctrl_num = @settlement_ctrl_num

/*
** If there are no records in apinppdt, abort
*/
if @rec_count = 0
	return 

select @rec_count = count(*) from #apinppytgl

/* MAYOR CYCLE */
while (@rec_count >= @count)
BEGIN


if (ABS((@pay_amt_applied)-(0.0)) < 0.0000001)
BEGIN	
	Select @pay_trx_ctrl_num = MIN(trx_ctrl_num) from #apinppytgl 
	where trx_ctrl_num > @pay_trx_ctrl_num
	and settlement_ctrl_num = @settlement_ctrl_num

	IF @pay_trx_ctrl_num IS NULL
		break

	/*PAYMENT INFO*/
	select @pay_amt_applied = amt_payment, 
		@pay_apply_date = date_applied, 
		@pay_rate_home = rate_home, 
		@pay_rate_oper = rate_oper, 
		@pay_cur_code = nat_cur_code, 
		@pay_rate_type_home = rate_type_home, 
		@pay_rate_type_oper = rate_type_oper
	from #apinppytgl 
	where trx_ctrl_num  = @pay_trx_ctrl_num

	SELECT @count = @count + 1
END		

if (ABS((@vo_amt_applied)-(0.0)) < 0.0000001)
BEGIN	
	/* Select @vo_trx_ctrl_num = NULL Dpardo If you nullify this value the following selects won't work SP 4*/

	IF @negative_vouchers = 1 
		Select @vo_trx_ctrl_num = MIN(apply_to_num)
        	from #apinppdt3450 
		where apply_to_num  > @vo_trx_ctrl_num
		and trx_ctrl_num = @settlement_ctrl_num
		and amt_applied < 0

	/*
	** Start applying the receipts on positive vouchers
	*/
	IF @vo_trx_ctrl_num IS NULL OR @negative_vouchers = 0 
	BEGIN
		IF @negative_vouchers = 1
			Select @vo_trx_ctrl_num = MIN(apply_to_num), 
				@negative_vouchers = 0 
			from #apinppdt3450
			where trx_ctrl_num = @settlement_ctrl_num
			and amt_applied > 0
		ELSE
			Select @vo_trx_ctrl_num = MIN(apply_to_num), 
				@negative_vouchers = 0 
			from #apinppdt3450
			where apply_to_num  > @vo_trx_ctrl_num
			and trx_ctrl_num = @settlement_ctrl_num
			and amt_applied > 0
	END

	IF @vo_trx_ctrl_num IS NULL
		break

	select @vop_amt_applied = t.amt_applied, 
		@vo_amt_applied = t.vo_amt_applied, 
		@vo_apply_date = f.date_doc, 
		@vo_cur_code = t.nat_cur_code, 
		@voucher_num = f.apply_to_num, 
		@cross_rate = t.cross_rate,
		@vo_amt_paid_date = f.amt_paid_to_date,
		@vo_amt_disc_taken = t.vo_amt_disc_taken,
		@pay_amt_disc_taken = t.amt_disc_taken
	from  aptrxapl_vw f, #apinppdt3450 t
	where t.apply_to_num  = @vo_trx_ctrl_num 
	AND   f.apply_to_num = t.apply_to_num

	/*VOUCHER INFO*/

	select @vo_rate_home = rate_home, 
		@vo_rate_oper = rate_oper, 
		@vo_rate_type_home = rate_type_home, 
		@vo_rate_type_oper = rate_type_oper
	from apvohdr 
	where trx_ctrl_num =  @vo_trx_ctrl_num

END	



if ((@pay_amt_applied) >= (@vop_amt_applied) - 0.0000001)
BEGIN
	select @percent = 1

	select @pay_amt_applied = @pay_amt_applied - @vop_amt_applied 
	
	select @amount_for_voucher = @vop_amt_applied,
		@new_vo_amt_applied = @vo_amt_applied, 
		@new_vo_amt_paid_date = @vo_amt_paid_date,
		@new_vo_amt_disc_taken = @vo_amt_disc_taken,
		@new_pay_amt_disc_taken = @pay_amt_disc_taken

	SELECT @vo_amt_applied = 0
	/* Receipt currency */
	select @amt_gain = @vop_amt_applied 	

	
END	
ELSE
BEGIN
	/* Get the percentage of the invoice covered by the receipt */
	select @percent = @pay_amt_applied/@vop_amt_applied

	select @amount_for_voucher = @pay_amt_applied,
		@new_vo_amt_applied = ROUND(@vo_amt_applied * @percent, 2), 
		@new_vo_amt_paid_date = ROUND(@vo_amt_paid_date * @percent, 2),
		@new_vo_amt_disc_taken = ROUND(@vo_amt_disc_taken * @percent, 2),
		@new_pay_amt_disc_taken = ROUND(@pay_amt_disc_taken * @percent, 2)

	select @vop_amt_applied = @vop_amt_applied - @pay_amt_applied, 
		@vo_amt_applied = @vo_amt_applied - @new_vo_amt_applied, 
		@vo_amt_paid_date = @vo_amt_paid_date - @new_vo_amt_paid_date,
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
					END,
			@amt_gain_home = ROUND(@amt_gain_home, @home_precision),	
			@amt_gl_home = CASE
					 WHEN @pay_rate_home > 0 THEN @amt_gain_home - ROUND((@amt_gain * @pay_rate_home), @home_precision)
					 ELSE @amt_gain_home - ROUND(@amt_gain / ABS(@pay_rate_home), @home_precision)
					END,
			@amt_gain_oper = CASE
					 WHEN @payv_rate_oper > 0 THEN @amt_gain * @payv_rate_oper
					 ELSE @amt_gain / ABS(@payv_rate_oper)
					END,
			@amt_gain_oper = ROUND(@amt_gain_oper, @oper_precision),
			@amt_gl_oper = CASE
					 WHEN @pay_rate_oper > 0 THEN @amt_gain_oper - ROUND((@amt_gain * @pay_rate_oper), @oper_precision)
					 ELSE @amt_gain_oper - ROUND(@amt_gain / ABS(@pay_rate_oper), @oper_precision)
					END		
		

		/*INSERT INTO #GAIN_LOSS*/ 
			
		insert into #ap_gain_loss
		select 
		@settlement_ctrl_num,
		@pay_trx_ctrl_num,
		@sequence,
		c.doc_ctrl_num,
		@cross_rate,
		@amt_gl_home,
		@amt_gl_oper,
		@payv_rate_home,
		@payv_rate_oper,
		@pay_rate_home,
		@pay_rate_oper
		from  #apinppytgl c
		where 	c.trx_ctrl_num = @pay_trx_ctrl_num

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
					END,
			@amt_gain_home = ROUND(@amt_gain_home, @home_precision),	
			@amt_gl_home = CASE
					 WHEN @vo_rate_home > 0 THEN @amt_gain_home - ROUND((@amt_gain * @vo_rate_home), @home_precision)
					 ELSE @amt_gain_home - ROUND(@amt_gain / ABS(@vo_rate_home), @home_precision) 
					END,
			@amt_gain_oper = CASE
					 WHEN @vop_rate_oper > 0 THEN @amt_gain * @vop_rate_oper
					 ELSE @amt_gain / ABS(@vop_rate_oper)
					END,
			@amt_gain_oper = ROUND(@amt_gain_oper, @oper_precision),
			@amt_gl_oper = CASE
					 WHEN @vo_rate_oper > 0 THEN @amt_gain_oper - ROUND((@amt_gain * @vo_rate_oper), @oper_precision)
					 ELSE @amt_gain_oper - ROUND(@amt_gain / ABS(@vo_rate_oper), @oper_precision)
					END		

		/*INSERT INTO #GAIN_LOSS*/ 

		insert into #ap_gain_loss
		values(
		@settlement_ctrl_num,
		@pay_trx_ctrl_num,
		@sequence,
		@vo_trx_ctrl_num,
		@cross_rate,
		@amt_gl_home,
		@amt_gl_oper,
		@vop_rate_home,
		@vop_rate_oper,
		@vo_rate_home,
		@vo_rate_oper)
	END

END

	select @vo_amt_paid_date = @vo_amt_paid_date + @vo_amt_applied

	select @sequence = @sequence + 1
	

END



END

GO
GRANT EXECUTE ON  [dbo].[apstlgl_sp] TO [public]
GO
