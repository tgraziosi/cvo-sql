SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE proc [dbo].[cc_purge_alert_history_sp]	@date	datetime

AS
	SET NOCOUNT ON

	DECLARE @through_date int
	
	SELECT @through_date = DATEDIFF(dd, '1/1/1753', @date) + 639906

	DELETE cc_invoice_alerts
	WHERE	date_created <= @through_date
	
	IF @@ERROR <> 0 
		RETURN -1
	ELSE
		RETURN 0

GO
GRANT EXECUTE ON  [dbo].[cc_purge_alert_history_sp] TO [public]
GO
