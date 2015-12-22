SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\aravgact.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

	

CREATE PROC [dbo].[aravgact_sp] 
	@t_prc_flag smallint,	@t_slp_flag smallint,	@t_ter_flag smallint, 
	@t_shp_flag smallint,	@t_mast_flag smallint,	@t_cus_flag smallint,
	@t_prc_code char(8),	@t_slp_code char(8),	@t_ter_code char(8), 
	@t_shp_code char(8),	@t_cus_code char(8),	@t_date_due int,
	@t_date_applied int,	@t_date_aging int,	@t_disc_lost float,	 
	@t_period_end int, 	@t_date_entered int
AS

DECLARE	@days_to_pay_off float, @days_over_due float, @juldate int,
	@month smallint, @day smallint, @year smallint


IF ( @t_date_entered > @t_date_aging )
	SELECT	@days_to_pay_off = @t_date_entered - @t_date_aging
ELSE
	SELECT	@days_to_pay_off = 0

IF ( @t_cus_flag > 0 )
BEGIN
	UPDATE	aractcus
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		num_inv_paid = num_inv_paid + 1	
	WHERE	customer_code = @t_cus_code

	UPDATE	arsumcus
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		amt_disc_lost = amt_disc_lost + @t_disc_lost,
		num_inv_paid = num_inv_paid + 1	
	WHERE	customer_code = @t_cus_code
	 AND	date_thru = @t_period_end
END

IF ( @t_prc_flag > 0 )
BEGIN
	UPDATE	aractprc
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		num_inv_paid = num_inv_paid + 1	
	WHERE	price_code = @t_prc_code

	UPDATE	arsumprc
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		amt_disc_lost = amt_disc_lost + @t_disc_lost,
		num_inv_paid = num_inv_paid + 1	
	WHERE	price_code = @t_prc_code
	 AND	date_thru = @t_period_end
END

IF (( @t_shp_flag > 0 ) AND ( @t_mast_flag > 0 ))
BEGIN
	UPDATE	aractshp
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		num_inv_paid = num_inv_paid + 1	
	WHERE	customer_code = @t_cus_code
	 AND	ship_to_code = @t_shp_code

	UPDATE	arsumshp
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		amt_disc_lost = amt_disc_lost + @t_disc_lost,
		num_inv_paid = num_inv_paid + 1	
	WHERE	customer_code = @t_cus_code
	 AND	ship_to_code = @t_shp_code
	 AND	date_thru = @t_period_end
END

IF ( @t_slp_flag > 0 )
BEGIN
	UPDATE	aractslp
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		num_inv_paid = num_inv_paid + 1	
	WHERE	salesperson_code = @t_slp_code

	UPDATE	arsumslp
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		amt_disc_lost = amt_disc_lost + @t_disc_lost,
		num_inv_paid = num_inv_paid + 1	
	WHERE	salesperson_code = @t_slp_code
	 AND	date_thru = @t_period_end
END

IF ( @t_ter_flag > 0 )
BEGIN
	UPDATE	aractter
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		num_inv_paid = num_inv_paid + 1	
	WHERE	territory_code = @t_ter_code

	UPDATE	arsumter
	SET	avg_days_pay = ROUND(( avg_days_pay * num_inv_paid 
			+ @days_to_pay_off ) / ( num_inv_paid + 1.0 ), 0 ),
		amt_disc_lost = amt_disc_lost + @t_disc_lost,
		num_inv_paid = num_inv_paid + 1	
	WHERE	territory_code = @t_ter_code
	 AND	date_thru = @t_period_end
END



SELECT @year = DATEPART(year, getdate())
SELECT @month = DATEPART(month, getdate())
SELECT @day = DATEPART(day, getdate())

EXEC appjuldt_sp @year, @month, @day, @juldate OUTPUT 

IF ( @t_date_due > @juldate )
BEGIN
	SELECT	@days_over_due = @t_date_applied - @t_date_due 

	IF ( @t_cus_flag > 0 )
	BEGIN
		UPDATE	aractcus
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	customer_code = @t_cus_code

		UPDATE	arsumcus
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	customer_code = @t_cus_code
		 AND	date_thru = @t_period_end
	END

	IF ( @t_prc_flag > 0 )
	BEGIN
		UPDATE	aractprc
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	price_code = @t_prc_code

		UPDATE	arsumprc
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	price_code = @t_prc_code
		 AND	date_thru = @t_period_end
	END

	IF (( @t_shp_flag > 0 ) AND ( @t_mast_flag > 0 ))
	BEGIN
		UPDATE	aractshp
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	customer_code = @t_cus_code
		 AND	ship_to_code = @t_shp_code

		UPDATE	arsumshp
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	customer_code = @t_cus_code
		 AND	ship_to_code = @t_shp_code
		 AND	date_thru = @t_period_end
	END

	IF ( @t_slp_flag > 0 )
	BEGIN
		UPDATE	aractslp
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	salesperson_code = @t_slp_code

		UPDATE	arsumslp
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	salesperson_code = @t_slp_code
		 AND	date_thru = @t_period_end
	END

	IF ( @t_ter_flag > 0 )
	BEGIN
		UPDATE	aractter
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	territory_code = @t_ter_code

		UPDATE	arsumter
		SET	avg_days_overdue = ROUND(( avg_days_overdue 
					* num_overdue_pyt + @days_over_due )
					/ ( num_overdue_pyt + 1.0 ), 0 ),
			num_overdue_pyt = num_overdue_pyt + 1
		WHERE	territory_code = @t_ter_code
		 AND	date_thru = @t_period_end
	END
END

RETURN 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[aravgact_sp] TO [public]
GO
