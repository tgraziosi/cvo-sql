SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cvo_writeoff_fisherprice_sp]
as 
begin

-- TAG - 123114
-- adjust out BY DOING ADHOC FP frames,suns, and POP

/*  Set up adhoc - in TO BIN = Transfer*/

 IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
 BEGIN   
 DROP TABLE #temp_who  
 END
Create table #temp_who(who varchar(50), login_id varchar(50))
Insert #temp_who select 'tdcsql','tdcsql'

IF (SELECT OBJECT_ID('tempdb..#temp_part_list')) IS NOT NULL 
BEGIN  
DROP TABLE #temp_part_list
END

CREATE TABLE #temp_part_list (
id int identity,
loc varchar(10) not null,
bin_no varchar(12) not null,
part_no varchar(30) not null, 
qty decimal(20,8) not null,
direction int not null  )

insert #temp_part_list
select location, bin_no, i.part_no, qty, -1
from lot_bin_stock lb
inner join inv_master i on i.part_no = lb.part_no
where i.category = 'fp' and type_code in ('frame','sun','pop')
and not exists (select 1 
from tdc_soft_alloc_tbl t
 where t.location = lb.location and t.bin_no = lb.bin_no and t.part_no = lb.part_no) 

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
err_msg		varchar(255)	null,
row_id		int 	not null)

-- do the processing

declare @part_no varchar(30)
DECLARE @BIN_no varchar(12), @location varchar(12)
declare @qty decimal(20,0)
declare @id int, @direction int, @err int

--	LOOP HERE UNTIL TEMP_PART_LIST IS EMPTY
select @id = min(id) from #temp_part_list
while @id is not null
 begin
	select @part_no = part_no, @location = loc, @bin_no = bin_no, @direction = direction, @qty = qty
	from #temp_part_list where id = @id
	
	truncate table #adm_inv_adj
	
	if @direction = -1
	begin
		INSERT INTO #adm_inv_adj 
	    (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 					
	    SELECT LB.LOCATION, lb.PART_NO, LB.BIN_NO, lb.LOT_SER, DATE_EXPIRES, 
	    case when @QTY > lb.qty then lb.qty else @qty end, -1,'tdcsql','WRITE-OFF', 'WRITEOFF'
	    FROM LOT_BIN_STOCK lb
	    WHERE LB.BIN_NO = @bin_no and LB.LOCATION = @location and lb.part_no = @part_no
	    exec  @err = tdc_adm_inv_adj
	    if (@err < 0) begin if (@@trancount >0 ) rollback tran end
	   	insert into #adm_INV_ADJ_log
	    SELECT * FROM #ADM_INV_ADJ
    end	
	
	if @direction = 1
	begin
	INSERT INTO #adm_inv_adj 
	(loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 			--VALUES('001', 
	--'OPZCASEL', 'RR CASES', '1', '05/24/2013',13.00000000, -1,'CVOPTICAL\epitest2', 'ADJ-ADHOC', 'CYC')
	SELECT @location, @PART_NO, @BIN_NO, '1', convert(varchar(12),
		dateadd(yy,1,getdate()),109), @qty, @direction,
		'tdcsql','WRITE-OFF', 'WRITEOFF'
 
	exec tdc_adm_inv_adj 
	
	insert into #adm_INV_ADJ_log
	SELECT * FROM #ADM_INV_ADJ
    end
    
	select @id = min(id)
	from #temp_part_list
	where id > @id
end

end
GO
GRANT EXECUTE ON  [dbo].[cvo_writeoff_fisherprice_sp] TO [public]
GO
