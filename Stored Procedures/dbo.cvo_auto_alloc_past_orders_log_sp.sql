SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- v1.0 CT 07/03/2014 - Issue #1459 - Write information on the allocation of past orders to log

-- EXEC dbo.cvo_auto_alloc_past_orders_log_sp 'ST',NULL,NULL,NULL,'Message'
CREATE PROC [dbo].[cvo_auto_alloc_past_orders_log_sp]  (@order_type	VARCHAR(2),
													@template	VARCHAR(255),
													@order_no	INT = NULL,
													@ext		INT = NULL,
													@log_msg	VARCHAR(1000))

AS
BEGIN

	SET NOCOUNT ON

	INSERT INTO cvo_auto_alloc_past_orders_log(
		log_date,
		order_type,
		template,
		order_no,
		ext,
		log_msg)
	SELECT
		GETDATE(),
		@order_type,
		@template,
		@order_no,
		@ext,
		@log_msg

END

GO
GRANT EXECUTE ON  [dbo].[cvo_auto_alloc_past_orders_log_sp] TO [public]
GO
