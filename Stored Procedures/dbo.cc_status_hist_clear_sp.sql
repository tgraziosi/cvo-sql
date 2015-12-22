SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_status_hist_clear_sp]	@doc_ctrl_num varchar(16), 
										@user_id int,
										@customer_code varchar(8)
AS
	UPDATE 	cc_inv_status_hist 
	SET 		clear_date =  DATEDIFF(dd,'01/01/1753',getdate()) + 639906,
					cleared_by = @user_id
	WHERE 	doc_ctrl_num = @doc_ctrl_num
	AND 		clear_date IS NULL
	AND			( ISNULL(DATALENGTH(LTRIM(RTRIM(customer_code))), 0 ) = 0 OR customer_code = @customer_code )
    
GO
GRANT EXECUTE ON  [dbo].[cc_status_hist_clear_sp] TO [public]
GO
