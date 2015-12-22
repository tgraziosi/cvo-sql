SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create Procedure [dbo].[cvo_installment_billing_sp]
		@trx_ctrl_num varchar(16),
		@terms_code varchar(8),
		@date_doc int,
		@date_applied int,
		@customer_code varchar(8),
		@salesperson_code varchar(8),
		@territory_code varchar(8),
		@price_code varchar(8),
		@amt_due float
AS
DECLARE @prc_type tinyint, --1: equal
			   --2: as per cvo_artermsd_installment
			   --3: as per cvo_artermsd_installment with remainder added equally to each period
	@prc_total float,
	@prc_remainder float,
	@prc_equal float,
	@terms_type smallint --1: days
			     --3: fixed dates	

/*
** Calculation of proration
*/
--Determine how proration will take place.
--If sum of discount % = 0 then prorate equal,
--else prorate according to discount %
--If sum of discount % <> 100 then add the difference to the
--last period.
	SELECT 	@prc_total = 0,
	       	@prc_type = 0,
	       	@prc_equal = 0,
		@prc_remainder=0

	SELECT @prc_total = sum(installment_prc)
	FROM cvo_artermsd_installment
	WHERE terms_code = @terms_code

	SELECT @prc_type = CASE
			   WHEN @prc_total = 0 THEN 1
			   WHEN @prc_total = 100 THEN 2
			   ELSE 3
			   END	  
	
	IF @prc_type = 1
	BEGIN
		SELECT @prc_equal = @amt_due/max(sequence_id)
		FROM cvo_artermsd_installment
		where terms_code = @terms_code
	END
	ELSE IF @prc_type = 3 
	BEGIN
		SELECT @prc_remainder = (100 - @prc_total)/max(sequence_id)
		FROM cvo_artermsd_installment
		where terms_code = @terms_code
	END
	


	SELECT @terms_type = terms_type 
	FROM arterms where terms_code = @terms_code

/*
**	INSERT THE VALUES INTO THE ARINPAGE TABLE
*/


	DELETE arinpage where trx_ctrl_num = @trx_ctrl_num

	INSERT arinpage
	SELECT  NULL,
		@trx_ctrl_num,
		td.sequence_id,
		'',
		'',
		0,
		2031,
		date_applied = @date_applied,
		date_due = case 
			   WHEN @terms_type = 1 THEN @date_doc + td.installment_days
			   WHEN @terms_type = 3 THEN td.date_installment
			   ELSE 0
			   END	 ,
		date_aging = case
		  		WHEN td.sequence_id = 1 THEN @date_doc
				ELSE (SELECT CASE @terms_type
					     WHEN 1 THEN (@date_doc + installment_days)
					     WHEN 3 THEN date_installment
					     ELSE 0
					     END	
				      FROM cvo_artermsd_installment
					WHERE terms_code = td.terms_code
					AND sequence_id = td.sequence_id-1 )
				END,
		@customer_code,
		@salesperson_code,
		@territory_code,
		@price_code,
		amt_due = case
			 WHEN @prc_type = 1 THEN @prc_equal 
			 WHEN @prc_type = 2 THEN @amt_due * (td.installment_prc/100)
			 WHEN @prc_type = 3 THEN @amt_due * ((td.installment_prc + @prc_remainder)/100)
			 ELSE @amt_due * (@prc_equal/100) 
			 END 
	FROM cvo_artermsd_installment td
	WHERE terms_code = @terms_code

/*
**	INSERT THE STATEMENT DATES INTO THE CUSTOM TABLE
*/
IF NOT EXISTS (SELECT 1 FROM cvo_invoice_statement WHERE trx_ctrl_num=@trx_ctrl_num  )
	INSERT cvo_invoice_statement(trx_ctrl_num,sequence_id,date_statement)
	select trx_ctrl_num,sequence_id,date_due 
	from arinpage 
	where trx_ctrl_num=@trx_ctrl_num 
GO
GRANT EXECUTE ON  [dbo].[cvo_installment_billing_sp] TO [public]
GO
