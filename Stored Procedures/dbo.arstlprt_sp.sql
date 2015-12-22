SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arstlprt_sp] @settlement_ctrl_num varchar(16)
AS
BEGIN

DECLARE
	@rec_trx_ctrl_num	varchar(16),
	@inv_trx_ctrl_num	varchar(16),
	@rec_amt_applied	float,
	@inv_amt_applied	float,
	@cross_rate		float,
	@amt_gain		float,
	@inv_amt_paid_date	float,
	@rec_apply_date		int,
	@inv_apply_date		int,
	@rec_rate_home		float,
	@rec_rate_oper		float,
	@inv_rate_home		float,
	@inv_rate_oper		float,
	@reci_rate_home		float,
	@reci_rate_oper		float,
	@invr_rate_home		float,
	@invr_rate_oper		float,
	@rec_cur_code		varchar(8),
	@inv_cur_code		varchar(8),
	@rec_rate_type_home	varchar(8),
	@rec_rate_type_oper	varchar(8),
	@inv_rate_type_home	varchar(8),
	@inv_rate_type_oper	varchar(8),
	@divide_flag_h		smallint,
	@home_currency		varchar(8),
	@oper_currency		varchar(8),
	@amt_gl_home		float,
	@amt_gl_oper		float,
	@invoice_num		varchar(16),
	@amti_gain_home		float,
	@amti_gain_oper		float,
	@amt_gain_home		float,
	@amt_gain_oper		float,
	@sequence		int,
	@result			int,
	@debug_level		int,
	@invr_amt_applied	float,
	@wr_ammount		float,
	@rec_count	  	int,
	@count		  	int,
	@percent		float,
	@amount_for_invoice	float,
	@new_invr_amt_applied   float,
	@new_inv_amt_applied 	float,
	@new_inv_amt_paid_date 	float,
	@new_inv_amt_disc_taken float,
	@new_rec_amt_disc_taken float,
	@new_rec_amt_max_wr_off float,
	@new_inv_amt_max_wr_off float,
	@new_write_off_amount	float,
	@write_off_amount	float,
	@inv_amt_disc_taken	float,
	@rec_amt_disc_taken	float,
	@rec_amt_max_wr_off	float,
	@inv_amt_max_wr_off	float,
	@home_precision		int,
	@oper_precision		int


select @sequence = 1


select @home_currency =  home_currency  , @oper_currency = oper_currency from glco

SELECT @home_precision = curr_precision
FROM glcurr_vw
WHERE currency_code = @home_currency

SELECT @oper_precision = curr_precision
FROM glcurr_vw
WHERE currency_code = @oper_currency










Select @inv_trx_ctrl_num = MIN(apply_to_num) from #arinppdt4750
where trx_ctrl_num = @settlement_ctrl_num

Select @rec_trx_ctrl_num = MIN(trx_ctrl_num) from #arinppyt4750
where settlement_ctrl_num = @settlement_ctrl_num


select @rec_amt_applied = doc_amount, 
	@rec_apply_date = date_applied, 
	@rec_rate_home = rate_home, 
	@rec_rate_oper = rate_oper, 
	@rec_cur_code = nat_cur_code, 
	@rec_rate_type_home = rate_type_home, 
	@rec_rate_type_oper = rate_type_oper
from #arinppyt4750 
where trx_ctrl_num  = @rec_trx_ctrl_num


select @invr_amt_applied = amt_applied, 
	@inv_amt_applied = inv_amt_applied, 
	@inv_apply_date = date_doc, 
	@inv_cur_code = inv_cur_code, 
	@invoice_num = apply_to_num, 
	@cross_rate = cross_rate,
	@inv_amt_paid_date = amt_paid_to_date,
	@inv_amt_disc_taken = inv_amt_disc_taken,
	@rec_amt_disc_taken = amt_disc_taken,
	@rec_amt_max_wr_off = amt_max_wr_off,
	@inv_amt_max_wr_off = inv_amt_max_wr_off,
	@write_off_amount = writeoff_amount
from #arinppdt4750  
where apply_to_num  = @inv_trx_ctrl_num 

select @inv_rate_home = rate_home, 
	@inv_rate_oper = rate_oper, 
	@inv_rate_type_home = rate_type_home, 
	@inv_rate_type_oper = rate_type_oper
from artrx 
where doc_ctrl_num =  @inv_trx_ctrl_num


select @count = 1

select @rec_count = count(*) 
from #arinppdt4750
where trx_ctrl_num = @settlement_ctrl_num




if @rec_count = 0
	return 

select @rec_count = count(*) from #arinppyt4750


while (@rec_count >= @count)
BEGIN


if (ABS((@rec_amt_applied)-(0.0)) < 0.0000001)
BEGIN	
	Select @rec_trx_ctrl_num = MIN(trx_ctrl_num) from #arinppyt4750 
	where trx_ctrl_num > @rec_trx_ctrl_num
	and settlement_ctrl_num = @settlement_ctrl_num

	IF @rec_trx_ctrl_num IS NULL
		BREAK

	
	select @rec_amt_applied = doc_amount, 
		@rec_apply_date = date_applied, 
		@rec_rate_home = rate_home, 
		@rec_rate_oper = rate_oper, 
		@rec_cur_code = nat_cur_code, 
		@rec_rate_type_home = rate_type_home, 
		@rec_rate_type_oper = rate_type_oper
	from #arinppyt4750 
	where trx_ctrl_num  = @rec_trx_ctrl_num

	SELECT @count = @count + 1

	SELECT  @sequence = 1				
END		

if (ABS((@inv_amt_applied)-(0.0)) < 0.0000001)
BEGIN	

	Select @inv_trx_ctrl_num = MIN(apply_to_num)
        from #arinppdt4750 
	where apply_to_num  > @inv_trx_ctrl_num
	and trx_ctrl_num = @settlement_ctrl_num


	IF @inv_trx_ctrl_num IS NULL
		BREAK


	select @invr_amt_applied = amt_applied, 
		@inv_amt_applied = inv_amt_applied, 
		@inv_apply_date = date_doc, 
		@inv_cur_code = inv_cur_code, 
		@invoice_num = apply_to_num, 
		@cross_rate = cross_rate,
		@inv_amt_paid_date = amt_paid_to_date,
		@inv_amt_disc_taken = inv_amt_disc_taken,
		@rec_amt_disc_taken = amt_disc_taken,
		@rec_amt_max_wr_off = amt_max_wr_off,
		@inv_amt_max_wr_off = inv_amt_max_wr_off,
		@write_off_amount = writeoff_amount
	from #arinppdt4750  
	where apply_to_num  = @inv_trx_ctrl_num 
	and trx_ctrl_num = @settlement_ctrl_num					
	

	select @inv_rate_home = rate_home, 
		@inv_rate_oper = rate_oper, 
		@inv_rate_type_home = rate_type_home, 
		@inv_rate_type_oper = rate_type_oper
	from artrx 
	where doc_ctrl_num =  @inv_trx_ctrl_num

END	



if ((@rec_amt_applied) >= (@invr_amt_applied) - 0.0000001)
BEGIN
	select @percent = 1

	select @rec_amt_applied = @rec_amt_applied - @invr_amt_applied 
	
	select @amount_for_invoice = @invr_amt_applied,
		@new_inv_amt_applied = @inv_amt_applied, 
		@new_inv_amt_paid_date = @inv_amt_paid_date,
		@new_inv_amt_disc_taken = @inv_amt_disc_taken,
		@new_rec_amt_disc_taken = @rec_amt_disc_taken,
		@new_rec_amt_max_wr_off = @rec_amt_max_wr_off,
		@new_inv_amt_max_wr_off = @inv_amt_max_wr_off,
		@new_write_off_amount = @write_off_amount,
		@new_invr_amt_applied = @invr_amt_applied

	SELECT @inv_amt_applied = 0
	
	select @amt_gain = @invr_amt_applied 	

	
END	
ELSE
BEGIN
	
	select @percent = @rec_amt_applied/@invr_amt_applied

	select @amount_for_invoice = @rec_amt_applied,
		@new_inv_amt_applied = ROUND(@inv_amt_applied * @percent, 2), 
		@new_inv_amt_paid_date = ROUND(@inv_amt_paid_date * @percent, 2),
		@new_inv_amt_disc_taken = ROUND(@inv_amt_disc_taken * @percent, 2),
		@new_rec_amt_disc_taken = ROUND(@rec_amt_disc_taken * @percent, 2),
		@new_rec_amt_max_wr_off = ROUND(@rec_amt_max_wr_off * @percent, 2),
		@new_inv_amt_max_wr_off = ROUND(@inv_amt_max_wr_off * @percent, 2),
		@new_write_off_amount = ROUND(@write_off_amount * @percent, 2)
	
	select @invr_amt_applied = @invr_amt_applied - @rec_amt_applied, 
		@inv_amt_applied = @inv_amt_applied - @new_inv_amt_applied, 
		@inv_amt_paid_date = @inv_amt_paid_date - @new_inv_amt_paid_date,
		@inv_amt_disc_taken = @inv_amt_disc_taken - @new_inv_amt_disc_taken,
		@rec_amt_disc_taken = @rec_amt_disc_taken - @new_rec_amt_disc_taken,
		@rec_amt_max_wr_off = @rec_amt_max_wr_off - @new_rec_amt_max_wr_off,
		@inv_amt_max_wr_off = @inv_amt_max_wr_off - @new_inv_amt_max_wr_off,
		@write_off_amount = @write_off_amount - @new_write_off_amount,
		@new_invr_amt_applied = @rec_amt_applied

	select @amt_gain = @rec_amt_applied


	select @rec_amt_applied = 0

END
	
if @rec_apply_date < @inv_apply_date
BEGIN	
	IF @rec_cur_code = @inv_cur_code
	BEGIN
		SELECT @reci_rate_home = @inv_rate_home,
			@reci_rate_oper = @inv_rate_oper
	END
	ELSE
	BEGIN
		EXEC @result = CVO_Control..mccurate_sp
			@inv_apply_date,
			@rec_cur_code,	
			@home_currency,		
			@rec_rate_type_home,	
			@reci_rate_home		OUTPUT,
			0,
			@divide_flag_h		OUTPUT

		EXEC @result = CVO_Control..mccurate_sp
			@inv_apply_date,
			@rec_cur_code,	
			@oper_currency,		
			@rec_rate_type_oper,	
			@reci_rate_oper		OUTPUT,
			0,
			@divide_flag_h		OUTPUT
	END

	if @rec_rate_home <> @reci_rate_home or @rec_rate_oper <> @reci_rate_oper
	BEGIN
		SELECT @amt_gain_home = CASE
					 WHEN @reci_rate_home > 0 THEN @amt_gain * @reci_rate_home
					 ELSE @amt_gain / ABS(@reci_rate_home)
					END

		SELECT @amt_gain_home = ROUND(@amt_gain_home, @home_precision)

		SELECT @amt_gl_home = CASE
					 WHEN @rec_rate_home > 0 THEN @amt_gain_home - ROUND((@amt_gain * @rec_rate_home), @home_precision)
					 ELSE ROUND(@amt_gain / ABS(@rec_rate_home), @home_precision)  - @amt_gain_home
					END

		SELECT @amt_gain_oper = CASE
					 WHEN @reci_rate_oper > 0 THEN @amt_gain * @reci_rate_oper
					 ELSE @amt_gain / ABS(@reci_rate_oper)
					END

		SELECT @amt_gain_oper = ROUND(@amt_gain_oper, @oper_precision)

		SELECT @amt_gl_oper = CASE
					 WHEN @rec_rate_oper > 0 THEN @amt_gain_oper - ROUND((@amt_gain * @rec_rate_oper), @oper_precision)
					 ELSE ROUND(@amt_gain / ABS(@rec_rate_oper), @oper_precision) - @amt_gain_oper
					END		
		


	END
END
ELSE
BEGIN
	IF @rec_cur_code = @inv_cur_code
	BEGIN
		SELECT @invr_rate_home = @rec_rate_home,
			@invr_rate_oper = @rec_rate_oper
	END
	ELSE
	BEGIN	
		EXEC @result = CVO_Control..mccurate_sp
			@rec_apply_date,
			@inv_cur_code,	
			@home_currency,		
			@inv_rate_type_home,	
			@invr_rate_home		OUTPUT,
			0,
			@divide_flag_h		OUTPUT
	
		EXEC @result = CVO_Control..mccurate_sp
			@rec_apply_date,
			@inv_cur_code,	
			@oper_currency,		
			@inv_rate_type_oper,	
			@invr_rate_oper		OUTPUT,
			0,
			@divide_flag_h		OUTPUT
	END

	if @inv_rate_home <> @invr_rate_home or @inv_rate_oper <> @invr_rate_oper
	BEGIN

		SELECT @amt_gain_home = CASE
					 WHEN @invr_rate_home > 0 THEN @amt_gain * @invr_rate_home
					 ELSE @amt_gain / ABS(@invr_rate_home)
					END

		SELECT @amt_gain_home = ROUND(@amt_gain_home, @home_precision)

		SELECT @amt_gl_home = CASE
					 WHEN @inv_rate_home > 0 THEN @amt_gain_home - ROUND((@amt_gain * @inv_rate_home), @home_precision)
					 ELSE ROUND(@amt_gain / ABS(@inv_rate_home), @home_precision) - @amt_gain_home
					END

		SELECT @amt_gain_oper = CASE
					 WHEN @invr_rate_oper > 0 THEN @amt_gain * @invr_rate_oper
					 ELSE @amt_gain / ABS(@invr_rate_oper)
					END

		SELECT @amt_gain_oper = ROUND(@amt_gain_oper, @oper_precision)

		SELECT @amt_gl_oper = CASE
					 WHEN @inv_rate_oper > 0 THEN @amt_gain_oper - ROUND((@amt_gain * @inv_rate_oper), @oper_precision)
					 ELSE ROUND(@amt_gain / ABS(@inv_rate_oper), @oper_precision) - @amt_gain_oper
					END		

	

	END

END


	insert into #arinppdt4750 
(
	timestamp            ,
	trx_ctrl_num         ,
	doc_ctrl_num         ,
	sequence_id          ,
	trx_type             ,
	apply_to_num         ,
	apply_trx_type       ,
	customer_code        ,
	date_aging           ,
	amt_applied          ,
	amt_disc_taken       ,
	wr_off_flag          ,
	amt_max_wr_off       ,
	void_flag            ,
	line_desc            ,
	sub_apply_num        ,
	sub_apply_type       ,
	amt_tot_chg          ,	      
	amt_paid_to_date     ,       
	terms_code           ,  
	posting_code         ,  
	date_doc             ,	      
	amt_inv              ,       
	gain_home            ,       
	gain_oper            ,
	inv_amt_applied      ,
	inv_amt_disc_taken   ,
	inv_amt_max_wr_off   ,        
	inv_cur_code		,	
	writeoff_code	   ,	
	writeoff_amount	     ,		
	cross_rate	     ,		
	org_id		     
)
	select 
	NULL,
	@rec_trx_ctrl_num,
	c.doc_ctrl_num,
	@sequence,					
	i.trx_type,
	i.apply_to_num,
	i.apply_trx_type,
	i.customer_code,
	i.date_aging,
	@new_invr_amt_applied,
	@new_rec_amt_disc_taken,
	i.wr_off_flag,
	@new_rec_amt_max_wr_off,
	i.void_flag,
	i.line_desc,
	i.sub_apply_num,
	i.sub_apply_type,
	i.amt_tot_chg,
	@inv_amt_paid_date,
	i.terms_code,
	i.posting_code,
	i.date_doc,
	i.amt_inv,
	ISNULL(@amt_gl_home,0.0),
	ISNULL(@amt_gl_oper,0.0),
	@new_inv_amt_applied,
	@new_inv_amt_disc_taken,
	@new_inv_amt_max_wr_off,
	i.inv_cur_code,
	i.writeoff_code,
	@new_write_off_amount,
	i.cross_rate, 
	i.org_id 
	from #arinppdt4750 i, #arinppyt4750 c
	where 	i.apply_to_num = @inv_trx_ctrl_num
	and   	c.trx_ctrl_num = @rec_trx_ctrl_num
	AND	i.trx_ctrl_num = @settlement_ctrl_num				
	
	select @inv_amt_paid_date = @inv_amt_paid_date + @inv_amt_applied

	select @sequence = @sequence + 1
	

END
	delete #arinppdt4750 where trx_ctrl_num = @settlement_ctrl_num



END

GO
GRANT EXECUTE ON  [dbo].[arstlprt_sp] TO [public]
GO
