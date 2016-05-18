SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[CVO_INV_GL_Recon_sp] @datefrom datetime, @dateto datetime
as 
BEGIN

SET NOCOUNT ON

-- Author: Tine Graziosi - 07/26/2013
-- Usage: exec cvo_INV_gl_recon_sp '05/05/2016', '5/6/2016'
-- declare @datefrom datetime, @dateto datetime

declare @jdatefrom int, @jdateto int

--select @datefrom = dateadd(mm,datediff(mm,0,dateadd(dd,datediff(dd,1,getdate()), 0)), 0)
--select @dateto = dateadd(dd,datediff(dd,1,getdate()), 0)

select @jdatefrom = dbo.adm_get_pltdate_f(@datefrom)
select @jdateto = dbo.adm_get_pltdate_f(@dateto)

-- select  dateadd(mm,datediff(mm,0,getdate()), 0), dateadd(dd,datediff(dd,0,getdate()), 0)

-- select @datefrom, @dateto

-- get G/L Balances

IF(OBJECT_ID('tempdb.dbo.#glbal') is not null)  drop table #glbal

CREATE TABLE #glbal
(
	account_code            varchar(36) 	NOT NULL,
	post_status				INT		NOT NULL,
	org_id			varchar(30)	NULL,
	date_period_end         int 	NOT NULL,
	beginning_balance       float		NOT NULL,
	net_change				FLOAT		NOT NULL,
	ending_balance          float		NOT NULL,
	oper_beginning_balance      float	NOT NULL,
	oper_net_change				FLOAT	NOT NULL,
	oper_ending_balance         float	NOT NULL,
	x_date_period_end	INT NOT NULL,
	x_beginning_balance	FLOAT NOT NULL,
	x_net_change	FLOAT NOT NULL,
	x_ending_balance FLOAT NOT NULL,
	x_oper_beginning_balance FLOAT NOT NULL,
	x_oper_net_change FLOAT NOT NULL,
	x_oper_ending_balance FLOAT NOT null	
)

DECLARE @where_clause VARCHAR(1000)
SELECT @where_clause = 
 ' Where (account_code like ''%1400000000000%'' OR account_code like ''%1405000000000%'' or account_code like ''%1415000000000%'') and post_status=0 and date_period_end=xDATE_PERIOD_ENDx'

SELECT @where_clause = REPLACE(@where_clause,'xDATE_PERIOD_ENDx', cast(@jdateto as VARCHAR(6)))

-- SELECT @where_clause

INSERT into #glbal 
	EXEC glbl1_sp @where_clause

SELECT @where_clause = REPLACE(@where_clause,'post_status=0','post_status=1')

-- SELECT @where_clause

INSERT INTO #glbal
 exec glbl1_sp @where_clause


select 'INVVAL' Source_Ledger, 'Inventory' Inv_Type, '1400' Acct, round(sum(cvo_ext_value),2) Value
FROM cvo_inv_val_snapshot
GROUP BY asofdate

UNION ALL
select 'INVVAL', 'Picked, Not Shipped', '1400', ROUND(SUM(pns_value),2) pns_value
FROM cvo_inv_val_snapshot
GROUP BY asofdate

UNION ALL
select 'INVVAL', 'Intransit', '1415', ROUND(SUM(int_value),2) int_value
FROM cvo_inv_val_snapshot
GROUP BY asofdate

UNION ALL
SELECT 'GLBAL', CASE WHEN b.post_status = 1 THEN 'Posted' ELSE 'Not Posted' end, 
LEFT(b.account_code,4) natAcct, ROUND(SUM(b.ending_balance),2) ending_balance
FROM #glbal AS b
WHERE LEFT(b.account_code,4) IN ('1400','1415')
GROUP BY b.post_status, LEFT(b.account_code,4)

UNION ALL
SELECT 'GLBAL', CASE WHEN b.post_status = 1 THEN 'Posted' ELSE 'Not Posted' end, 
LEFT(b.account_code,4) natAcct, ROUND(SUM(b.ending_balance),2) ending_balance
FROM #glbal AS b
WHERE LEFT(b.account_code,4) IN ('1405')
GROUP BY b.post_status, LEFT(b.account_code,4)

UNION ALL
select 'INVVAL', 'QC', '1405', ROUND(SUM(qc_value),2) qc_value 
FROM cvo_inv_val_snapshot
GROUP BY asofdate

END



GO
