SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_cust_status_hist_i_sp]	@customer_code varchar(16),
														@status_code varchar(5),
														@date smalldatetime,
														@original_user int
AS
	INSERT 	cc_cust_status_hist 
	SELECT 	@customer_code,
				@status_code,
				DATEDIFF(dd,'01/01/1753',@date) + 639906,
				@original_user,
				null,
				null,
				(SELECT ISNULL(MAX(sequence_num),0) + 1 
				 FROM cc_cust_status_hist
				 WHERE customer_code = @customer_code) 

 
GO
GRANT EXECUTE ON  [dbo].[cc_cust_status_hist_i_sp] TO [public]
GO
