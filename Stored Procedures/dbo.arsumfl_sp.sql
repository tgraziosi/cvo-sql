SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arsumfl.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC	[dbo].[arsumfl_sp]	
	@sum_postflag smallint, @apply_date int
AS

DECLARE	@sumcus smallint, @sumprc smallint, 
	@sumshp smallint, @sumslp smallint, 
	@sumter smallint, @trx_type smallint,
	@fin_charge smallint, @late_charge smallint,
	@cur_code char(8), @last_code char(8),
	@amt_late float, @amt_fin float, 
	@num_late float, @num_fin float,
	@cust_code varchar(8)

SELECT @fin_charge = 2061, @late_charge = 2071


IF ( SELECT COUNT(*) FROM artrx WHERE posted_flag = @sum_postflag ) = 0
	RETURN

SELECT 	@sumcus = arsumcus_flag, @sumprc = arsumprc_flag,
	@sumshp = arsumshp_flag, @sumslp = arsumslp_flag,
	@sumter = arsumter_flag
FROM	arco

IF @sumcus = 1
BEGIN
	SELECT	@cur_code = " "

	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_code = NULL

		SET	ROWCOUNT 1

		SELECT	@last_code = customer_code
		FROM	artrx
		WHERE	posted_flag = @sum_postflag
		AND	customer_code > @cur_code

		SET	ROWCOUNT 0

		IF	@last_code IS NULL
			BREAK

		SELECT	@cur_code = @last_code

		EXEC	arintsum_sp	@cur_code, 
					NULL,	 
					NULL,	 
					NULL,	 
					NULL,	 
					@apply_date,
					0, 
					0 

		SELECT	@num_fin = COUNT(*), @amt_fin = SUM(amt_net)
		FROM	artrx
		WHERE	trx_type = @fin_charge
		AND	customer_code = @cur_code
		AND	posted_flag = @sum_postflag

		SELECT	@num_late = COUNT(*), @amt_late = SUM(amt_net)
		FROM	artrx
		WHERE	trx_type = @late_charge
		AND	customer_code = @cur_code
		AND	posted_flag = @sum_postflag

		IF @num_fin = 0 AND @num_late = 0
			CONTINUE

		IF @amt_late IS NULL
			SELECT @amt_late = 0
		IF @amt_fin IS NULL
			SELECT @amt_fin = 0

		
 		UPDATE	arsumcus
		SET	num_fin_chg = num_fin_chg + @num_fin,
			num_late_chg = num_late_chg + @num_late,
			amt_fin_chg = amt_fin_chg + @amt_fin,
			amt_late_chg = amt_late_chg + @amt_late
		WHERE	customer_code = @cur_code
		AND	date_thru = ( SELECT MIN(date_thru)
				 FROM arsumcus
				 WHERE customer_code = @cur_code
				 AND ( @apply_date BETWEEN 
				 		date_from AND date_thru ) )
	END
END

IF @sumprc = 1
BEGIN 
	
	SELECT	@cur_code = " "

	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_code = NULL

		SET	ROWCOUNT 1

		SELECT	@last_code = price_code
		FROM	artrx
		WHERE	posted_flag = @sum_postflag
		AND	price_code > @cur_code

		SET	ROWCOUNT 0

		IF	@last_code IS NULL
			BREAK

		SELECT	@cur_code = @last_code

		EXEC	arintsum_sp	NULL, 	 
					@last_code, 
					NULL,	 
					NULL,	 
					NULL,	 
					@apply_date,
					0, 
					0 


		SELECT	@num_fin = COUNT(*), @amt_fin = SUM(amt_net)
		FROM	artrx
		WHERE	trx_type = @fin_charge
		AND	price_code= @cur_code
		AND	posted_flag = @sum_postflag

		SELECT	@num_late = COUNT(*), @amt_late = SUM(amt_net)
		FROM	artrx
		WHERE	trx_type = @late_charge
		AND	price_code= @cur_code
		AND	posted_flag = @sum_postflag

		IF @num_fin = 0 AND @num_late = 0
			CONTINUE

		IF @amt_late IS NULL
			SELECT @amt_late = 0
		IF @amt_fin IS NULL
			SELECT @amt_fin = 0

		
 		UPDATE	arsumprc
		SET	num_fin_chg = num_fin_chg + @num_fin,
			num_late_chg = num_late_chg + @num_late,
			amt_fin_chg = amt_fin_chg + @amt_fin,
			amt_late_chg = amt_late_chg + @amt_late
		WHERE	price_code= @cur_code
		AND	date_thru = ( SELECT MIN(date_thru)
				 FROM arsumprc
				 WHERE price_code= @last_code
				 AND ( @apply_date BETWEEN 
				 		date_from AND date_thru ) )
	END
END

IF @sumshp = 1
BEGIN
	
	SELECT	@cur_code = " "

	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_code = NULL

		SET	ROWCOUNT 1

		SELECT	@last_code = x.ship_to_code,
			@cust_code = x.customer_code
		FROM	artrx x, arcust c
		WHERE	posted_flag = @sum_postflag
		AND	x.ship_to_code > @cur_code
		AND	x.customer_code = c.customer_code
		AND	c.ship_to_history = 1

		SET	ROWCOUNT 0

		IF	@last_code IS NULL
			BREAK

		SELECT	@cur_code = @last_code

		EXEC	arintsum_sp	@cust_code, 
					NULL,	 
					@last_code, 
					NULL,	 
					NULL,	 
					@apply_date,
					0, 
					0 


		SELECT	@num_fin = COUNT(*), @amt_fin = SUM( amt_net )
		FROM	artrx
		WHERE	trx_type = @fin_charge
		AND	ship_to_code = @cur_code
		AND	posted_flag = @sum_postflag

		SELECT	@num_late = COUNT(*), @amt_late= SUM( amt_net )
		FROM	artrx
		WHERE	trx_type = @late_charge
		AND	ship_to_code= @cur_code
		AND	posted_flag = @sum_postflag

		IF @num_fin = 0 AND @num_late = 0
			CONTINUE

		IF @amt_late IS NULL
			SELECT @amt_late = 0
		IF @amt_fin IS NULL
			SELECT @amt_fin = 0

		
 		UPDATE	arsumshp
		SET	num_fin_chg = num_fin_chg + @num_fin,
			num_late_chg = num_late_chg + @num_late,
			amt_fin_chg = amt_fin_chg + @amt_fin,
			amt_late_chg = amt_late_chg + @amt_late
		WHERE	ship_to_code= @cur_code
		AND	date_thru = ( SELECT MIN(date_thru)
				 FROM arsumshp
				 WHERE ship_to_code= @last_code
				 AND ( @apply_date BETWEEN 
				 		date_from AND date_thru ) )
	END
END

IF @sumter = 1
BEGIN
	
	SELECT	@cur_code = " "

	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_code = NULL

		SET	ROWCOUNT 1

		SELECT	@last_code = territory_code
		FROM	artrx
		WHERE	posted_flag = @sum_postflag
		AND	territory_code > @cur_code

		SET	ROWCOUNT 0

		IF	@last_code IS NULL
			BREAK

		SELECT	@cur_code = @last_code

		EXEC	arintsum_sp	NULL, 	 
					NULL,	 
					NULL, 	 
					NULL,	 
					@last_code, 
					@apply_date,
					0, 
					0 


		SELECT	@num_fin = COUNT(*), @amt_fin = SUM(amt_net)
		FROM	artrx
		WHERE	trx_type = @fin_charge
		AND	territory_code = @cur_code
		AND	posted_flag = @sum_postflag

		SELECT	@num_late = COUNT(*), @amt_late = SUM(amt_net)
		FROM	artrx
		WHERE	trx_type = @late_charge
		AND	territory_code= @cur_code
		AND	posted_flag = @sum_postflag

		IF @num_fin = 0 AND @num_late = 0
			CONTINUE

		IF @amt_late IS NULL
			SELECT @amt_late = 0
		IF @amt_fin IS NULL
			SELECT @amt_fin = 0

		
 		UPDATE	arsumter
		SET	num_fin_chg = num_fin_chg + @num_fin,
			num_late_chg = num_late_chg + @num_late,
			amt_fin_chg = amt_fin_chg + @amt_fin,
			amt_late_chg = amt_late_chg + @amt_late
		WHERE	territory_code= @cur_code
		AND	date_thru = ( SELECT MIN(date_thru)
				 FROM arsumter
				 WHERE territory_code= @last_code
				 AND ( @apply_date BETWEEN 
				 		date_from AND date_thru ) )
	END
END

IF @sumslp = 1
BEGIN
	
	SELECT	@cur_code = " "

	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_code = NULL

		SET	ROWCOUNT 1

		SELECT	@last_code = salesperson_code
		FROM	artrx
		WHERE	posted_flag = @sum_postflag
		AND	salesperson_code > @cur_code

		SET	ROWCOUNT 0

		IF	@last_code IS NULL
			BREAK

		SELECT	@cur_code = @last_code

		EXEC	arintsum_sp	NULL, 	 
					NULL,	 
					NULL, 	 
					@last_code, 
					NULL, 
					@apply_date,
					0, 
					0 


		SELECT	@num_fin = COUNT(*), @amt_fin = SUM(amt_net)
		FROM	artrx
		WHERE	trx_type = @fin_charge
		AND	salesperson_code = @cur_code
		AND	posted_flag = @sum_postflag

		SELECT	@num_late = COUNT(*), @amt_late = SUM(amt_net)
		FROM	artrx
		WHERE	trx_type = @late_charge
		AND	salesperson_code= @cur_code
		AND	posted_flag = @sum_postflag

		IF @num_fin = 0 AND @num_late = 0
			CONTINUE

		IF @amt_late IS NULL
			SELECT @amt_late = 0
		IF @amt_fin IS NULL
			SELECT @amt_fin = 0

		
 		UPDATE	arsumslp
		SET	num_fin_chg = num_fin_chg + @num_fin,
			num_late_chg = num_late_chg + @num_late,
			amt_fin_chg = amt_fin_chg + @amt_fin,
			amt_late_chg = amt_late_chg + @amt_late
		WHERE	salesperson_code= @cur_code
		AND	date_thru = ( SELECT MIN(date_thru)
				 FROM arsumslp
				 WHERE salesperson_code= @last_code
				 AND ( @apply_date BETWEEN 
				 		date_from AND date_thru ) )
	END
END 
	
RETURN



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arsumfl_sp] TO [public]
GO
