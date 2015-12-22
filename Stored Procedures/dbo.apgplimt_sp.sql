SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apgplimt_sp] @limit_check_flag smallint,
								@from_check_amt float,
								@to_check_amt float, 
								@limit_amount_flag	 smallint,
								@max_amt		 float,		
								@debug_level smallint = 0

AS
		DECLARE @date_due	 int,
				 @amt			 float,
 				 @last_id		 int,
				 @id			 int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgplimt.sp" + ", line " + STR( 63, 5 ) + " -- ENTRY: "



IF @limit_check_flag = 1
 BEGIN
	 SELECT id, amt_applied = SUM(amt_applied)
	 INTO #temp5
	 FROM #pay_detail
	 GROUP BY id

	 DELETE #pay_detail
	 FROM #pay_detail a, #temp5 b
	 WHERE a.id = b.id
	 AND ((b.amt_applied) < (@from_check_amt) - 0.0000001)

	 SELECT a.id, 
	 		 a.apply_to_num,
			 a.date_due,
			 a.amt_applied,
			 flag = 0
	 INTO #temp6
	 FROM #pay_detail a, #temp5 c
	 WHERE a.id = c.id
	 AND ((c.amt_applied) > (@to_check_amt) + 0.0000001)

	 CREATE CLUSTERED INDEX temp6_ind ON #temp6 (id,date_due,apply_to_num)

	 SELECT @last_id = 0
	 WHILE (1=1)
		 BEGIN 
			SELECT @id = MIN(id)
			FROM #temp6
			WHERE id > @last_id

			IF @id IS NULL BREAK

			SELECT @amt = 0.0
			WHILE (1=1)
			 BEGIN
				 SET ROWCOUNT 1
				 SELECT @amt = @amt + amt_applied
				 FROM #temp6
				 WHERE id = @id
				 AND flag = 0
				 SET ROWCOUNT 0

				 IF ((@amt) <= (@to_check_amt) + 0.0000001)
				 BEGIN	
						SET ROWCOUNT 1
						UPDATE #temp6
						SET flag = 1
						WHERE id = @id
						AND flag = 0 
						SET ROWCOUNT 0

						IF (ABS((@amt)-(@to_check_amt)) < 0.0000001) BREAK
					 END
				 				 
				 ELSE IF ((@amt) > (@to_check_amt) + 0.0000001)
				 BEGIN
						SET ROWCOUNT 1
						UPDATE #temp6
						SET flag = 2,
							amt_applied = amt_applied - (@amt - @to_check_amt) 
						WHERE id = @id
						AND flag = 0 
						SET ROWCOUNT 0

						BREAK
					 END

			 END

			SELECT @last_id = @id

		 END
 



			DELETE #pay_detail
			FROM #pay_detail a, #temp6 b
			WHERE a.apply_to_num = b.apply_to_num
			AND b.flag = 0

			UPDATE #pay_detail
			SET amt_applied = b.amt_applied,
			 vo_amt_applied = (SIGN(b.amt_applied/a.cross_rate) * ROUND(ABS(b.amt_applied/a.cross_rate) + 0.0000001, c.curr_precision))
			FROM #pay_detail a, #temp6 b, glcurr_vw c
			WHERE a.apply_to_num = b.apply_to_num
			AND a.nat_cur_code = c.currency_code
			AND b.flag = 2

			DROP TABLE #temp6

						
	 DROP TABLE #temp5
 END


IF (@limit_amount_flag = 1)
 BEGIN
	 IF ( (((SELECT SUM(amt_applied) FROM #pay_detail)) > (@max_amt) + 0.0000001) )
	 BEGIN
			SELECT a.apply_to_num,
			 a.amt_applied,
				 a.date_due,
				 flag = 0
 INTO #temp4
			FROM #pay_detail a

		 	CREATE CLUSTERED INDEX temp4_ind ON #temp4(date_due,apply_to_num)

			SELECT @amt = 0.0
			WHILE (1=1)
			 BEGIN
				 SET ROWCOUNT 1
				 SELECT @amt = @amt + amt_applied
				 FROM #temp4
				 WHERE flag = 0
				 SET ROWCOUNT 0

				 IF ((@amt) <= (@max_amt) + 0.0000001)
				 BEGIN	
						SET ROWCOUNT 1
						UPDATE #temp4
						SET flag = 1
						WHERE flag = 0 
						SET ROWCOUNT 0

						IF (ABS((@amt)-(@max_amt)) < 0.0000001) BREAK
					 END
				 				 
				 ELSE IF ((@amt) > (@max_amt) + 0.0000001)
				 BEGIN
						SET ROWCOUNT 1
						UPDATE #temp4
						SET flag = 2,
							amt_applied = amt_applied - (@amt - @max_amt) 
						WHERE flag = 0 
						SET ROWCOUNT 0

						BREAK
					 END
			 END


			DELETE #pay_detail
			FROM #pay_detail a, #temp4 b
			WHERE a.apply_to_num = b.apply_to_num
			AND b.flag = 0

			UPDATE #pay_detail
			SET amt_applied = b.amt_applied,
			 vo_amt_applied = (SIGN(b.amt_applied/a.cross_rate) * ROUND(ABS(b.amt_applied/a.cross_rate) + 0.0000001, c.curr_precision))
			FROM #pay_detail a, #temp4 b, glcurr_vw c
			WHERE a.apply_to_num = b.apply_to_num
			AND a.nat_cur_code = c.currency_code
			AND b.flag = 2

			DROP TABLE #temp4
		 END
 END


DELETE #pay_header
WHERE id NOT IN (SELECT id FROM #pay_detail)

UPDATE #pay_header
SET amt_payment = (SELECT SUM(b.amt_applied) FROM #pay_detail b WHERE b.id = a.id),
	amt_disc_taken = (SELECT SUM(b.amt_disc_taken) FROM #pay_detail b WHERE b.id = a.id)
FROM #pay_header a	



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgplimt.sp" + ", line " + STR( 242, 5 ) + " -- EXIT: "
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apgplimt_sp] TO [public]
GO
