SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\aptxinln.SPv - e7.2.2 : 1.9
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



























create procedure [dbo].[aptxinln_sp]
	@g_trx_num char(32), @tax_code char(8), @amount float,
	@qty_shipped float, @acct_code char(32),
	@incl_tax_line float OUTPUT,
	@last_incl_rev_acct char(32) OUTPUT
as
DECLARE @last_seq_id int,
	@tax_type_code char(8),
	@tax_based_type smallint,
	@amt_tax float,
	@prc_flag smallint,
 @accumulated_tax float

	SELECT @last_seq_id = 0
	SELECT @incl_tax_line = 0.0

	SET ROWCOUNT 1

	
	WHILE (1 = 1)
	BEGIN
		SELECT @tax_type_code = aptxtype.tax_type_code,
		 @tax_based_type = aptxtype.tax_based_type,
		 @amt_tax = aptxtype.amt_tax,	
		 @prc_flag = aptxtype.prc_flag,
		 @last_seq_id = aptaxdet.sequence_id
		FROM aptaxdet, aptxtype
		WHERE aptaxdet.tax_code = @tax_code
		AND aptaxdet.sequence_id > @last_seq_id
		AND aptxtype.tax_type_code = aptaxdet.tax_type_code
		ORDER BY aptaxdet.sequence_id

		IF (@@ROWCOUNT = 0)
			BREAK

		
		IF (@tax_based_type = 2)
			CONTINUE
		
		
		IF (@tax_based_type = 1)
		BEGIN
			
			IF ((@amount) > (0.0) + 0.0000001)
			 SELECT @incl_tax_line = @incl_tax_line +
				(@qty_shipped * @amt_tax)
			ELSE
			 SELECT @incl_tax_line = @incl_tax_line -
				(@qty_shipped * @amt_tax)
		END
		ELSE
		BEGIN
			
			IF (@tax_based_type = 0)
				
		 	
				IF ( @prc_flag = 1)
				 BEGIN 
					SELECT @accumulated_tax = SUM( amt_tax)
					 FROM aptaxdet, aptxtype
					 WHERE aptaxdet.tax_code = @tax_code
				 		AND prc_flag = 1
					 AND aptxtype.tax_type_code = aptaxdet.tax_type_code
					

					
					
 
					SELECT @incl_tax_line = @incl_tax_line + 
(SIGN((@amt_tax/100) * (SIGN((@amount / ( 1.0 + ( @accumulated_tax / 100)))) * ROUND(ABS((@amount / ( 1.0 + ( @accumulated_tax / 100)))) + 0.0000001, 2))) * ROUND(ABS((@amt_tax/100) * (SIGN((@amount / ( 1.0 + ( @accumulated_tax / 100)))) * ROUND(ABS((@amount / ( 1.0 + ( @accumulated_tax / 100)))) + 0.0000001, 2))) + 0.0000001, 2))
				 END
				ELSE
					
					IF ((@amount) > (0.0) + 0.0000001)
			 		 SELECT @incl_tax_line =
						@incl_tax_line + @amt_tax
					ELSE
					 SELECT @incl_tax_line =
						@incl_tax_line - @amt_tax
		END
	END
	SELECT @incl_tax_line = (SIGN(@incl_tax_line) * ROUND(ABS(@incl_tax_line) + 0.0000001, 2))
	IF NOT( (ABS((@incl_tax_line)-(0.0)) < 0.0000001) )
		SELECT @last_incl_rev_acct = @acct_code

	SET ROWCOUNT 0

	


GO
GRANT EXECUTE ON  [dbo].[aptxinln_sp] TO [public]
GO
