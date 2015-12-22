SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_cust_status_hist_clear_sp]	@customer_code varchar(8), @user_id int
AS
	UPDATE 	cc_cust_status_hist 
	SET 	clear_date = DATEDIFF(dd,'01/01/1753',getdate()) + 639906,
				cleared_by = @user_id
	WHERE customer_code = @customer_code
	AND 	clear_date IS NULL

 
GO
GRANT EXECUTE ON  [dbo].[cc_cust_status_hist_clear_sp] TO [public]
GO
