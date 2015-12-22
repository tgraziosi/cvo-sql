SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arincra_sp] 
	@module_id int,
	@interface_mode smallint,
	@trx_ctrl_num		varchar(16),
	@sequence_id		int,	
	@doc_ctrl_num		varchar(16),
	@apply_to_num		varchar(16),
	@apply_trx_type		smallint,
	@trx_type		smallint,
	@date_applied		int,
	@date_due		int,
	@date_aging		int,
	@customer_code		varchar(8),
	@salesperson_code	varchar(8),
	@territory_code		varchar(8),
	@price_code		varchar(8),
	@amt_due			float

AS

DECLARE @result int

IF ( @interface_mode NOT IN ( 1, 2 ) )
BEGIN 
	RETURN 32501
END


SELECT @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM #arinpage 
WHERE trx_ctrl_num = @trx_ctrl_num
AND trx_type = @trx_type


INSERT #arinpage (
	trx_ctrl_num,
	sequence_id,	
	doc_ctrl_num,
	apply_to_num,
	apply_trx_type,
	trx_type,
	date_applied,
	date_due,
	date_aging,
	customer_code,
	salesperson_code,
	territory_code,
	price_code,
	amt_due,
	trx_state,
	mark_flag
 )
VALUES (
	@trx_ctrl_num,
	@sequence_id,	
	@doc_ctrl_num,
	@apply_to_num,
	@apply_trx_type,
	@trx_type,
	@date_applied,
	@date_due,
	@date_aging,
	@customer_code,
	@salesperson_code,
	@territory_code,
	@price_code,
	@amt_due,
	2,
	0
 )

IF ( @@error != 0 )
	RETURN 32502
	

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[arincra_sp] TO [public]
GO
