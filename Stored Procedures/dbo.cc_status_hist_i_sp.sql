SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_status_hist_i_sp]	@doc_ctrl_num varchar(16),
																			@status_code varchar(5),
																			@date smalldatetime,
																			@original_user int,

																			@customer_code varchar(8)
AS
	INSERT	cc_inv_status_hist 
	SELECT 	@doc_ctrl_num,
					@status_code,
					DATEDIFF(dd,'01/01/1753',@date) + 639906,
					@original_user,
					NULL,
					NULL,
					(	SELECT ISNULL(MAX(sequence_num),0) + 1 
						FROM cc_inv_status_hist
						WHERE doc_ctrl_num = @doc_ctrl_num),
					@customer_code 


GO
GRANT EXECUTE ON  [dbo].[cc_status_hist_i_sp] TO [public]
GO
