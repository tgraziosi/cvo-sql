SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_adhoc_revo_packaging_sp] AS

-- 12/19/2014 - update to look at scrap bins in all locations
-- EXEC CVO_ADHOC_revo_packaging_sp
-- select * From lot_bin_stock where bin_no = 'rr scrap'

BEGIN
SET NOCOUNT ON
-- TAG - 071612
-- EMPTY OUT A BIN BY DOING ADHOC based on a list of part/qtys

-- =CONCATENATE("insert into #temp_part_list values('",A2,"',",B2,")")
-- =CONCATENATE("insert into #temp_part_list values('",A2,"','",left(a2,3),"','",b2,"','",D2,"')")


DECLARE @BIN VARCHAR(10)
DECLARE @LOC VARCHAR(10)
DECLARE @QTY_TO_ISSUE INT, @last_upd datetime

SET @BIN = 'F11-BOX'
-- SET @LOC = '001'
SET @LOC = '001'


IF NOT EXISTS (SELECT 1 FROM config WHERE flag = 'CVO_RE_PKG_UPD')
	INSERT dbo.config
	        ( flag ,
	          description ,
	          value_str ,
	          flag_class
	        )
	VALUES  ( 'CVO_RE_PKG_UPD' , -- flag - varchar(20)
	          'Last update of Revo Pkging qty' , -- description - varchar(40)
	          '1/1/1900' , -- value_str - varchar(40)
	          'misc'  -- flag_class - varchar(10)
	        )

SELECT @last_upd = ISNULL(CAST(value_str AS DATETIME),'1/1/1900') FROM config WHERE flag = 'CVO_RE_PKG_UPD'

SELECT @QTY_TO_ISSUE = SUM(ISNULL(shipped,0)) FROM shippers WHERE part_no = 'REZCASES' AND date_shipped > @last_upd

UPDATE config SET value_str = GETDATE() WHERE flag = 'CVO_RE_PKG_UPD'

IF @QTY_TO_ISSUE <= 0 RETURN  -- there's nothing to do


-- BIN = '1' AND LOCATION = '001'
-- BIN = 'RR CASES' AND LOCATION = '001'

-- 8700T212D40242c

/*  Set up adhoc - in TO BIN = Transfer*/

IF (SELECT OBJECT_ID('tempdb..#temp_part_list')) IS NOT NULL 
BEGIN  
DROP TABLE #temp_part_list
END

CREATE TABLE #temp_part_list (
id int identity,
location varchar(12), 
bin_no varchar(12),
	part_no varchar(30) not null, 
	qty decimal(20,8) not NULL,
	direction int NOT null)

-- issue the same number of consumer boxes and authenticity cards as cases

insert into #temp_part_list
select location, bin_no, part_no, CASE WHEN @QTY_TO_ISSUE > QTY THEN QTY ELSE @QTY_TO_ISSUE END , -1
	from lot_bin_stock 
-- where location = @LOC and bin_no = @BIN
where location = @LOC and bin_no = @BIN
AND part_no IN ( 'rezbox','rezaudcard' )
and qty > 0

-- keep the rx lenses at an inventory level of 1000

insert into #temp_part_list
select location, bin_no, part_no, 1000 - qty , 1
	from lot_bin_stock 
-- where location = @LOC and bin_no = @BIN
where location = @LOC and bin_no = @BIN
AND part_no IN ( 'rezrxlens','rerimless' )
and qty < 1000


-- select * from #temp_part_list

IF (SELECT OBJECT_ID('tempdb..#t1')) IS NOT NULL 
BEGIN  
DROP TABLE #t1
END

select location, bin_no, part_no, sum(qty) qty, direction into #t1
from #temp_part_list 
group by location, bin_no, part_no, direction

truncate table #temp_part_list

insert into #temp_part_list
	select * from #t1

--select * From #temp_part_list

IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj')) IS NOT NULL 
BEGIN  
DROP TABLE #adm_inv_adj  
END

CREATE TABLE #adm_inv_adj 
(adj_no int null,
loc			varchar(10)		not null,
part_no		varchar(30)		not null,
bin_no		varchar(12)		null,
lot_ser		varchar(25)		null,
date_exp		datetime		null,
qty			decimal(20,8)	not null,
direction	int				not null,
who_entered	varchar(50)		not null,
reason_code	varchar(10)		null,
code			varchar(8)		not null,
cost_flag	char(1)			null,
avg_cost		decimal(20,8)	null,
direct_dolrs	decimal(20,8)	null,
ovhd_dolrs	decimal(20,8)	null,
util_dolrs	decimal(20,8)	null,
err_msg		varchar(255)	null,
row_id		int identity	not null)

IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj_LOG')) IS NOT NULL 
BEGIN  
DROP TABLE #adm_inv_adj_LOG
END

CREATE TABLE #adm_inv_adj_LOG
(adj_no int null,
loc			varchar(10)		not null,
part_no		varchar(30)		not null,
bin_no		varchar(12)		null,
lot_ser		varchar(25)		null,
date_exp		datetime		null,
qty			decimal(20,8)	not null,
direction	int				not null,
who_entered	varchar(50)		not null,
reason_code	varchar(10)		null,
code			varchar(8)		not null,
cost_flag	char(1)			null,
avg_cost		decimal(20,8)	null,
direct_dolrs	decimal(20,8)	null,
ovhd_dolrs	decimal(20,8)	null,
util_dolrs	decimal(20,8)	null,
err_msg		varchar(255)	null
,row_id		int 	not null)

-- SELECT * FROM #ADM_INV_ADJ

IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
BEGIN   
DROP TABLE #temp_who  
END
Create table #temp_who(who varchar(50), login_id varchar(50))
Insert #temp_who select 'tdcsql','tdcsql'

-- SELECT * FROM #TEMP_PART_LIST

---  do the processing

DECLARE @LOCATION VARCHAR(12), @BIN_NO VARCHAR(12), @PART_NO VARCHAR(30), @ERR INT, @ID INT, @direction int

--	LOOP HERE UNTIL TEMP_PART_LIST IS EMPTY
select @id = min(id) from #temp_part_list
while @id is not null
 begin
	select top 1 @location = location,
			@bin_no = bin_no,
			@part_no = part_no,
			@QTY_TO_ISSUE = qty,
			@direction = direction
	from #temp_part_list where id = @id

    -- SELECT @ID
    
	truncate table #adm_INV_ADJ
	INSERT INTO #adm_inv_adj 
	(loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 									
	--VALUES('001', 
	--'OPZCASEL', 'RR CASES', '1', '05/24/2013',13.00000000, -1,'CVOPTICAL\epitest2', 'ADJ-ADHOC', 'CYC')
	SELECT top 1 LB.LOCATION, lb.PART_NO, LB.BIN_NO, lb.LOT_SER, DATE_EXPIRES, 
	case when @QTY_TO_ISSUE > lb.qty then lb.qty else @QTY_TO_ISSUE end, @direction, 'tdcsql', 'ADJ-ADHOC', 'ADHOC'
	FROM LOT_BIN_STOCK lb
	WHERE LB.BIN_NO = @bin_no and LB.LOCATION = @location and lb.part_no = @part_no
	--and lb.lot_ser = '-1'

	exec  @err = tdc_adm_inv_adj
	if (@err < 0)
	begin if (@@trancount >0 ) rollback tran end
	insert into #adm_INV_ADJ_log
		SELECT * FROM #ADM_INV_ADJ

	select @id = min(id)
	from #temp_part_list
	where id > @id
end

-- SELECT * FROM #adm_INV_ADJ_log

END

GO
