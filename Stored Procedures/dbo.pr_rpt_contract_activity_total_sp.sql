SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_rpt_contract_activity_total_sp]	@contract_type		smallint = 0,	
																										@contract_status	smallint = 0,	
																										@range					varchar(8000) = ' 0 = 0 ',
																										@tableh						varchar(50) = 'prrptcah'

AS

	DECLARE	@currency_type			varchar(20),
					@status_range				varchar(20),
					@contract_type_str	varchar(5)



	SELECT @currency_type = text_value 
	FROM pr_config 
	WHERE item_name = 'CURRENCY'


	SELECT @contract_type_str = CONVERT(varchar(5), @contract_type )

	SELECT @status_range = '( 0 )'
	
	IF ( @contract_status = 0 )
		SELECT @status_range = '( 0 )'
	IF ( @contract_status = 1 )
		SELECT @status_range = '( 1 )'
	IF ( @contract_status = 2 )
		SELECT @status_range = '( 0, 1 )'



	EXEC(	'	INSERT 	' + @tableh +
				'	(				[contract_ctrl_num],
									[description],
									[start_date],
									[end_date],
									[status],
									[type],
									[amt_paid],
									[amt_accrued] )
					SELECT 	[contract_ctrl_num],
									[description],
									[start_date] = CASE WHEN [start_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [start_date] - 639906, "1/1/1753")) ELSE [start_date] end,
									[end_date] = CASE WHEN [end_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [end_date] - 639906, "1/1/1753")) ELSE [end_date] end,
									[status] = CASE WHEN [status] = 0 THEN "ACTIVE" ELSE "INACTIVE" END,
									[type],
									[amt_paid] = CASE	WHEN ( UPPER( "' + @currency_type + '" ) = "HOME" ) THEN 	SUM([amount_paid_to_date_home]) ELSE SUM([amount_paid_to_date_oper]) END,
									[amt_accrued] = CASE	WHEN ( UPPER( "' + @currency_type + '" ) = "HOME" ) THEN 	SUM([amount_accrued_home]) ELSE SUM([amount_accrued_oper]) END
					FROM 	pr_contracts e
					WHERE [type] = ' +	@contract_type_str +
				' AND	e.status IN ' + @status_range + 
				' AND ' + @range +
				'	GROUP BY [contract_ctrl_num],	[description], [status],	[start_date],	[end_date],	[type]' )

EXEC('SELECT * FROM ' + @tableh ) 
																										
GO
GRANT EXECUTE ON  [dbo].[pr_rpt_contract_activity_total_sp] TO [public]
GO
