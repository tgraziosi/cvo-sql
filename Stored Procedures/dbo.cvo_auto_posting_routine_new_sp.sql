SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* 
BEGIN TRAN
select status, * from orders_all where order_no = 1419328
EXEC cvo_auto_posting_routine_new_sp 1419328, 0
select status, * from orders_all where order_no = 1419328
ROLLBACK TRAN
*/

CREATE PROC [dbo].[cvo_auto_posting_routine_new_sp] @order_no	int,
												@order_ext	int
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@next_batch		varchar(16),
			@err_code		int

	BEGIN TRAN [cvo_post]

	BEGIN TRY

		-- Get the next batch number
		CREATE TABLE #cvo_next_batch (
			err_code	int,
			batch		varchar(16))
		
		INSERT #cvo_next_batch
		EXEC dbo.fs_next_batch @process_description = 'ADM AR Transactions',@user = 'sa',@process_parent_app = 18000  

		SELECT	@err_code = err_code,
				@next_batch = batch
		FROM	#cvo_next_batch

		DROP TABLE #cvo_next_batch

		IF (@err_code <> 0 OR ISNULL(@next_batch,'') = '')
		BEGIN
			IF (@@TRANCOUNT <> 0)
				ROLLBACK TRAN [cvo_post]

			INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
			SELECT	GETDATE(), @next_batch, @order_no, @order_ext, 'Error code returned from fs_next_batch'
			RETURN
		END

		-- For linked sales orders/PO
		UPDATE	so_porel 
		SET		order_ext = 0 + 1 
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		-- Mark the order for posting
		UPDATE	orders_posting_vw 
		SET		process_ctrl_num = @next_batch 
		WHERE	order_no = @order_no 
		AND		ext = @order_ext

		-- Exec the posting routine ans standard processing
		EXEC dbo.fs_post_ar_wrap @user = 'sa',@process_ctrl_num = @next_batch

		EXEC dbo.icv_fs_post_cradj_wrap @user = 'sa',@process_ctrl_num = @next_batch

	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT <> 0)
			ROLLBACK TRAN [cvo_post]

		INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
		SELECT	GETDATE(), @next_batch, @order_no, @order_ext, ERROR_MESSAGE()

	END CATCH

	COMMIT TRAN [cvo_post]

END
GO
GRANT EXECUTE ON  [dbo].[cvo_auto_posting_routine_new_sp] TO [public]
GO
