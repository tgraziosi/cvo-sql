SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/******************************* EPICOR SOFTWARE CORP *************************************************
CREATED BY:		ALEX AVERBUKH
CREATED IN:		NOV 2011
PURPOSE:		CLIENT WOULD LIKE A CUSTOM EXPLORER VIEW FOR AR AGING
EDITS:			20111220_bjb  to move aging buckets
				20120120_bjb  to correct credit aging
				20120328_bjb	to corect open amounts
				20120605 - tag - rewrite to match C&C summary Aging numbers, misc. updates
				20130529 - tag - change join on artrx to an outer join.  writeoff's don't have artrx
                20131016 - tag- add rolling 12 month sales		
                20131101 - tag - merge code from ssrs and EV version to use same code.
                            Create monthly snapshot on day 1		
EXEC CVO_ARAGING_ssrs_SP
select * from SSRS_ARAging_Temp
select dbo.adm_format_pltdate_f(735173)
*******************************************************************************************************/

CREATE PROCEDURE [dbo].[CVO_ARAGING_SSRS_SP] -- (@WHERECLAUSE VARCHAR(1024))
AS
SET NOCOUNT OFF
;



IF (OBJECT_ID('dbo.SSRS_ARAging_Temp') IS NOT NULL)
    TRUNCATE TABLE SSRS_ARAging_Temp
    ;

INSERT INTO SSRS_ARAging_Temp
(
    CUST_CODE,
    [KEY],
    attn_email,
    SLS,
    TERR,
    REGION,
    NAME,
    BG_CODE,
    BG_NAME,
    TMS,
    r12sales,
    AVGDAYSLATE,
    BAL,
    FUT,
    CUR,
    AR30,
    AR60,
    AR90,
    AR120,
    AR150,
    CREDIT_LIMIT,
    ONORDER,
    lpmtdt,
    AMOUNT,
    YTDCREDS,
    YTDSALES,
    LYRSALES,
    HOLD,
    date_asof,
    date_type_string,
    date_type
)
EXEC CVO_ARAGING_SP ''
;

DECLARE @asofdate DATETIME
;
SELECT @asofdate = CONVERT(VARCHAR(30), DATEADD(d, -1, CONVERT(DATETIME, MAX(date_asof), 101)), 101)
FROM dbo.SSRS_ARAging_Temp AS saat
;

IF DATEPART(DAY, GETDATE()) = 1
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM dbo.cvo_ARAging_month AS caam
        WHERE date_asof = @asofdate
    )
        DELETE FROM dbo.cvo_ARAging_month
        WHERE date_asof = @asofdate
        ;

    INSERT INTO cvo_ARAging_month -- month-end save for fin reporting
    SELECT
        CUST_CODE,
        [KEY],
        attn_email,
        SLS,
        TERR,
        REGION,
        NAME,
        BG_CODE,
        BG_NAME,
        TMS,
        AVGDAYSLATE,
        BAL,
        FUT,
        CUR,
        AR30,
        AR60,
        AR90,
        AR120,
        AR150,
        CREDIT_LIMIT,
        ONORDER,
        lpmtdt,
        AMOUNT,
        YTDCREDS,
        YTDSALES,
        LYRSALES,
        r12sales,
        HOLD,
        @asofdate date_asof,
        date_type_string,
        date_type
    FROM SSRS_ARAging_Temp
    ;
END
;


GO
