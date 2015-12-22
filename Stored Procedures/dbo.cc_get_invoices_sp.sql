SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_invoices_sp]
	@customer_code varchar(8),
	@days_old int

AS
	DECLARE @today int

	SELECT @today = DATEDIFF(dd, '1/1/1753', CONVERT(datetime, GETDATE())) + 639906


	SELECT DISTINCT doc_ctrl_num
	FROM artrx
	WHERE trx_type = 2031
	AND customer_code = @customer_code
	AND date_doc >= @today - @days_old
	AND void_flag = 0

GO
GRANT EXECUTE ON  [dbo].[cc_get_invoices_sp] TO [public]
GO
