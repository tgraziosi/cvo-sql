
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



if(object_id('dbo.SSRS_ARAging_Temp') is not null)
 TRUNCATE table SSRS_ARAging_Temp

insert into ssrs_araging_temp
(cust_code, [key], attn_email, sls, terr, region, name, bg_code,
bg_name, tms, r12sales, avgdayslate, bal, fut, cur, ar30, ar60,
ar90, ar120, ar150, credit_limit, onorder, lpmtdt, amount, ytdcreds, ytdsales, lyrsales, hold,
date_asof, date_type_string, date_type)
 exec cvo_araging_sp ''

DECLARE @asofdate DATETIME
SELECT @asofdate = CONVERT(varchar(30), dateadd(d,-1, convert(datetime,MAX(date_asof),101)), 101)
					FROM dbo.SSRS_ARAging_Temp AS saat

if datepart(day,getdate()) = 1
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.cvo_ARAging_month AS caam WHERE date_asof = @asofdate)
			DELETE FROM dbo.cvo_ARAging_month WHERE date_asof = @asofdate

    insert into cvo_araging_month -- month-end save for fin reporting
    select 
    cust_code, [key], attn_email, sls, terr, region, name, bg_code,
    bg_name, tms, avgdayslate, bal, fut, cur, ar30, ar60,
    ar90, ar120, ar150, credit_limit, onorder, lpmtdt, amount, ytdcreds, ytdsales, lyrsales, 
    r12sales, hold,
    @asofdate date_asof, date_type_string, date_type
    from ssrs_araging_temp
end

GO
