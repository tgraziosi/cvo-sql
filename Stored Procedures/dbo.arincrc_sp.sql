SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









 



					 










































 










































































































































































































































































 



































































































































































































































































































CREATE PROCEDURE [dbo].[arincrc_sp] 
	@module_id		int,
	@interface_mode	smallint,
	@trx_ctrl_num		varchar(16),
	@trx_type		smallint,
	@sequence_id		int,
	@salesperson_code	varchar(8),
	@amt_commission	float,
	@percent_flag		smallint,
	@exclusive_flag	smallint,
	@split_flag		smallint 

AS

DECLARE @result		int

IF ( @interface_mode NOT IN ( 1, 2 ) )
BEGIN 
	RETURN 32501
END


SELECT @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM #arinpcom 
WHERE trx_ctrl_num = @trx_ctrl_num
AND trx_type = @trx_type


INSERT #arinpcom (
	trx_ctrl_num,
	trx_type,
	sequence_id,
	salesperson_code,
	amt_commission,
	percent_flag,
	exclusive_flag,
	split_flag,
	trx_state,
	mark_flag
 )
VALUES (
	@trx_ctrl_num,
	@trx_type,
	@sequence_id,
	@salesperson_code,
	@amt_commission,
	@percent_flag,
	@exclusive_flag,
	@split_flag,
	2,
	0
 )

IF ( @@error != 0 )
	RETURN 32502
	

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[arincrc_sp] TO [public]
GO