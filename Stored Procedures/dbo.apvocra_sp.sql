SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvocra_sp] 
	@module_id int,
	@interface_mode smallint,
	@trx_ctrl_num 	varchar(16),
	@trx_type		smallint,
	@sequence_id		int,
	@date_applied 	int,
	@date_due		int,
	@date_aging		int,
	@amt_due			float

AS

DECLARE @result int


SELECT @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM #apinpage 
WHERE trx_ctrl_num = @trx_ctrl_num
AND trx_type = @trx_type


INSERT #apinpage (
	trx_ctrl_num,
	trx_type,
	sequence_id,
	date_applied,
	date_due,
	date_aging,
	amt_due,
	trx_state,
	mark_flag
 )
VALUES (
	@trx_ctrl_num,
	@trx_type,
	@sequence_id,
	@date_applied,
	@date_due,
	@date_aging,
	@amt_due,
	2,
	0
 )

IF ( @@error != 0 )
	RETURN -1
	

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apvocra_sp] TO [public]
GO
