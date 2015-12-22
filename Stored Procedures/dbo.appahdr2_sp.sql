SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[appahdr2_sp] @error_level smallint, @debug_level smallint = 0
AS

declare @ib_offset smallint, 
	@ib_seg smallint, 
	@ib_length smallint, 
	@segment_length smallint,
	@ib_flag	smallint

select  @ib_offset = ib_offset, 
	@ib_seg = ib_segment, 
	@ib_length = ib_length,
	@ib_flag = ib_flag 
from glco

--select @segment_length = sum(length) 
--from glaccdef 
--where acct_level < @ib_seg

-- scr 38330

  select @segment_length = ISNULL(start_col - 1, 0 ) from glaccdef where acct_level = @ib_seg 

-- end 38330

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr2.cpp" + ", line " + STR( 48, 5 ) + " -- ENTRY: "




IF (SELECT err_type FROM apedterr WHERE err_code = 40410) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr2.cpp" + ", line " + STR( 55, 5 ) + " -- MSG: " + "Check if posted flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 40410,
			 "",
			 "",
			 posted_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt 
	  WHERE posted_flag NOT IN (0,-1)
END




IF (SELECT err_type FROM apedterr WHERE err_code = 40440) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr2.cpp" + ", line " + STR( 80, 5 ) + " -- MSG: " + "Check if hold flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 40440,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt 
	  WHERE hold_flag NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 40430) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr2.cpp" + ", line " + STR( 103, 5 ) + " -- MSG: " + "Check if hold flag is 1"
	


      INSERT #ewerror
	  SELECT 4000,
			 40430,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt 
	  WHERE hold_flag = 1
END

IF ((SELECT mc_flag FROM apco) = 1)
BEGIN
	IF (SELECT err_type FROM apedterr WHERE err_code = 40850) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr2.cpp" + ", line " + STR( 127, 5 ) + " -- MSG: " + "Validate gain/loss accounts exist"














































			Declare @g_l_accts TABLE 
			(
			 trx_ctrl_num varchar(16),
			 nat_cur_code varchar(8),
			 ap_acct_code varchar(32),
			 flag smallint
			)



			INSERT @g_l_accts (trx_ctrl_num, 
					  nat_cur_code, 
					  ap_acct_code, 
					  flag)
			SELECT DISTINCT c.trx_ctrl_num, 
					b.nat_cur_code, 
					CASE WHEN @ib_flag = 0 THEN d.ap_acct_code
						ELSE STUFF(d.ap_acct_code,@ib_offset + @segment_length ,@ib_length, o.branch_account_number) END, 
					0
			FROM apvohdr a
				INNER JOIN #appavpdt b ON a.trx_ctrl_num = b.apply_to_num			
				INNER JOIN #appavpyt c ON b.trx_ctrl_num = c.trx_ctrl_num
				INNER JOIN  apaccts d ON a.posting_code = d.posting_code
				INNER JOIN Organization o ON a.org_id = o.organization_id
			WHERE (b.nat_cur_code != c.nat_cur_code
			     OR b.gain_home != 0.0
				 OR b.gain_oper != 0.0)












			







			INSERT	#ewerror
			SELECT 4000,
				40850,
				a.nat_cur_code + "--" + a.ap_acct_code,
				"",
				0,
				0.0,
				1,
				a.trx_ctrl_num,
				0,
				"",
				0
			FROM	@g_l_accts a
					LEFT JOIN CVO_Control..mccocdt b ON a.ap_acct_code like b.acct_mask AND b.currency_code = a.nat_cur_code
					INNER JOIN glco c ON b.company_code = c.company_code
			WHERE	b.currency_code IS NULL

			--DROP TABLE #g_l_accts


	 END

END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr2.cpp" + ", line " + STR( 247, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appahdr2_sp] TO [public]
GO
