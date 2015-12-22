SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

























CREATE PROCEDURE [dbo].[apagvald_sp] (
		@over_days smallint,
		@day_lim int,
		@over_amt smallint,
		@amt_lim float,
		@over_cdt_lim smallint,
		@over_ag_lim smallint,
		@meet_all smallint, 
		@sel_ag_date smallint, 
		@apactvnd_flag smallint, 
		@cond_msk smallint, 
		@as_of_date int
		)
as

declare @brkt2_b smallint,
	@brkt3_b smallint,
	@brkt4_b smallint,
	@brkt5_b smallint,
	@brkt6_b smallint,
	@brkt1_e smallint,
	@brkt2_e smallint,
	@brkt3_e smallint,
	@brkt4_e smallint,
	@brkt5_e smallint,
	@min_vendor_code		varchar(12),						
	@aging_brkt smallint


declare @ca_date_doc int,
	@ca_date_due int,
	@ca_date_aging int,
	@ca_date_applied int,
	@brkt_age int


declare @cond_met smallint,
	@old_vendor_code varchar(12),
	@vend_bal float,
	@credit_limit float,
	@aging_limit smallint,
	@vendor_code varchar(12),
	@cmp_result smallint


SELECT @brkt1_e = age_bracket1, @brkt2_e = age_bracket2,
 @brkt3_e = age_bracket3, @brkt4_e = age_bracket4,
 @brkt5_e = age_bracket5
FROM apco


select @brkt2_b = @brkt1_e + 1 , @brkt3_b = @brkt2_e + 1 ,
	@brkt4_b = @brkt3_e + 1 , @brkt5_b = @brkt4_e + 1 ,
	@brkt6_b = @brkt5_e + 1



IF @apactvnd_flag = 0
BEGIN

	WHILE ( 1 = 1 )
	BEGIN
		SET ROWCOUNT 10000
		Update #apagvnd
		set valid_vnd = 2,
		 vend_bal =( SELECT sum(amount - amt_paid_to_date)
				FROM aptrxage
				WHERE trx_type = 4091
				AND paid_flag = 0
				AND aptrxage.vendor_code = #apagvnd.vendor_code )
		WHERE valid_vnd = 1
	
		if @@rowcount < 10000
			BREAK
	END
	SET ROWCOUNT 0
END
ELSE
BEGIN

	SET ROWCOUNT 10000
	WHILE ( 1 = 1 )
	BEGIN
		UPDATE #apagvnd
		 SET valid_vnd = 2,
		 vend_bal =(
			SELECT apactvnd.amt_balance
			FROM apactvnd
			WHERE apactvnd.vendor_code = #apagvnd.vendor_code )
		WHERE valid_vnd = 1
	
		if @@rowcount < 10000
			BREAK
	END

	SET ROWCOUNT 0
END



IF @over_days = 0 AND @over_ag_lim = 0
	RETURN



select @vendor_code = ""
while ( 1 = 1)
begin
	SELECT @old_vendor_code = @vendor_code

	SELECT @min_vendor_code = min(vendor_code)					
	FROM #apagvnd											
	WHERE vendor_code > @old_vendor_code						

	SELECT @vendor_code = vendor_code,
		@vend_bal = vend_bal,
		@credit_limit = credit_limit,
		@aging_limit = aging_limit
	FROM #apagvnd
	WHERE vendor_code > @old_vendor_code
	 AND	vendor_code = @min_vendor_code						


	IF @vendor_code !> @old_vendor_code
		break

	if @vend_bal IS NULL
	 select @vend_bal = 0

	SELECT @cond_met = 0

	
	IF ( @sel_ag_date = 0 )
	BEGIN
		SELECT @brkt_age = @as_of_date - min ( date_aging)
		FROM aptrxage
		WHERE vendor_code = @vendor_code
		 AND trx_type = 4091
		 AND paid_flag = 0
	END
	ELSE IF (@sel_ag_date = 1 )
	BEGIN
		SELECT @brkt_age = @as_of_date - min( date_due )
		FROM aptrxage
		WHERE vendor_code = @vendor_code
		 AND trx_type = 4091
		 AND paid_flag = 0
	END
	ELSE IF (@sel_ag_date = 2 )
	BEGIN
		SELECT @brkt_age = @as_of_date - min( date_doc )
		FROM aptrxage
		WHERE vendor_code = @vendor_code
		 AND trx_type = 4091
		 AND paid_flag = 0
	END
	ELSE IF (@sel_ag_date = 3 )
	BEGIN
		SELECT @brkt_age = @as_of_date - min( date_applied )
		FROM aptrxage
		WHERE vendor_code = @vendor_code
		 AND trx_type = 4091
		 AND paid_flag = 0
	END


	
	if ( @brkt_age <= @brkt1_e )
		select @aging_brkt = 1
	else if @brkt_age >= @brkt2_b and @brkt_age <= @brkt2_e
		select @aging_brkt = 2
	else if @brkt_age >= @brkt3_b and @brkt_age <= @brkt3_e
		select @aging_brkt = 3
	else if @brkt_age >= @brkt4_b and @brkt_age <= @brkt4_e
		select @aging_brkt = 4
	else if @brkt_age >= @brkt5_b and @brkt_age <= @brkt5_e
		select @aging_brkt = 5
	else if @brkt_age >= @brkt6_b
		select @aging_brkt = 6

	IF ( @over_days != 0 )
	BEGIN
		
		EXEC @cmp_result = flcomp_sp @vend_bal , 0.0
		if @brkt_age > @day_lim and @cmp_result = 1
			select @cond_met = @cond_met + 1
	END

	IF ( (ABS((@over_amt)-(0)) > 0.0000001) )
	BEGIN
		EXEC @cmp_result = flcomp_sp @vend_bal , @amt_lim
		if @cmp_result = 1
			select @cond_met = @cond_met + 2
	END

	IF @over_cdt_lim != 0
	BEGIN
		EXEC @cmp_result = flcomp_sp @vend_bal , @credit_limit

		if @cmp_result = 1
			select @cond_met = @cond_met + 4
	END

	IF ( @over_ag_lim != 0 )
	BEGIN
		
		EXEC @cmp_result = flcomp_sp @vend_bal , 0.0
		if @aging_brkt > @aging_limit and @cmp_result = 1
			select @cond_met = @cond_met + 8

	END

	
	IF ( @meet_all = 0 and @cond_met = 0 ) or
	 ( @meet_all != 0 and @cond_met != @cond_msk )
	BEGIN
		update #apagvnd
		set #apagvnd.valid_vnd = 0
		where vendor_code = @vendor_code
	
	END
END

GO
GRANT EXECUTE ON  [dbo].[apagvald_sp] TO [public]
GO
