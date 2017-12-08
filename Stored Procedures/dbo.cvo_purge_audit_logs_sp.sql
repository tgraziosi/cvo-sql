SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_purge_audit_logs_sp]
AS
BEGIN

    SET NOCOUNT OFF;

    DECLARE @months_to_keep INT,
            @cutoffdate DATETIME;

    SELECT @months_to_keep = 6;

    SELECT @cutoffdate = DATEADD(MONTH, -@months_to_keep, GETDATE());

    DELETE TOP (50000)
    FROM dbo.cvo_process_soft_allocations_audit
    WHERE allocation_date < @cutoffdate;

    DELETE TOP (50000)
    FROM dbo.cvo_replenishment_audit
    WHERE entry_date < @cutoffdate;

    DELETE TOP (50000)
    FROM dbo.cvo_invoice_audit
    WHERE printed_date < @cutoffdate;

    DELETE TOP (50000)
    FROM dbo.cvo_order_cancellation_audit
    WHERE when_cancelled < @cutoffdate;

    DELETE TOP (50000)
    FROM ESC_CashAppAudit
    WHERE ProcessDate < @cutoffdate;

END;

GRANT EXECUTE ON cvo_purge_audit_logs_sp TO PUBLIC;
GO
